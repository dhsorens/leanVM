//! Equality tables for the zerocheck kernels.

use primitives::field::F192;
pub use primitives::multilinear::eq_table as build_eq;

/// Pack a bit vector LSB-first into bytes.
#[cfg(test)]
pub fn pack_bits(bits: &[bool]) -> Vec<u8> {
    let n_bytes = bits.len().div_ceil(8);
    // Each output byte depends on 8 contiguous input bits: disjoint, so
    // process bytes in parallel.
    parallel::map_collect(n_bytes, |byte_idx| {
        let mut byte = 0u8;
        let base = byte_idx * 8;
        for j in 0..8 {
            let bit_idx = base + j;
            if bit_idx < bits.len() && bits[bit_idx] {
                byte |= 1u8 << j;
            }
        }
        byte
    })
}

/// Eq table split into a lo half (large, L2-resident) and a hi half (small,
/// kept in registers across the inner loop).
#[derive(Clone, Debug)]
pub struct SplitEq {
    pub n_lo: usize,
    pub n_hi: usize,
    pub lo: Vec<F192>,
    pub hi: Vec<F192>,
}

impl SplitEq {
    /// C++-default cap on the hi half size: keeps outer F192 muls cheap.
    pub const MAX_N_HI: usize = 7;

    pub fn new(r: &[F192]) -> Self {
        let n = r.len();
        let n_hi = n.min(Self::MAX_N_HI);
        let n_lo = n - n_hi;
        Self {
            n_lo,
            n_hi,
            lo: build_eq(&r[..n_lo]),
            hi: build_eq(&r[n_lo..]),
        }
    }
}
