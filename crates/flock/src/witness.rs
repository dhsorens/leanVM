// CREDIT: https://github.com/succinctlabs/flock (flock-prover), MIT OR Apache-2.0.
//! Bit-packing helpers and the parallel witness driver for the hash R1CS.

use primitives::bits::bit_transpose_64bytes;
use primitives::stream::Stream;

/// The packed witness as bytes: the little-endian image
/// of the `u64` words on a little-endian target.
pub(crate) fn packed_bytes(words: &[u64]) -> &[u8] {
    const _: () = assert!(
        cfg!(target_endian = "little"),
        "packed witness bytes assume little-endian"
    );
    // SAFETY: `u64` has no padding or invalid bit patterns, and `u8`'s
    // alignment divides `u64`'s, so the words are a valid `8 · len` byte slice.
    unsafe { core::slice::from_raw_parts(words.as_ptr().cast::<u8>(), words.len() * 8) }
}

// ---------------------------------------------------------------------------
// Generic witness packing driver.
// ---------------------------------------------------------------------------

/// Drive the parallel chunked witness build for `2^n_blocks_log` blocks.
/// Returns `(z, a, b, z_lincheck)`: the three bit-packed `u64` tables (`K / 64`
/// words per block) and the lincheck byte stripe.
///
/// `per_block(t, z_u64, a_u64, b_u64)` populates block `t`'s `(z, a, b)` data:
/// 3 zero-initialized `u64`-buffers of length `K / 64`. `K` is derived from
/// `k_log`. Every block is built, so an encoder that pins a constant wire has it
/// set across the whole batch (see `lincheck`'s `LincheckCircuit::const_pin_col`).
pub(crate) fn drive_witness_packed_and_lincheck<F>(
    n_blocks_log: usize,
    k_log: usize,
    per_block: F,
) -> (Vec<u64>, Vec<u64>, Vec<u64>, Vec<u8>)
where
    F: Fn(usize, &mut [u64], &mut [u64], &mut [u64]) + Sync,
{
    let k = 1usize << k_log;
    let u64_per_block = k / 64;
    let n_total = 1usize << n_blocks_log;
    assert!(
        n_total >= 8 && n_total.is_multiple_of(8),
        "lincheck stripe layout requires n_total ≥ 8 and divisible by 8"
    );

    let total_words = n_total * u64_per_block;
    // SAFETY (x4): group `g` publishes chunk `g` of every table in full below, and the chunk counts match.
    // The z/a/b chunks are 8 blocks of packed words, and the stripe chunk is the transpose's k bytes.
    let mut z = unsafe { primitives::uninit_vec::<u64>(total_words) };
    let mut a = unsafe { primitives::uninit_vec::<u64>(total_words) };
    let mut b = unsafe { primitives::uninit_vec::<u64>(total_words) };
    let mut z_lincheck = unsafe { primitives::uninit_vec::<u8>((n_total / 8) * k) };

    // Four output tables at two widths, indexed by the same group: `z`/`a`/`b`
    // take eight blocks' packed words, `z_lincheck` takes one byte stripe.
    let group_words = 8 * u64_per_block;
    let z_chunks = parallel::Chunks::new(&mut z, group_words);
    let a_chunks = parallel::Chunks::new(&mut a, group_words);
    let b_chunks = parallel::Chunks::new(&mut b, group_words);
    let stripe_chunks = parallel::Chunks::new(&mut z_lincheck, k);
    debug_assert_eq!(z_chunks.count(), stripe_chunks.count());

    // Each group builds in its worker's scratch, which stays in cache, then streams out.
    //
    //     scratch  z | a | b   8 blocks each, zeroed then ORed into
    //     stripe               the bit transpose of the 8 z blocks
    //
    // Building in place instead would fetch every output line before writing it.
    parallel::map_reduce_with_state(
        z_chunks.count(),
        || (vec![0u64; 3 * group_words], vec![0u8; k]),
        || (),
        |(scratch, stripe), (), g| {
            scratch.fill(0);
            let (z_grp, rest) = scratch.split_at_mut(group_words);
            let (a_grp, b_grp) = rest.split_at_mut(group_words);
            for k_in in 0..8 {
                let range = k_in * u64_per_block..(k_in + 1) * u64_per_block;
                per_block(
                    8 * g + k_in,
                    &mut z_grp[range.clone()],
                    &mut a_grp[range.clone()],
                    &mut b_grp[range],
                );
            }

            // Bit-transpose 8 z chunks into the lincheck stripe.
            for (i, out) in stripe.as_chunks_mut::<64>().0.iter_mut().enumerate() {
                let rows: [[u8; 8]; 8] = std::array::from_fn(|l| z_grp[l * u64_per_block + i].to_le_bytes());
                bit_transpose_64bytes(rows.as_flattened().try_into().expect("64 bytes"), out);
            }

            // SAFETY: each group `g` takes chunk `g` of each table exactly once, and
            // all four tables stay borrowed for the whole dispatch.
            let stream = Stream::new();
            unsafe {
                stream.copy(z_chunks.get(g), z_grp);
                stream.copy(a_chunks.get(g), a_grp);
                stream.copy(b_chunks.get(g), b_grp);
                stream.copy(stripe_chunks.get(g), stripe);
            }
        },
        |(), ()| (),
    );

    (z, a, b, z_lincheck)
}
