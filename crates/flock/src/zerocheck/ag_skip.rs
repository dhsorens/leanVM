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
//! A group is 64 consecutive blocks, and the protocol fixes the six equality coordinates inside a
//! group so that block `K` weighs `g^K` ([`friendly_challenges`]). One coordinate of one group is
//! then 64 bits that ARE a base-field element, a plane, and a group costs one mixed product per
//! coordinate. A kernel turns groups into planes, eight groups at a time: `bytes` where the target
//! has GFNI and the AVX-512 byte and bit shuffles, `planes` elsewhere.
//!
//! `R c` is linear, so `c` skips the extension: its 64 planes accumulate as they are, and `R` is
//! applied once to the 64 sums.

use primitives::field::{F192, G, LaneSums};

use super::eq::SplitEq;
use super::{K_SKIP, N_INNER, PaddingSpec};
use crate::ag_code::tables::R_ROWS;
use crate::ag_code::{K, SUFFIX, to_pairs};

#[cfg(all(
    target_arch = "x86_64",
    target_feature = "avx512bw",
    target_feature = "avx512vbmi",
    target_feature = "avx512bitalg",
    target_feature = "gfni"
))]
mod bytes;
#[cfg(all(
    target_arch = "x86_64",
    target_feature = "avx512bw",
    target_feature = "avx512vbmi",
    target_feature = "avx512bitalg",
    target_feature = "gfni"
))]
use bytes::Kernel;

#[cfg(any(
    test,
    not(all(
        target_arch = "x86_64",
        target_feature = "avx512bw",
        target_feature = "avx512vbmi",
        target_feature = "avx512bitalg",
        target_feature = "gfni"
    ))
))]
mod planes;
#[cfg(not(all(
    target_arch = "x86_64",
    target_feature = "avx512bw",
    target_feature = "avx512vbmi",
    target_feature = "avx512bitalg",
    target_feature = "gfni"
)))]
use planes::Kernel;

/// Blocks per group, the bits of a base-field element.
const GROUP: usize = 64;
/// Groups per kernel call.
const LANES: usize = 8;

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
    parallel::map_reduce_with_state(
        n_groups / lanes,
        Kernel::new,
        Sums::new,
        |kernel, sums, chunk| {
            let mut w = [F192::ZERO; LANES];
            for q in (0..lanes).filter(|&q| live(chunk * lanes + q)) {
                let group = chunk * lanes + q;
                let pair = weight(group / 2);
                w[q] = if group.is_multiple_of(2) { pair } else { pair * F192::Y };
                kernel.load(q, [a, b, c].map(|table| &table[group * GROUP * 8..][..GROUP * 8]));
            }
            if w != [F192::ZERO; LANES] {
                kernel.flush(&w, sums);
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

    /// The two kernels agree, lane by lane, with some lanes left out.
    #[cfg(all(
        target_arch = "x86_64",
        target_feature = "avx512bw",
        target_feature = "avx512vbmi",
        target_feature = "avx512bitalg",
        target_feature = "gfni"
    ))]
    #[test]
    fn kernels_agree() {
        let mut rng = Rng::new(13);
        let [a, b, c]: [Vec<u8>; 3] = std::array::from_fn(|_| (0..LANES * GROUP * 8).map(|_| rng.next_u8()).collect());
        let mut w = [F192::ZERO; LANES];
        let (mut fast, mut portable) = (bytes::Kernel::new(), planes::Kernel::new());
        for q in [0, 1, 3, 6, 7] {
            w[q] = rng.ext();
            let group = [&a, &b, &c].map(|table| &table[q * GROUP * 8..][..GROUP * 8]);
            fast.load(q, group);
            portable.load(q, group);
        }
        let (mut got, mut want) = (Sums::new(), Sums::new());
        fast.flush(&w, &mut got);
        portable.flush(&w, &mut want);
        assert_eq!(got.finish(), want.finish());
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
