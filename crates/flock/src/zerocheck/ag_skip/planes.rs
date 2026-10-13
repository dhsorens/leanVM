//! The portable kernel, bit-sliced: a group's 64 blocks are transposed into 64 planes, bit `K` of
//! plane `i` being bit `i` of block `K`, and the extension and the jet product run on planes.
//!
//! ```text
//!     transpose    64 blocks x 64 bits  ->  64 planes
//!     extend       R a, R b              on planes, by tables of 4-plane XORs
//!     multiply     the jet products      on planes, ANDs and XORs
//! ```
//!
//! Eight groups ride the eight words of a vector.

use std::mem::MaybeUninit;

use primitives::field::{F192, Weights8};

use super::{GROUP, LANES, Sums};
use crate::ag_code::tables::R_ROWS;
use crate::ag_code::{K, SUFFIX};

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

/// The blocks of up to eight groups, a group per lane.
pub struct Kernel([[Lanes; K]; 3]);

impl Kernel {
    pub fn new() -> Self {
        Self([[Lanes::ZERO; K]; 3])
    }

    /// Load a group's blocks of `a`, `b`, `c` into lane `q`.
    pub fn load(&mut self, q: usize, tables: [&[u8]; 3]) {
        for (rows, table) in self.0.iter_mut().zip(tables) {
            debug_assert_eq!(table.len(), GROUP * 8);
            for (row, word) in rows.iter_mut().zip(table.as_chunks::<8>().0) {
                row.0[q] = u64::from_le_bytes(*word);
            }
        }
    }

    /// Add the loaded groups to `sums`, lane `q` weighing `w[q]`: zero for a lane not loaded since
    /// the last call, which may hold anything.
    pub fn flush(&mut self, w: &[F192; LANES], sums: &mut Sums) {
        let [a, b, c] = &mut self.0;
        transpose(a);
        transpose(b);
        transpose(c);
        let (mut l, mut r) = ([Lanes::ZERO; SUFFIX], [Lanes::ZERO; SUFFIX]);
        extend(a, &mut l);
        extend(b, &mut r);

        let w = Weights8::new(w);
        // Jets multiply as power series: order `n` of the product is the sum over `s + t = n`.
        // Order 0 of a message is the message, and order 3 lives at the first 30 points only.
        for i in 0..K {
            sums.jets[i].add(&w, &((a[i] & r[i]) ^ (l[i] & b[i])).0);
            let order2 = (a[i] & r[K + i]) ^ (l[i] & r[i]) ^ (l[K + i] & b[i]);
            sums.jets[K + i].add(&w, &order2.0);
            sums.c[i].add(&w, &c[i].0);
        }
        for i in 0..SUFFIX - 2 * K {
            let order3 = (a[i] & r[2 * K + i]) ^ (l[i] & r[K + i]) ^ (l[K + i] & r[i]) ^ (l[2 * K + i] & b[i]);
            sums.jets[2 * K + i].add(&w, &order3.0);
        }
    }
}
