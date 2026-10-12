//! Bridge to the flock Keccak prover ([`flock::hash`]), single-PCS.
//!
//! `q_flock` (flock's packed witness, 64 bits per `F64` word) is committed as a
//! column in leanVM's ONE stacked `F64` witness (§sec:stacking), with no separate
//! flock commitment. The VM's `SHA3` table binds to it by point-eval equality (its
//! value columns and `q_flock`'s slots are point-evals of the same committed
//! stack), and flock's R1CS validity is discharged by the same stacked WHIR: the
//! reduction's tower-field claim passes through [`ring_switch_open`] /
//! [`ring_switch_verify`] and joins the batch-mixed opening ([`::pcs::stack_open`]).
//!
//! ## The mapping
//!
//! The VM's `SHA3(m, tail, cap) -> out` is one [`primitives::hash::step`] on the
//! 25 lanes those thirteen cells hold, written to thirteen cells in the same
//! order ([`CELL_LANES`]). Every lane is one whole packed word of the row's
//! quarter: input lane `i` is slot `i`, output lane `i` slot `25 + i`, so the
//! memory interaction binds every input and output of the relation.
//!
//! ## Rows and blocks
//!
//! A flock block proves three steps and is four quarters, the fourth pinned to
//! the step of the all-zero state (`flock::hash`). `SHA3` table row `r` is
//! quarter `r mod 4` of block `r / 4`, so the table keeps a power-of-two height
//! and a lane's column is still one strided slice of `q_flock`, as long as every
//! fourth row is a step of the zero state. The fill blocks' `SHA3` dummies are
//! exactly that, and they run last, so `cpu::filler` fills the table until they
//! are a quarter of it and `interleave_dummies` moves them into place: the bus
//! is a multiset, indifferent to row order.

use crate::transcript::{ProverState, VerifierState};
use flock::hash::{
    DUMMY_QUARTER, IN_WORD, Instance, KeccakSetup, OUT_WORD, QUARTER_WORDS_LOG, QUARTERS_LOG, ReductionReplay,
    STEPS_PER_BLOCK,
};
use flock::verifier::VerifyError;
use primitives::field::{F64, F192};
use primitives::hash::STATE_LANES;
use primitives::stream::Stream;

pub use flock::hash::{SliceClaim, qflock_kappa, ring_switch_open, ring_switch_verify};

/// `log2` of the least `SHA3` table height: flock's floor of eight blocks.
pub const MIN_LOG_ROWS: usize = 3 + QUARTERS_LOG;

/// The steps flock proves for a `SHA3` table of `2^log_rows` rows: all but the
/// dummy quarters.
pub fn n_steps(log_rows: usize) -> usize {
    assert!(log_rows >= MIN_LOG_ROWS, "the SHA3 table is below flock's floor");
    STEPS_PER_BLOCK << (log_rows - QUARTERS_LOG)
}

/// The least `SHA3` table height holding `rows` executed steps beside its dummy
/// quarters, which are fill on top of them.
pub fn min_rows(rows: usize) -> usize {
    (rows.div_ceil(STEPS_PER_BLOCK) << QUARTERS_LOG)
        .next_power_of_two()
        .max(1 << MIN_LOG_ROWS)
}

/// Move the last quarter of `rows`, the fill's dummies, onto every fourth row.
/// Rows not a multiple of four are left alone, for `Layout` to refuse.
pub(crate) fn interleave_dummies<T>(rows: &mut Vec<T>) {
    let per = 1 << QUARTERS_LOG;
    if !rows.len().is_multiple_of(per) {
        return;
    }
    let blocks = rows.len() / per;
    let dummies = rows.split_off(STEPS_PER_BLOCK * blocks);
    let mut steps = std::mem::take(rows).into_iter();
    for dummy in dummies {
        rows.extend(steps.by_ref().take(STEPS_PER_BLOCK));
        rows.push(dummy);
    }
}

/// Cells a sponge state occupies.
pub const STATE_CELLS: usize = 13;
/// Cells one `SHA3` row touches: thirteen read, thirteen written.
pub const ROW_CELLS: usize = 2 * STATE_CELLS;
/// The state cell holding lane 16 alone, its high lane zero.
pub const LONE_CELL: usize = 8;

/// The lanes each state cell holds, `(lo, hi)`, where a `None` high lane is a
/// literal zero: lanes 0..16 two to a cell (the eight cells a block's 128 message
/// bytes fill), then lane 16 alone, then the capacity lanes 17..25.
pub const CELL_LANES: [(usize, Option<usize>); STATE_CELLS] = {
    let mut t = [(0usize, None); STATE_CELLS];
    let mut c = 0;
    while c < STATE_CELLS {
        t[c] = if c < LONE_CELL {
            (2 * c, Some(2 * c + 1))
        } else if c == LONE_CELL {
            (16, None)
        } else {
            (2 * c - 1, Some(2 * c))
        };
        c += 1;
    }
    t
};

/// The fifty within-instance value slots in canonical order: the input lanes
/// `0..25`, then the output lanes, matching `tables::SHA3_VALUE_COLS`.
pub const SLOTS: [usize; 2 * STATE_LANES] = {
    let mut s = [0usize; 2 * STATE_LANES];
    let mut i = 0;
    while i < STATE_LANES {
        s[i] = IN_WORD + i;
        s[STATE_LANES + i] = OUT_WORD + i;
        i += 1;
    }
    s
};

/// The 25 lanes thirteen state cells hold.
pub fn state_of_cells(cells: &[F192; STATE_CELLS]) -> [u64; STATE_LANES] {
    let mut s = [0u64; STATE_LANES];
    for (cell, &(lo, hi)) in cells.iter().zip(&CELL_LANES) {
        s[lo] = cell.c0;
        if let Some(hi) = hi {
            s[hi] = cell.c1;
        }
    }
    s
}

/// The thirteen state cells holding 25 lanes (canonical: top limbs zero, and the
/// lone cell's high lane zero).
pub fn cells_of_state(s: &[u64; STATE_LANES]) -> [F192; STATE_CELLS] {
    std::array::from_fn(|c| {
        let (lo, hi) = CELL_LANES[c];
        F192::new(s[lo], hi.map_or(0, |hi| s[hi]), 0)
    })
}

/// What a `SHA3` instruction writes, given the thirteen cells it reads.
pub fn step_cells(cells: &[F192; STATE_CELLS]) -> [F192; STATE_CELLS] {
    cells_of_state(&primitives::hash::step(&state_of_cells(cells)))
}

/// Flock-native reduction buffers emitted in the same fused pass as the
/// committed, flattened `q_flock`. They stay alive across commit, bus, and
/// constraint proving so reduction needs no second witness pass.
pub(crate) struct PreparedReductionWitness {
    n_steps: usize,
    z_packed: Vec<u64>,
    a_packed: Vec<u64>,
    b_packed: Vec<u64>,
    z_lincheck: Vec<u8>,
}

impl PreparedReductionWitness {
    pub(crate) fn n_steps(&self) -> usize {
        self.n_steps
    }

    pub(crate) fn prove(&self, ps: &mut ProverState) -> SliceClaim {
        KeccakSetup::new(self.n_steps).prove_reduction_precomputed(
            &self.z_packed,
            &self.a_packed,
            &self.b_packed,
            &self.z_lincheck,
            ps,
        )
    }
}

/// Lift flock's packed witness (64 bits per word, bit `i` at position `i`) into
/// the committed `F64` column: word for word, which is exactly `pcs::pack`'s
/// LSB-first convention on the same bit string.
fn flatten_packed_into(packed: &[u64], out: &mut [F64]) {
    assert_eq!(out.len(), packed.len(), "q_flock's window is the wrong size");
    // Write directly into the committed window and publish it with streaming stores.
    // SAFETY: `F64` is `repr(transparent)` over `u64`, so the two slices are the
    // same bytes.
    let words: &mut [u64] = unsafe { std::slice::from_raw_parts_mut(out.as_mut_ptr().cast(), out.len()) };
    parallel::chunks_mut_zip(words, packed, 1 << 14, |_, dst, src| Stream::new().copy(dst, src));
}

/// Build the committed `q_flock` column (flock's packed witness) for the `SHA3`
/// table's `rows`, in table order, and retain the Flock-native layouts produced
/// by that same fused pass so reduction does not regenerate them later.
pub(crate) fn build_qflock_prepared(rows: &[Instance], q_flock: &mut [F64]) -> PreparedReductionWitness {
    let n_steps = n_steps(crate::log2_strict_usize(rows.len()));
    let (quarters, _) = rows.as_chunks::<{ 1 << QUARTERS_LOG }>();
    assert!(
        quarters
            .iter()
            .all(|q| q[DUMMY_QUARTER] == flock::hash::padding_instance()),
        "every fourth SHA3 row must be a step of the zero state (cpu::filler)"
    );
    let instances: Vec<Instance> = quarters.iter().flat_map(|q| &q[..STEPS_PER_BLOCK]).copied().collect();
    let setup = KeccakSetup::new(n_steps);
    let (z_packed, a_packed, b_packed, z_lincheck) =
        flock::hash::generate_witness_with_ab_packed_and_lincheck(&instances, setup.n_blocks_log());
    flatten_packed_into(&z_packed, q_flock);
    PreparedReductionWitness {
        n_steps,
        z_packed,
        a_packed,
        b_packed,
        z_lincheck,
    }
}

/// `log2` of a row's packed span, one quarter of a block: the number of low
/// coords of a `q_flock` point that carry the slot's bits, and the stride between
/// consecutive rows' same-slot words in `q_flock`. A value claim on `q_flock`
/// is thus a boolean-selector (strided) claim with this stride.
pub const SLOT_STRIDE_LOG: usize = QUARTER_WORDS_LOG;

/// **Flock reduction only** (prover): run flock's zerocheck + lincheck over
/// the table's `rows` and return the committed `q_flock` with the one
/// [`SliceClaim`] on it. Does NOT open the PCS.
#[cfg(test)]
fn prove_reduction(rows: &[Instance], ps: &mut ProverState) -> (Vec<F64>, SliceClaim) {
    let mut q_flock = vec![F64::ZERO; rows.len() << SLOT_STRIDE_LOG];
    let reduced = build_qflock_prepared(rows, &mut q_flock).prove(ps);
    (q_flock, reduced)
}

/// `q_flock` on its own, for the tests that only need the committed column.
#[cfg(test)]
fn build_qflock(rows: &[Instance]) -> Vec<F64> {
    let mut q_flock = vec![F64::ZERO; rows.len() << SLOT_STRIDE_LOG];
    build_qflock_prepared(rows, &mut q_flock);
    q_flock
}

/// **Flock reduction only** (verifier): mirror of `prove_reduction`. Replay the
/// zerocheck + lincheck sub-proofs straight off the shared stream, and recover the
/// one claim on `q_flock` for the PCS to discharge.
pub fn verify_reduction(n_steps: usize, vs: &mut VerifierState) -> Result<ReductionReplay, VerifyError> {
    KeccakSetup::new(n_steps).verify_reduction(vs)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn f(x: u64) -> F64 {
        F64(x)
    }

    /// The smallest table: thirty-two rows, every fourth a zero-state dummy.
    const LOG_ROWS: usize = MIN_LOG_ROWS;

    fn sample_rows() -> Vec<Instance> {
        let mut rows: Vec<Instance> = (0..n_steps(LOG_ROWS) as u64)
            .map(|i| std::array::from_fn(|l| 0x0101_0101_0101_0101u64.wrapping_mul(i + 1) ^ l as u64))
            .collect();
        rows.resize(1 << LOG_ROWS, flock::hash::padding_instance());
        interleave_dummies(&mut rows);
        rows
    }

    /// The cell layout round-trips, and a zero-state step over 64 message bytes
    /// and the padding is the hash of those bytes.
    #[test]
    fn cells_carry_the_state() {
        let s: [u64; STATE_LANES] = std::array::from_fn(|i| 0x1111 * (i as u64 + 1));
        assert_eq!(state_of_cells(&cells_of_state(&s)), s);
        let msg: Vec<u8> = (0..64u8).collect();
        let mut cells = [F192::ZERO; STATE_CELLS];
        for (c, cell) in cells.iter_mut().enumerate().take(4) {
            let w = |k: usize| u64::from_le_bytes(msg[8 * k..8 * k + 8].try_into().unwrap());
            *cell = F192::new(w(2 * c), w(2 * c + 1), 0);
        }
        cells[4] = F192::new(primitives::hash::PAD_FIRST as u64, 0, 0);
        let out = step_cells(&cells);
        let digest: Vec<u8> = [out[0].c0, out[0].c1, out[1].c0, out[1].c1]
            .iter()
            .flat_map(|w| w.to_le_bytes())
            .collect();
        assert_eq!(digest, primitives::hash::hash(&msg));
    }

    /// `q_flock`'s packed slots hold every row's input and output lanes, the
    /// dummies' included.
    #[test]
    fn qflock_words_match_layout() {
        let rows = sample_rows();
        let q_flock = build_qflock(&rows);
        assert_eq!(q_flock.len(), 1 << qflock_kappa(n_steps(LOG_ROWS)));
        let slot = |j: usize, s: usize| q_flock[j * (1 << SLOT_STRIDE_LOG) + s];
        for (j, input) in rows.iter().enumerate() {
            let out = primitives::hash::step(input);
            for i in 0..STATE_LANES {
                assert_eq!(slot(j, SLOTS[i]), f(input[i]));
                assert_eq!(slot(j, SLOTS[STATE_LANES + i]), f(out[i]));
            }
        }
    }

    /// The Flock reduction (zerocheck + lincheck) is a clean, self-contained
    /// unit: run WITHOUT any PCS open, the prover's claim on the committed witness
    /// `q_flock` is exactly what the verifier recovers by replaying the sub-proofs.
    #[test]
    fn reduction_roundtrip() {
        let rows = sample_rows();
        let q_flock = build_qflock(&rows);
        let dummy = vec![f(7); 8];
        let stacked = crate::witness::stack(&[q_flock.clone(), dummy]);
        let offset = stacked.placements[0].offset;

        let mut ps = ProverState::from_label(b"reduce");
        let _committed = crate::pcs::commit(&mut ps, &stacked.q, stacked.shape, crate::pcs::TEST_LOG_INV_RATE);
        let (z_packed, reduced) = prove_reduction(&rows, &mut ps);
        let bundle = ps.into_proof();

        assert_eq!(z_packed, q_flock, "reduction witness must equal committed q_flock");
        assert_eq!(&stacked.q[offset..offset + z_packed.len()], z_packed.as_slice());

        let mut vs = VerifierState::from_label(b"reduce", &bundle);
        let _root = crate::pcs::read_commitment(&mut vs).unwrap();
        let replay = verify_reduction(n_steps(LOG_ROWS), &mut vs).expect("reduction verifies");
        assert_eq!(reduced, replay.claim, "reduction claim mismatch");

        let mut vs_bad = VerifierState::from_label(b"different", &bundle);
        let _root_b = crate::pcs::read_commitment(&mut vs_bad).unwrap();
        if let Ok(replay_b) = verify_reduction(n_steps(LOG_ROWS), &mut vs_bad) {
            assert!(
                replay_b.claim != replay.claim,
                "a diverged transcript must not reproduce the prover's claim"
            );
        }
    }

    /// flock's validity claims, discharged by ONE stacked WHIR over a hand-stacked
    /// witness containing `q_flock` (plus a dummy column) together with an ordinary
    /// point claim. A mismatched domain and a tampered point value are rejected.
    #[test]
    fn validity_stacked_roundtrip() {
        let rows = sample_rows();
        let q_flock = build_qflock(&rows);
        let dummy: Vec<F64> = (0..8u64).map(|i| f(0x9000 + i)).collect();
        let stacked = crate::witness::stack(&[q_flock.clone(), dummy.clone()]);
        let offset = stacked.placements[0].offset;

        let dummy_pl = stacked.placements[1];
        let low_point: Vec<F192> = (0..dummy_pl.n_vars)
            .map(|i| F192::new(0x100 + i as u64, 0x7, 0x55))
            .collect();
        let pd_value = primitives::multilinear::mle_eval(&dummy, &low_point);
        let points = vec![crate::pcs::SlotClaim::Point {
            offset: dummy_pl.offset,
            low_point: low_point.clone(),
            value: pd_value,
        }];

        let mut ps = ProverState::from_label(b"vstack");
        let committed = crate::pcs::commit(&mut ps, &stacked.q, stacked.shape, crate::pcs::TEST_LOG_INV_RATE);
        let (_z, reduced) = prove_reduction(&rows, &mut ps);
        let ring = ring_switch_open(n_steps(LOG_ROWS), offset, &reduced);
        crate::pcs::open(&mut ps, &committed, &stacked.q, &points, &ring);
        let bundle = ps.into_proof();

        let run = |label: &'static [u8], points: &[crate::pcs::SlotClaim]| -> Result<(), &'static str> {
            let mut vs = VerifierState::from_label(label, &bundle);
            let root = crate::pcs::read_commitment(&mut vs).map_err(|_| "root")?;
            let replay = verify_reduction(n_steps(LOG_ROWS), &mut vs).map_err(|_| "reduction")?;
            let ring = ring_switch_verify(n_steps(LOG_ROWS), offset, &replay.claim);
            crate::pcs::verify(
                &mut vs,
                points,
                &ring,
                stacked.shape,
                crate::pcs::TEST_LOG_INV_RATE,
                &root,
            )
            .map_err(|_| "opening")?;
            vs.finish().map_err(|_| "leftover")
        };

        run(b"vstack", &points).expect("validity verifies");
        assert!(
            run(b"different-domain", &points).is_err(),
            "validity under a mismatched transcript must fail"
        );
        let mut bad_points = points.clone();
        if let crate::pcs::SlotClaim::Point { value, .. } = &mut bad_points[0] {
            *value += F192::ONE;
        }
        assert!(run(b"vstack", &bad_points).is_err(), "tampered point value must fail");
    }
}
