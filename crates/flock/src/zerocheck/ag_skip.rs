//! Round 1 of the zerocheck, the AG skip: the six skip variables fold through the genus-95
//! multiplication code of [`crate::ag_code`] rather than through Reed-Solomon.
//!
//! A block is 64 consecutive witness bits, a message of the code. The round-1 message is
//!
//! ```text
//!     P = sum_X eq(r, X) * suffix(a_X x b_X + R c_X)        X over the 2^(m-6) blocks
//! ```
//!
//! and the code is binary-preserving, so every `suffix` is 158 BITS: `P` is 158 sums of selected
//! equality weights, with no field product per witness bit.
//!
//! The kernel is bit-sliced. A group is 64 consecutive blocks, and the protocol fixes the six
//! equality coordinates inside a group so that block `K` weighs `g^K` ([`friendly_challenges`]).
//! One coordinate of one group is then 64 bits that ARE a base-field element, and a group costs
//! one mixed product per coordinate:
//!
//! ```text
//!     transpose    64 blocks x 64 bits  ->  64 planes, bit K of plane i = bit i of block K
//!     extend       R a, R b              on planes, by tables of 4-plane XORs
//!     multiply     the jet products      on planes, ANDs and XORs
//!     accumulate   P_j += w * plane_j    the plane read as an element of K
//! ```
//!
//! Eight groups ride the eight words of a vector. `R c` is linear, so `c` skips the extension:
//! its 64 planes accumulate as they are, and `R` is applied once to the 64 sums.

use std::mem::MaybeUninit;

use primitives::field::{F192, G, LaneSums, Weights8};

use super::eq::SplitEq;
use super::{K_SKIP, N_INNER, PaddingSpec};
use crate::ag_code::tables::R_ROWS;
use crate::ag_code::{K, SUFFIX, to_pairs};

/// Blocks per group, the bits of a base-field element.
const GROUP: usize = 64;
/// Groups per kernel call.
const LANES: usize = 8;

/// One word per group: a vector register where the target has one this wide.
///
/// The operations are spelled out for AVX-512 rather than left to the loop vectorizer, which
/// otherwise vectorizes the kernel's loops over planes ACROSS the planes, through scatters.
#[derive(Clone, Copy)]
#[repr(C, align(64))]
struct Lanes([u64; LANES]);

impl Lanes {
    const ZERO: Self = Self([0; LANES]);
}

#[cfg(all(target_arch = "x86_64", target_feature = "avx512f"))]
mod lanes {
    use core::arch::x86_64::{
        __m512i, _mm_cvtsi32_si128, _mm512_and_si512, _mm512_sll_epi64, _mm512_srl_epi64, _mm512_xor_si512,
    };
    use core::mem::transmute;
    use core::ops::{BitAnd, BitXor};

    use super::Lanes;

    // SAFETY (all): `avx512f` is enabled at compile time, and `Lanes` is 64 aligned bytes of plain words.
    impl BitXor for Lanes {
        type Output = Self;
        #[inline(always)]
        fn bitxor(self, rhs: Self) -> Self {
            unsafe {
                transmute(_mm512_xor_si512(
                    transmute::<Self, __m512i>(self),
                    transmute::<Self, __m512i>(rhs),
                ))
            }
        }
    }

    impl BitAnd for Lanes {
        type Output = Self;
        #[inline(always)]
        fn bitand(self, rhs: Self) -> Self {
            unsafe {
                transmute(_mm512_and_si512(
                    transmute::<Self, __m512i>(self),
                    transmute::<Self, __m512i>(rhs),
                ))
            }
        }
    }

    impl Lanes {
        #[inline(always)]
        pub fn shl(self, n: u32) -> Self {
            unsafe {
                transmute(_mm512_sll_epi64(
                    transmute::<Self, __m512i>(self),
                    _mm_cvtsi32_si128(n as i32),
                ))
            }
        }

        #[inline(always)]
        pub fn shr(self, n: u32) -> Self {
            unsafe {
                transmute(_mm512_srl_epi64(
                    transmute::<Self, __m512i>(self),
                    _mm_cvtsi32_si128(n as i32),
                ))
            }
        }
    }
}

#[cfg(not(all(target_arch = "x86_64", target_feature = "avx512f")))]
mod lanes {
    use core::ops::{BitAnd, BitXor};

    use super::Lanes;

    impl BitXor for Lanes {
        type Output = Self;
        #[inline(always)]
        fn bitxor(self, rhs: Self) -> Self {
            Self(std::array::from_fn(|q| self.0[q] ^ rhs.0[q]))
        }
    }

    impl BitAnd for Lanes {
        type Output = Self;
        #[inline(always)]
        fn bitand(self, rhs: Self) -> Self {
            Self(std::array::from_fn(|q| self.0[q] & rhs.0[q]))
        }
    }

    impl Lanes {
        #[inline(always)]
        pub fn shl(self, n: u32) -> Self {
            Self(self.0.map(|w| w << n))
        }

        #[inline(always)]
        pub fn shr(self, n: u32) -> Self {
            Self(self.0.map(|w| w >> n))
        }
    }
}

/// The seven fixed equality coordinates that follow the skip.
///
/// The first six are `g^(2^j) / (1 + g^(2^j))`, so that `eq(., K) = g^K / D` over a group.
/// The seventh is `y / (1 + y)`: two adjacent groups weigh `1` and `y`, over `1 + y`.
///
/// **Soundness dependency.** `lem:fixed-zerocheck` requires the `2^7` equality weights to be
/// GF(2)-linearly independent. They are the basis elements `g^K y^i` of F192 over GF(2), scaled
/// by one constant. Asserted by `tests::friendly_challenges_f2_independent`.
pub fn friendly_challenges() -> [F192; N_INNER] {
    let mut g = F192::from(G);
    std::array::from_fn(|j| {
        let base = if j < K_SKIP { g } else { F192::Y };
        g = g.square();
        base * (F192::ONE + base).inv()
    })
}

/// `1 / (D (1 + y))`, the constant the group weights `g^K y^i` leave out.
fn friendly_scale() -> F192 {
    let mut g = F192::from(G);
    let mut d = F192::ONE + F192::Y;
    for _ in 0..K_SKIP {
        d *= F192::ONE + g;
        g = g.square();
    }
    d.inv()
}

/// Transpose 64 words of 64 bits, in every lane at once.
fn transpose(v: &mut [Lanes; 64]) {
    let mut j = 32u32;
    let mut mask = 0x0000_0000_ffff_ffffu64;
    while j != 0 {
        let lane_mask = Lanes([mask; LANES]);
        let mut k = 0;
        while k < 64 {
            let t = (v[k].shr(j) ^ v[k + j as usize]) & lane_mask;
            v[k] = v[k] ^ t.shl(j);
            v[k + j as usize] = v[k + j as usize] ^ t;
            k = (k + j as usize + 1) & !(j as usize);
        }
        j >>= 1;
        mask ^= mask << j;
    }
}

/// Planes XORed per table of [`extend`].
const TABLE_BITS: usize = 4;
/// Tables: the last one holds the planes left over.
const TABLES: usize = K.div_ceil(TABLE_BITS);

/// `R m` past the prefix, for the 64 messages of each lane's group: `out[j]` is the XOR of the
/// planes row `64 + j` of `R` selects.
///
/// By tables: entry `v` of a table is the XOR of the planes `v` selects among its `TABLE_BITS`,
/// and a row takes one entry per table. A table is filled in Gray-code order, each entry the last
/// one with a single plane added, so filling it reads nothing back.
#[inline]
fn extend(planes: &[Lanes; K], out: &mut [Lanes; SUFFIX]) {
    let mut tables = MaybeUninit::<[[Lanes; 1 << TABLE_BITS]; TABLES]>::uninit();
    let entries = tables.as_mut_ptr().cast::<Lanes>();
    for t in 0..TABLES {
        let bits = TABLE_BITS.min(K - t * TABLE_BITS);
        let mut entry = Lanes::ZERO;
        // SAFETY (both writes): table `t` is entries `t << TABLE_BITS ..`, and a Gray code of
        // `bits <= TABLE_BITS` bits stays below `1 << TABLE_BITS`.
        unsafe { entries.add(t << TABLE_BITS).write(entry) };
        for step in 1..1usize << bits {
            entry = entry ^ planes[t * TABLE_BITS + step.trailing_zeros() as usize];
            unsafe { entries.add((t << TABLE_BITS) + (step ^ (step >> 1))).write(entry) };
        }
    }
    for (out, &row) in out.iter_mut().zip(&R_ROWS[K..]) {
        // The digits come off the row by shifts: a table of them would be a load per digit, on
        // the ports the table entries need.
        *out = (0..TABLES).fold(Lanes::ZERO, |acc, t| {
            let digit = (row >> (TABLE_BITS * t)) as usize & ((1 << TABLE_BITS) - 1);
            // SAFETY: the Gray code wrote every entry below `1 << bits` of table `t`, and a digit
            // of `R` has no bit past the planes a short last table holds.
            acc ^ unsafe { *entries.add((t << TABLE_BITS) + digit) }
        });
    }
}

/// One worker's sums, unreduced: the 158 jet coordinates of the `a x b` part, and `c`'s 64 planes.
struct Sums {
    jets: [LaneSums; SUFFIX],
    c: [LaneSums; K],
}

impl Sums {
    fn new() -> Self {
        Self {
            jets: [LaneSums::ZERO; SUFFIX],
            c: [LaneSums::ZERO; K],
        }
    }

    fn merge(mut self, other: Self) -> Self {
        for (a, b) in self.jets.iter_mut().zip(&other.jets) {
            a.merge(b);
        }
        for (a, b) in self.c.iter_mut().zip(&other.c) {
            a.merge(b);
        }
        self
    }

    /// Add the groups whose 64 blocks each lane of `a`, `b`, `c` holds, lane `q` weighing `w[q]`.
    #[inline]
    fn add(&mut self, a: &mut [Lanes; K], b: &mut [Lanes; K], c: &mut [Lanes; K], w: &[F192; LANES]) {
        transpose(a);
        transpose(b);
        transpose(c);
        let (mut l, mut r) = ([Lanes::ZERO; SUFFIX], [Lanes::ZERO; SUFFIX]);
        extend(a, &mut l);
        extend(b, &mut r);

        let w = Weights8::new(w);
        let add = |acc: &mut LaneSums, plane: Lanes| acc.add(&w, &plane.0);
        // Jets multiply as power series: order `n` of the product is the sum over `s + t = n`.
        // Order 0 of a message is the message, and order 3 lives at the first 30 points only.
        for i in 0..K {
            add(&mut self.jets[i], (a[i] & r[i]) ^ (l[i] & b[i]));
            add(
                &mut self.jets[K + i],
                (a[i] & r[K + i]) ^ (l[i] & r[i]) ^ (l[K + i] & b[i]),
            );
            add(&mut self.c[i], c[i]);
        }
        for i in 0..SUFFIX - 2 * K {
            let order3 = (a[i] & r[2 * K + i]) ^ (l[i] & r[K + i]) ^ (l[K + i] & r[i]) ^ (l[2 * K + i] & b[i]);
            add(&mut self.jets[2 * K + i], order3);
        }
    }

    /// The message over the pairs.
    fn finish(self) -> [F192; SUFFIX] {
        let scale = friendly_scale();
        let c = self.c.map(|sum| sum.fold().reduce());
        let jets: [F192; SUFFIX] = std::array::from_fn(|j| {
            let row = R_ROWS[K + j];
            let r_c = (0..K)
                .filter(|i| row >> i & 1 == 1)
                .fold(F192::ZERO, |acc, i| acc + c[i]);
            (self.jets[j].fold().reduce() + r_c) * scale
        });
        to_pairs(&jets)
    }
}

/// The round-1 message over the pairs of [`crate::ag_code`].
///
/// `r_rest` is the equality tail, its first `N_INNER` coordinates the [`friendly_challenges`].
/// A group the padding declares all zero is not read.
pub fn round1(a: &[u8], b: &[u8], c: &[u8], m: usize, r_rest: &[F192], padding: &PaddingSpec) -> [F192; SUFFIX] {
    assert!(m >= K_SKIP + N_INNER);
    assert_eq!(r_rest.len(), m - K_SKIP);
    debug_assert_eq!(r_rest[..N_INNER], friendly_challenges());
    let n_groups = 1usize << (m - K_SKIP - 6);
    for table in [a, b, c] {
        assert_eq!(table.len(), n_groups * GROUP * 8);
    }
    // Two adjacent groups share one outer weight: the seventh fixed coordinate splits them.
    let eq = SplitEq::new(&r_rest[N_INNER..]);
    let weight = |pair: usize| eq.lo[pair & ((1 << eq.n_lo) - 1)] * eq.hi[pair >> eq.n_lo];
    // Bits of a group, and of the block the padding repeats.
    let (group_bits, period) = (GROUP * 64, 1usize << padding.k_log.min(m));
    let live = |group: usize| period < group_bits || (group * group_bits) % period < padding.useful_bits_per_block;

    let lanes = LANES.min(n_groups);
    parallel::fold_reduce(
        n_groups / lanes,
        Sums::new,
        |sums, chunk| {
            let mut w = [F192::ZERO; LANES];
            let mut rows = [[Lanes::ZERO; K]; 3];
            let mut any = false;
            for q in (0..lanes).filter(|&q| live(chunk * lanes + q)) {
                let group = chunk * lanes + q;
                let pair = weight(group / 2);
                w[q] = if group.is_multiple_of(2) { pair } else { pair * F192::Y };
                for (rows, table) in rows.iter_mut().zip([a, b, c]) {
                    let words = table[group * GROUP * 8..][..GROUP * 8].as_chunks::<8>().0;
                    for (row, word) in rows.iter_mut().zip(words) {
                        row.0[q] = u64::from_le_bytes(*word);
                    }
                }
                any = true;
            }
            if any {
                let [a, b, c] = &mut rows;
                sums.add(a, b, c, &w);
            }
        },
        Sums::merge,
    )
    .finish()
}

#[cfg(test)]
mod tests {
    use primitives::test_rng::Rng;

    use super::*;
    use crate::ag_code::product_suffix;

    /// The message from its definition, one block at a time.
    fn round1_naive(a: &[u8], b: &[u8], c: &[u8], r_rest: &[F192]) -> [F192; SUFFIX] {
        let eq = primitives::multilinear::eq_table(r_rest);
        let word = |t: &[u8], x: usize| u64::from_le_bytes(t[8 * x..][..8].try_into().unwrap());
        let mut jets = [F192::ZERO; SUFFIX];
        for (x, &e) in eq.iter().enumerate() {
            let bits = product_suffix(word(a, x), word(b, x), word(c, x));
            for (j, jet) in jets.iter_mut().enumerate() {
                if bits[j / 64] >> (j % 64) & 1 == 1 {
                    *jet += e;
                }
            }
        }
        to_pairs(&jets)
    }

    fn tail(m: usize, rng: &mut Rng) -> Vec<F192> {
        let mut r = friendly_challenges().to_vec();
        r.extend(rng.ext_vec(m - K_SKIP - N_INNER));
        r
    }

    /// On witnesses that need not satisfy `a b = c`: the message is defined for all of them.
    #[test]
    fn kernel_matches_definition() {
        let mut rng = Rng::new(11);
        for m in [13, 14, 15, 17] {
            let bytes = (1usize << m) / 8;
            let [a, b, c]: [Vec<u8>; 3] = std::array::from_fn(|_| (0..bytes).map(|_| rng.next_u8()).collect());
            let r = tail(m, &mut rng);
            assert_eq!(
                round1(&a, &b, &c, m, &r, &PaddingSpec::dense(m)),
                round1_naive(&a, &b, &c, &r),
                "m = {m}"
            );
        }
    }

    /// Skipping the declared padding changes nothing when it is zero.
    #[test]
    fn padding_is_skipped_exactly() {
        let mut rng = Rng::new(12);
        let (m, k_log, useful) = (18, 15, 5000);
        let padding = PaddingSpec {
            k_log,
            useful_bits_per_block: useful,
        };
        let [a, b, c]: [Vec<u8>; 3] = std::array::from_fn(|_| {
            let mut t = vec![0u8; (1usize << m) / 8];
            for bit in (0..1usize << m).filter(|bit| bit % (1 << k_log) < useful) {
                t[bit / 8] |= (rng.next_u8() & 1) << (bit % 8);
            }
            t
        });
        let r = tail(m, &mut rng);
        assert_eq!(
            round1(&a, &b, &c, m, &r, &padding),
            round1(&a, &b, &c, m, &r, &PaddingSpec::dense(m))
        );
    }

    /// See [`friendly_challenges`].
    #[test]
    fn friendly_challenges_f2_independent() {
        let a = friendly_challenges();
        let mut rows: Vec<[u64; 3]> = (0..1usize << N_INNER)
            .map(|b| {
                let w = a.iter().enumerate().fold(F192::ONE, |acc, (i, &ai)| {
                    acc * if (b >> i) & 1 == 1 { ai } else { F192::ONE + ai }
                });
                [w.c0, w.c1, w.c2]
            })
            .collect();
        let mut rank = 0usize;
        for col in (0..192).rev() {
            let (limb, mask) = (col / 64, 1u64 << (col % 64));
            if let Some(p) = (rank..rows.len()).find(|&i| rows[i][limb] & mask != 0) {
                rows.swap(rank, p);
                for i in 0..rows.len() {
                    if i != rank && rows[i][limb] & mask != 0 {
                        for l in 0..3 {
                            rows[i][l] ^= rows[rank][l];
                        }
                    }
                }
                rank += 1;
            }
        }
        assert_eq!(
            rank,
            1 << N_INNER,
            "zerocheck and WHIR L0 soundness depend on it (lem:fixed-zerocheck)"
        );
    }
}
