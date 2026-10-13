//! The GFNI kernel, byte-sliced: a column is one byte of each of a group's 64 blocks, and the
//! extension and the jet product run on columns.
//!
//! ```text
//!     columns      64 blocks x 8 bytes   ->  8 columns, by byte and qword shuffles
//!     extend       R a, R b              eight affine maps of the columns per byte of the suffix
//!     multiply     the jet products      on columns, ANDs and XORs
//!     slice        a column              ->  its 8 planes, one affine map and one byte shuffle
//! ```
//!
//! The extension holds nothing but the eight columns and reads its matrices as broadcasts, where
//! the bit-sliced kernel is bounded by the loads and stores of its intermediate planes.

use core::arch::x86_64::{
    __m512i, _mm512_and_si512, _mm512_gf2p8affine_epi64_epi8, _mm512_loadu_si512, _mm512_permutexvar_epi8,
    _mm512_set1_epi64, _mm512_setzero_si512, _mm512_shuffle_i64x2, _mm512_ternarylogic_epi64, _mm512_unpackhi_epi64,
    _mm512_unpacklo_epi64, _mm512_xor_si512,
};
use core::mem::transmute;

use primitives::field::{F192, Weights8};

use super::{GROUP, LANES, Sums};
use crate::ag_code::tables::R_ROWS;
use crate::ag_code::{K, SUFFIX};

/// Bytes of a message, and of its suffix (the last one short of two bits).
const MSG_BYTES: usize = K / 8;
const SUFFIX_BYTES: usize = SUFFIX.div_ceil(8);

/// `AFFINE[o][i]` maps byte `i` of a message to its part of byte `o` of the suffix of `R m`,
/// as `GF2P8AFFINEQB` reads a matrix: byte `7 - bit` is the row of output bit `bit`.
static AFFINE: [[i64; MSG_BYTES]; SUFFIX_BYTES] = {
    let mut out = [[0i64; MSG_BYTES]; SUFFIX_BYTES];
    let mut j = 0;
    while j < SUFFIX {
        let mut i = 0;
        while i < MSG_BYTES {
            let row = (R_ROWS[K + j] >> (8 * i)) & 0xff;
            out[j / 8][i] |= (row << (8 * (7 - j % 8))) as i64;
            i += 1;
        }
        j += 1;
    }
    out
};

type Columns = [__m512i; MSG_BYTES];

/// Transpose the bytes of each row, read as eight by eight, the columns reversed if `flip`.
#[inline(always)]
unsafe fn transpose_bytes(row: __m512i, flip: bool) -> __m512i {
    let idx: [u8; 64] = std::array::from_fn(|d| (8 * if flip { 7 - d % 8 } else { d % 8 } + d / 8) as u8);
    // SAFETY: the caller enables the features.
    unsafe { _mm512_permutexvar_epi8(_mm512_loadu_si512(idx.as_ptr().cast()), row) }
}

/// Transpose eight rows of eight qwords.
#[inline(always)]
unsafe fn transpose_qwords(t: [__m512i; 8]) -> [__m512i; 8] {
    // SAFETY: the caller enables the features.
    unsafe {
        let u: [__m512i; 8] = std::array::from_fn(|n| {
            let (x, y) = (t[n & !1], t[n | 1]);
            if n & 1 == 0 {
                _mm512_unpacklo_epi64(x, y)
            } else {
                _mm512_unpackhi_epi64(x, y)
            }
        });
        // Lanes `0, 1` or `2, 3` of two of `u` that share a parity.
        let v: [__m512i; 8] = std::array::from_fn(|n| {
            let (x, y) = (u[n & 5], u[(n & 5) + 2]);
            if n & 2 == 0 {
                _mm512_shuffle_i64x2::<0x44>(x, y)
            } else {
                _mm512_shuffle_i64x2::<0xee>(x, y)
            }
        });
        std::array::from_fn(|i| {
            let n = (i & 1) + ((i >> 2) << 1);
            if i & 2 == 0 {
                _mm512_shuffle_i64x2::<0x88>(v[n], v[n + 4])
            } else {
                _mm512_shuffle_i64x2::<0xdd>(v[n], v[n + 4])
            }
        })
    }
}

/// The columns of a group: byte `8 z + 7 - s` of column `i` is byte `i` of block `8 z + s`,
/// the order [`slice`] wants.
#[inline(always)]
unsafe fn columns(group: &[u8]) -> Columns {
    debug_assert_eq!(group.len(), GROUP * MSG_BYTES);
    // SAFETY: the caller enables the features; `group` holds eight rows of 64 bytes.
    unsafe {
        transpose_qwords(std::array::from_fn(|z| {
            transpose_bytes(_mm512_loadu_si512(group.as_ptr().add(64 * z).cast()), true)
        }))
    }
}

/// The columns of the suffix of `R m`.
#[inline(always)]
unsafe fn extend(m: &Columns) -> [__m512i; SUFFIX_BYTES] {
    // SAFETY: the caller enables the features.
    unsafe {
        std::array::from_fn(|o| {
            let t: Columns =
                std::array::from_fn(|i| _mm512_gf2p8affine_epi64_epi8::<0>(m[i], _mm512_set1_epi64(AFFINE[o][i])));
            let xor3 = |x, y, z| _mm512_ternarylogic_epi64::<0x96>(x, y, z);
            _mm512_xor_si512(xor3(t[0], t[1], t[2]), xor3(xor3(t[3], t[4], t[5]), t[6], t[7]))
        })
    }
}

/// The eight planes of a column, a plane per qword: bit `K` of qword `bit` is bit `bit` of the
/// column's byte for block `K`.
#[inline(always)]
unsafe fn slice(column: __m512i) -> __m512i {
    // SAFETY: the caller enables the features.
    unsafe {
        // With the column as the MATRIX and the bytes `1 << bit` as the input, the affine map
        // transposes the bits of each qword, and reverses its bytes on the way.
        let bits = _mm512_set1_epi64(0x8040_2010_0804_0201u64 as i64);
        transpose_bytes(_mm512_gf2p8affine_epi64_epi8::<0>(bits, column), false)
    }
}

/// Columns of the product's suffix, then of `c`.
const STAGED: usize = SUFFIX_BYTES + MSG_BYTES;

/// The sliced columns of up to eight groups: qword `bit` of `[column][q]` is plane
/// `8 * column + bit` of the group in lane `q`.
pub struct Kernel([[__m512i; LANES]; STAGED]);

impl Kernel {
    pub fn new() -> Self {
        // SAFETY: the module is compiled only with every feature it uses.
        Self([[unsafe { _mm512_setzero_si512() }; LANES]; STAGED])
    }

    /// Load a group's blocks of `a`, `b`, `c` into lane `q`.
    #[inline]
    pub fn load(&mut self, q: usize, [a, b, c]: [&[u8]; 3]) {
        // SAFETY: the module is compiled only with every feature it uses.
        unsafe {
            let and = |x, y| _mm512_and_si512(x, y);
            let xor3 = |x, y, z| _mm512_ternarylogic_epi64::<0x96>(x, y, z);
            let (a, b, c) = (columns(a), columns(b), columns(c));
            let (l, r) = (extend(&a), extend(&b));
            // Jets multiply as power series: order `n` of the product is the sum over `s + t = n`.
            // Order 0 of a message is the message, and order 3 lives at the first 30 points only.
            for i in 0..MSG_BYTES {
                self.0[i][q] = slice(_mm512_xor_si512(and(a[i], r[i]), and(l[i], b[i])));
                self.0[8 + i][q] = slice(xor3(and(a[i], r[8 + i]), and(l[i], r[i]), and(l[8 + i], b[i])));
                self.0[SUFFIX_BYTES + i][q] = slice(c[i]);
            }
            for i in 0..SUFFIX_BYTES - 2 * MSG_BYTES {
                let high = _mm512_xor_si512(and(l[8 + i], r[i]), and(l[16 + i], b[i]));
                self.0[16 + i][q] = slice(xor3(and(a[i], r[16 + i]), and(l[i], r[8 + i]), high));
            }
        }
    }

    /// Add the loaded groups to `sums`, lane `q` weighing `w[q]`: zero for a lane not loaded since
    /// the last call, which may hold anything.
    #[inline]
    pub fn flush(&mut self, w: &[F192; LANES], sums: &mut Sums) {
        let w = Weights8::new(w);
        let (jets, c) = self.0.split_at(SUFFIX_BYTES);
        // SAFETY: the module is compiled only with every feature it uses; a vector is eight words.
        let planes = |column: &[__m512i; LANES]| unsafe {
            transmute::<[__m512i; 8], [[u64; LANES]; 8]>(transpose_qwords(*column))
        };
        for (accs, column) in sums.jets.chunks_mut(8).zip(jets) {
            for (acc, plane) in accs.iter_mut().zip(&planes(column)) {
                acc.add(&w, plane);
            }
        }
        for (accs, column) in sums.c.chunks_mut(8).zip(c) {
            for (acc, plane) in accs.iter_mut().zip(&planes(column)) {
                acc.add(&w, plane);
            }
        }
    }
}
