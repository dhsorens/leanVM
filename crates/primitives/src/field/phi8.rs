// CREDIT: https://github.com/succinctlabs/flock (flock-core), MIT OR Apache-2.0.
// Copyright 2025 The Binius Developers / Irreducible, Inc.
// Modifications copyright 2026 Succinct Labs, Benedikt Bunz, William Wang.
// SPDX-License-Identifier: Apache-2.0 OR MIT

//! The embedding `phi_8: GF(2^8) -> K`, read in `E`.
//!
//! Its image lies in `K`, so every image's `c1` and `c2` are zero.
//!
//! A test checks the homomorphism on every pair.

use super::{F8, F192};

/// `phi_8(2^k)` for `k < 8`: the images of the polynomial basis of `GF(2^8)`, as `K` words.
const PHI8_BASIS: [u64; 8] = [
    0x0000000000000001,
    0x033ce8beddc8a656,
    0x512620375ed2a108,
    0x0c9e636090aafc01,
    0xba4f3cd82801769c,
    0xba26e7904adb4a47,
    0x467698598926dc01,
    0x4418ae808b28bdd0,
];

const fn build_phi8_table() -> [F192; 256] {
    let mut table = [F192::ZERO; 256];
    let mut value = 1;
    while value < table.len() {
        let mut c0 = 0u64;
        let mut bit = 0;
        while bit < PHI8_BASIS.len() {
            if value & (1 << bit) != 0 {
                c0 ^= PHI8_BASIS[bit];
            }
            bit += 1;
        }
        table[value] = F192::new(c0, 0, 0);
        value += 1;
    }
    table
}

/// `phi_8(a)` for every `a`, indexed by `a`'s byte.
///
/// Its image is the unique subfield of `E` with 256 elements.
pub static PHI8_TABLE: [F192; 256] = build_phi8_table();

/// `phi_8(a)`.
#[inline]
pub fn phi8(a: F8) -> F192 {
    PHI8_TABLE[a.0 as usize]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn homomorphism_full() {
        // Exhaustive: φ(a·b)=φ(a)·φ(b) and φ(a+b)=φ(a)+φ(b) over all 65536 pairs.
        for a in 0u16..256 {
            for b in 0u16..256 {
                let fa = F8(a as u8);
                let fb = F8(b as u8);
                assert_eq!(phi8(fa * fb), phi8(fa) * phi8(fb), "mul at a={a}, b={b}");
                assert_eq!(phi8(fa + fb), phi8(fa) + phi8(fb), "add at a={a}, b={b}");
            }
        }
    }
}
