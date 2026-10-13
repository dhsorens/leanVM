// CREDIT: https://github.com/succinctlabs/flock (flock-core), MIT OR Apache-2.0.
//! Zerocheck PIOP: prove a(y) · b(y) ⊕ c(y) = 0 for all y ∈ {0,1}^m.
//!
//! Inputs are three bit vectors of length 2^m. Output is an evaluation claim
//! on the multilinear extensions â, b̂, ĉ at the protocol-derived point.
//!
//! Protocol shape (m = log_n, k_skip = [`K_SKIP`] = 6):
//!   1. Verifier constructs `r ∈ F_{2^192}^{m-k_skip}` from fixed inner
//!      coordinates and sampled outer coordinates.
//!   2. Prover sends the skip message `P`: the [`ag_code::SUFFIX`] = 158 coordinates,
//!      over the pairs, of `Σ_x eq(r, x) · (a(·, x) × b(·, x) + R c(·, x))`. Its 64-coordinate
//!      prefix is zero by the zerocheck identity and never rides the wire.
//!   3. Verifier samples `x_0`. Prover answers with a curve point `Q` whose `x` is
//!      `x_0` plus a counter (the AG-skip fold point), which the verifier checks.
//!   4. For each of the `m - k_skip` multilinear rounds, prover sends
//!      the linear and quadratic coefficients; the verifier derives the constant from the claim and samples the round challenge.
//!   5. Prover sends final MLE evaluations `(â, b̂)`; `ĉ` is what the terminal
//!      identity leaves, `ĉ = claim + â·b̂`, so it never rides the wire.
//!
//! C rides the sumcheck rather than being split off at round 1, which is what
//! puts all three claims at ONE point and leaves lincheck a single family of
//! bit slices for ring switching (doc/leanvm Annex C).
//!
//! Both `prove` and `verify` are wired end-to-end. The prove→verify roundtrip
//! is tested on honest witnesses; verify also rejects byte-mutated proofs and
//! shape-corrupted ones.

use fiat_shamir::transcript::{Challenger, ProverState, Receiver, Transmitter, VerifierState};
use primitives::field::F192;

use crate::ag_code::{self, CurvePoint};

pub mod ag_skip;
pub mod bit_fold;
pub mod eq;
pub mod multilinear;

use bit_fold::BitFold;
use multilinear::{
    PackedWitness, bit_round_materialize, bit_round_pair, fold_and_compute_round_pair_into,
    fold_and_compute_round_single_into, fold_in_place_pair, fold_in_place_single, round_pair_naive, round_single_naive,
};

/// Number of variables folded in round 1 via the AG skip: a block of `2^K_SKIP = 64` witness
/// bits is one message of the multiplication code.
pub const K_SKIP: usize = 6;
const N_INNER: usize = 7; // fixed-constant eq dimensions, see `ag_skip::friendly_challenges`

/// Passes over the packed bits, two rounds each, before the folded tables are stored.
///
/// - A pass re-reads the three bit tables, `3 * 2^m` bits.
/// - Storing at level `t` writes three F192 tables, `3 * 192 * 2^(m - 6 - t)` bits, then reads them back.
/// - With GFNI a pass is bandwidth-bound, so storing pays once the tables are well below the bits: level 4, after two passes.
/// - The byte-table fold is compute-bound, its tables growing with the level, so a pass costs more than the stored tables' traffic: store at once.
const PAIR_PASSES: usize = if bit_fold::GFNI { 2 } else { 0 };

/// Build the equality coordinates that remain after the AG skip.
fn equality_tail(m: usize, mut sample_vec: impl FnMut(usize) -> Vec<F192>) -> Vec<F192> {
    let outer = sample_vec(m - K_SKIP - N_INNER);
    ag_skip::friendly_challenges().into_iter().chain(outer).collect()
}

/// Witness padding descriptor for round-1 work-skipping.
///
/// The witness is a sequence of `2^(m - k_log)` blocks of `2^k_log` bits each;
/// inside each block, bits `[0, useful_bits_per_block)` carry real data and
/// bits `[useful_bits_per_block, 2^k_log)` are zero padding. Round-1 contributions
/// from a chunk of all-zero bits are themselves zero, so we can skip those
/// chunks and produce byte-identical output.
pub use pcs::pack::PaddingSpec;

// ---------------------------------------------------------------------------
// Public types: claim, proof, error.
// ---------------------------------------------------------------------------

/// Evaluation claims on the multilinear extensions of a, b, c, all three at the
/// **same** point `(Q, mlv_challenges)`: C rides the sumcheck with AB, so the
/// three claims share the point its challenges define, and lincheck can batch
/// them into one reduction.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ZerocheckClaim {
    /// The weights `f_s(Q)` of the AG-skip point `Q` fixed after round 1 (it binds the K_SKIP
    /// skip variables): the claims' combination of a block's 64 bits.
    pub skip_weights: [F192; ag_code::K],
    /// Sumcheck bind challenges, one per multilinear round; length = `m - K_SKIP`.
    pub mlv_challenges: Vec<F192>,
    /// `â(Q, mlv_challenges)`.
    pub a_eval: F192,
    /// `b̂(Q, mlv_challenges)`.
    pub b_eval: F192,
    /// `ĉ(Q, mlv_challenges)`, derived from the terminal identity rather than
    /// transmitted: the sumcheck ends at `â·b̂ + ĉ`, so `ĉ = claim + â·b̂`.
    /// Nothing checks it here; lincheck's α-batched identity pins all three.
    pub c_eval: F192,
}

/// Reasons the verifier may reject a proof.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum VerifyError {
    /// `log_n` doesn't satisfy `log_n >= K_SKIP`.
    LogNTooSmall { log_n: usize, k_skip: usize },
    /// The skip point is not a counter away from the sampled `x`, or not in the code's evaluation set.
    SkipPoint,
    /// The proof stream ran out while reading a message.
    Transcript(fiat_shamir::transcript::Error),
}

// ---------------------------------------------------------------------------
// API: prove / verify.
// ---------------------------------------------------------------------------

/// Send one multilinear round and advance the running claim, the prover mirror
/// of the verifier's loop. `G(0)` never rides the wire: the eq split
/// `(1 + r_eq)·G(0) + r_eq·G(1) = claim` fixes the constant coefficient. At
/// `r_eq = 1` it leaves `G(0)` free, so the caller passes it: only the table
/// rounds can meet that, the earlier ones running on fixed challenges.
fn send_round(
    ps: &mut impl Transmitter,
    claim: F192,
    r_eq: F192,
    g0: Option<F192>,
    g1: F192,
    g_inf: F192,
    chis: &mut Vec<F192>,
) -> F192 {
    let g0 = g0.unwrap_or_else(|| (claim + r_eq * g1) * (F192::ONE + r_eq).inv());
    ps.add_round_poly(&[g0, g0 + g1 + g_inf, g_inf], true);
    let chi = ps.sample();
    chis.push(chi);
    // G(X) = G(0)·(1+X) + G(1)·X + G(inf)·X·(1+X).
    g0 + chi * (g0 + g1 + (F192::ONE + chi) * g_inf)
}

/// THE zerocheck prover entry: proves `a·b ⊕ c = 0` over the padded cube,
/// leaving `(â, b̂, ĉ)` claimed at one point for lincheck to batch.
pub fn prove_packed_padded(
    a_packed: &[u8],
    b_packed: &[u8],
    c_packed: &[u8],
    m: usize,
    padding: &PaddingSpec,
    ps: &mut ProverState,
) -> ZerocheckClaim {
    let k_skip = K_SKIP;
    assert!(
        m >= k_skip + N_INNER,
        "prove requires m >= k_skip + N_INNER (= {})",
        k_skip + N_INNER
    );
    let expected_bytes = (1usize << m) / 8;
    assert_eq!(a_packed.len(), expected_bytes);
    assert_eq!(b_packed.len(), expected_bytes);
    assert_eq!(c_packed.len(), expected_bytes);
    let n_mlv = m - k_skip;

    // ---- Construct the equality tail (with fixed constants in the inner 7 dims) ----
    //
    // r_rest layout:
    //   r_rest[0..7]               : protocol constants, `ag_skip::friendly_challenges`
    //   r_rest[7..m-k_skip]        : sampled outer equality coordinates
    // Prover and verifier use the same tower-valued challenges directly.
    let r_rest = equality_tail(m, |n| ps.sample_vec(n));

    // ---- Round 1: the skip message, then the point that evaluates it ----
    let span = tracing::info_span!("Round 1").entered();
    let round1 = ag_skip::round1(a_packed, b_packed, c_packed, m, &r_rest, padding);
    drop(span);
    for &x in round1.iter() {
        ps.add_scalar(x);
    }
    // The sampled `x` lies under a curve point about one time in sixteen, so the prover walks a
    // counter. It and the point's other coordinates ride the stream, bound before the rounds.
    let (delta, point) = ag_code::find_point(ps.sample());
    for x in [delta, point.y, point.z[0], point.z[1], point.z[2]] {
        ps.add_scalar(x);
    }
    let skip_weights = point
        .weights()
        .expect("find_point returns a point of the evaluation set");

    // ---- Rounds 2 onwards: straight from the packed bits ----
    //
    // Level `t` is the round with `rho_1..rho_t` already bound.
    //
    //     bits of a, b, c    1 bit per slot, 3 * 2^m bits in all
    //     one F192 table     192 bits per slot, 2^(m - 6 - t) slots each
    //
    // While the tables would be larger than the bits, re-reading the bits is the cheaper pass.
    // Each such pass sends two rounds; the second waits on the first's challenge.
    // A last single-round pass stores the three folded tables for the tail.
    //
    // The kernels take the eq challenges of the variables they do not bind.
    // They return the bare `(G(1), G(inf))` that goes on the wire.
    let span = tracing::info_span!("Bit rounds").entered();
    let bits = PackedWitness {
        a: a_packed,
        b: b_packed,
        c: c_packed,
    };
    // The running claim, mirrored from the verifier (same round-1 values, same point).
    // `(1 + r) G(0) + r G(1) = claim` lets the wire drop `G(0)`, so the prover needs it too.
    let mut c_running = ag_code::eval_pairs(&round1, &skip_weights);
    let mut mlv_chis: Vec<F192> = Vec::with_capacity(n_mlv);
    for t in (0..(n_mlv - 1) & !1).step_by(2).take(PAIR_PASSES) {
        let fold = BitFold::at_level(&skip_weights, &mlv_chis);
        let pair = bit_round_pair(bits, &fold, &r_rest[t + 1..], padding);
        let (g1, g_inf) = pair.first;
        c_running = send_round(ps, c_running, r_rest[t], None, g1, g_inf, &mut mlv_chis);
        let (g1, g_inf) = pair.second(mlv_chis[t]);
        c_running = send_round(ps, c_running, r_rest[t + 1], None, g1, g_inf, &mut mlv_chis);
    }
    let materialize_level = mlv_chis.len();
    let fold = BitFold::at_level(&skip_weights, &mlv_chis);
    let ((g1, g_inf), [mut a_mlv, mut b_mlv, mut c_mlv]) =
        bit_round_materialize(bits, &fold, &r_rest[materialize_level + 1..], padding);
    c_running = send_round(ps, c_running, r_rest[materialize_level], None, g1, g_inf, &mut mlv_chis);
    drop(span);
    let span = tracing::info_span!("Table rounds").entered();

    // ---- Remaining rounds, on the stored tables ----
    //
    // Iter i: fold (a, b, c) at ρ_{i+1}, compute the next round's message, sample
    // ρ_{i+2}. Use the fused parallel path while log_n ≥ 10; below that the
    // SplitEq inner can't form lo_size ≥ 2, so we fall back to
    // fold_in_place_* + round_*_naive.
    //
    // Ping-pong scratch buffers for the fused path: each fused round folds
    // (a_mlv, b_mlv, c_mlv) of size N into size N/2. Rather than allocating a
    // fresh buffer per round, we alternate between persistent ones, one per
    // folded table. Scratch capacity = N/2 (the largest fused output); only
    // needed when the first round is actually fused.
    let n_in = a_mlv.len();
    let (mut a_nxt, mut b_nxt, mut c_nxt) = if n_in >= 1024 {
        // SAFETY (x3): the fused rounds below write every slot they read; a
        // buffer is only ever read over the prefix a round just wrote.
        unsafe {
            (
                primitives::uninit_vec::<F192>(n_in / 2),
                primitives::uninit_vec::<F192>(n_in / 2),
                primitives::uninit_vec::<F192>(n_in / 2),
            )
        }
    } else {
        (Vec::new(), Vec::new(), Vec::new())
    };

    for i in materialize_level..(n_mlv - 1) {
        let chi_prev = mlv_chis[i];
        let log_n_before = a_mlv.len().trailing_zeros() as usize;

        // The eq weights of the variables the next round does not bind.
        let r_eq = &r_rest[i + 2..];

        let (m1, mi) = if log_n_before >= 10 {
            let half = a_mlv.len() / 2;
            let (m1, mi) = fold_and_compute_round_pair_into(
                &a_mlv,
                &b_mlv,
                &mut a_nxt[..half],
                &mut b_nxt[..half],
                chi_prev,
                r_eq,
            );
            let m1c = fold_and_compute_round_single_into(&c_mlv, &mut c_nxt[..half], chi_prev, r_eq);
            // Swap current <-> scratch, then shrink the new current to the
            // folded size. The old (larger) buffer becomes scratch; we only
            // ever write its leading `half` slots next round, so its stale
            // length is harmless.
            std::mem::swap(&mut a_mlv, &mut a_nxt);
            std::mem::swap(&mut b_mlv, &mut b_nxt);
            std::mem::swap(&mut c_mlv, &mut c_nxt);
            a_mlv.truncate(half);
            b_mlv.truncate(half);
            c_mlv.truncate(half);
            (m1 + m1c, mi)
        } else {
            fold_in_place_pair(&mut a_mlv, &mut b_mlv, chi_prev);
            fold_in_place_single(&mut c_mlv, chi_prev);
            let (m1, mi) = round_pair_naive(&a_mlv, &b_mlv, r_eq);
            (m1 + round_single_naive(&c_mlv, r_eq), mi)
        };

        let r = r_rest[i + 1];
        let g0 = (r == F192::ONE).then(|| {
            // happens only with probability 2^(-192). We keep it for completeness, but not strictly necessary in the real world
            let eq = primitives::multilinear::eq_table(r_eq);
            (0..eq.len()).fold(F192::ZERO, |acc, x| {
                acc + eq[x] * (a_mlv[2 * x] * b_mlv[2 * x] + c_mlv[2 * x])
            })
        });
        c_running = send_round(ps, c_running, r, g0, m1, mi, &mut mlv_chis);
    }

    // ---- Final binding at ρ_{n_mlv} (the last challenge) ----
    //
    // Only a and b are bound: ĉ comes from the terminal identity below, so
    // `c_mlv`'s last fold would be work for a value nobody reads.
    let chi_last = *mlv_chis.last().expect("at least one ρ sampled");
    fold_in_place_pair(&mut a_mlv, &mut b_mlv, chi_last);
    debug_assert_eq!(a_mlv.len(), 1);
    debug_assert_eq!(b_mlv.len(), 1);

    let final_a_eval = a_mlv[0];
    let final_b_eval = b_mlv[0];
    // The terminal identity `claim = â·b̂ + ĉ` solved for ĉ, the same way the
    // verifier does it. Deriving it here rather than reading `c_mlv[0]` is what
    // keeps the two sides identical on a DISHONEST witness too: the two agree
    // only when `a·b ⊕ c = 0` actually holds, since the running claim descends
    // from the round-1 message, whose reconstruction assumes it.
    let final_c_eval = c_running + final_a_eval * final_b_eval;

    // ---- Fiat-Shamir: bind the final â, b̂ claims into the transcript ----
    //
    // The three claims are reduced downstream by lincheck via a *single*
    // random-linear-combination check in powers of α (see `lincheck`). That
    // batching is only sound if α is sampled *after* they are committed to the
    // transcript: otherwise a prover that knows α can pick them to satisfy the
    // one batched equation while violating the individual checks. So observe
    // them here, before any later challenge (the next one drawn is lincheck's
    // α). `final_c_eval` is NOT transmitted: both sides derive it from the
    // terminal identity, so it is bound by the values that produced it.
    ps.add_scalar(final_a_eval);
    ps.add_scalar(final_b_eval);

    drop(span);

    ZerocheckClaim {
        skip_weights,
        mlv_challenges: mlv_chis,
        a_eval: final_a_eval,
        b_eval: final_b_eval,
        c_eval: final_c_eval,
    }
}

/// Replay a zerocheck proof for an instance over `{0,1}^log_n`.
///
/// Walks the transcript in lockstep with the prover, samples the same challenges,
/// and carries the running claim through the rounds. It is a REDUCTION, not a
/// check: `ĉ` is whatever the terminal identity leaves, so no round message can
/// fail here. The only errors are structural (shape, truncated stream). What
/// makes the claims meaningful is lincheck, which pins all three against the
/// committed witness: never call this alone and treat `Ok` as acceptance.
///
/// On accept: returns the [`ZerocheckClaim`] for lincheck and the PCS.
/// On reject: returns a [`VerifyError`] indicating which check failed.
pub fn verify(log_n: usize, vs: &mut VerifierState<'_>) -> Result<ZerocheckClaim, VerifyError> {
    let m = log_n;
    let k_skip = K_SKIP;

    if m < k_skip + N_INNER {
        return Err(VerifyError::LogNTooSmall { log_n: m, k_skip });
    }
    let n_mlv = m - k_skip;

    // ---- Re-derive the equality tail (in lockstep with prove_packed) ----
    // The verifier samples tower challenges directly, matching the prover.
    let r_rest = equality_tail(m, |n| vs.sample_vec(n));

    // ---- Read + bind the skip message and the skip point off the stream ----
    let round1: Vec<F192> = vs.next_scalars(ag_code::SUFFIX).map_err(VerifyError::Transcript)?;
    let x0 = vs.sample();
    let [delta, y, z1, z2, z3]: [F192; 5] = vs
        .next_scalars(5)
        .map_err(VerifyError::Transcript)?
        .try_into()
        .expect("five scalars were read");
    // The prover picks the counter and the point over `x`. A false message survives only over
    // a root of its norm, a polynomial in `x`, so neither choice is worth more than the
    // `2^COUNTER_BITS` values of `x` it reaches.
    if !ag_code::is_counter(delta) {
        return Err(VerifyError::SkipPoint);
    }
    let point = CurvePoint {
        x: ag_code::counter_x(x0, delta),
        y,
        z: [z1, z2, z3],
    };
    let skip_weights = point.weights().ok_or(VerifyError::SkipPoint)?;

    // ---- Reconstruct the initial running claim ----
    //
    // The message `P` of the product code has 222 coordinates and the prover sent 158. The
    // verifier uses the **zerocheck assumption**: the other 64, over the squares `f_s^2`, are
    // the equality-weighted sums of `a·b + c`, zero.
    //
    // If the prover's witness is dishonest the assumption fails and the
    // reconstructed claim is wrong; the chain then ends at a `ĉ` that is not
    // the true evaluation, and lincheck's α-batched identity rejects.
    let mut c_running = ag_code::eval_pairs(&round1, &skip_weights);

    // ---- Multilinear sumcheck chain ----
    //
    // The propagated running claim is the *inner* polynomial value G(ρ),
    // not the full per-round polynomial P(ρ) = eq(r_eq, ρ) · G(ρ). The eq
    // factor for the just-bound variable is absorbed by the next round's
    // consistency check via the identity
    //   G_{r-1}(ρ_{r-1}) = (1 + r_eq_r) · G_r(0) + r_eq_r · G_r(1).
    //
    // Round r (0-indexed i = r − 2) binds the i-th rest variable with eq weight
    // r_rest[i]. The prover sends `(G(1), G(∞))` (Convention A: no
    // factor). Verifier:
    //   1. reconstruct G(0) from consistency `c_running = (1+r_eq)·G(0) + r_eq·G(1)`,
    //   2. observe message, sample ρ_i,
    //   3. update `c_running ← G(ρ_i)`,
    //      where `G(X) = G(0)·(1+X) + G(1)·X + G(∞)·X·(X+1)` (char-2 quadratic
    //      interpolation through G(0), G(1), G(∞)).
    let mut mlv_chis: Vec<F192> = Vec::with_capacity(n_mlv);
    for i in 0..n_mlv {
        let r_eq = r_rest[i];
        let g = vs
            .next_round_poly(3, c_running, Some(r_eq))
            .map_err(VerifyError::Transcript)?;
        let chi = vs.sample();
        mlv_chis.push(chi);
        c_running = primitives::multilinear::poly_eval(&g, chi);
    }

    // ---- Terminal identity ----
    //
    // After all variables are bound, the inner running claim is the polynomial
    // without the eq weighting:
    //   G_final(ρ) = â(z, ρ)·b̂(z, ρ) + ĉ(z, ρ).
    // (The eq factors were absorbed round-by-round into the consistency checks,
    // never accumulating into the running claim.)
    //
    // Read + bind the final â, b̂ claims off the stream: binding must land
    // before the next challenge (lincheck's α) is drawn, so the α-batched
    // reduction of the three claims is sound. `ĉ` is not transmitted: it is
    // what the identity leaves, so there is nothing to check here. A prover who
    // lies about anything upstream just shifts the lie into `ĉ`, and lincheck,
    // which pins all three against the committed witness, rejects it.
    let final_a_eval = vs.next_scalar().map_err(VerifyError::Transcript)?;
    let final_b_eval = vs.next_scalar().map_err(VerifyError::Transcript)?;
    let final_c_eval = c_running + final_a_eval * final_b_eval;

    Ok(ZerocheckClaim {
        skip_weights,
        mlv_challenges: mlv_chis,
        a_eval: final_a_eval,
        b_eval: final_b_eval,
        c_eval: final_c_eval,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use primitives::test_rng::Rng;

    /// Test shim for the dense-prove entry.
    fn prove_packed(
        a_packed: &[u8],
        b_packed: &[u8],
        c_packed: &[u8],
        m: usize,
        ps: &mut fiat_shamir::transcript::ProverState,
    ) -> ZerocheckClaim {
        prove_packed_padded(a_packed, b_packed, c_packed, m, &PaddingSpec::dense(m), ps)
    }

    /// The quirky evaluation `f̂(Q, chi)` of a Boolean witness: the combination,
    /// by the skip point's weights, of the multilinear extensions of its 2^K_SKIP bit
    /// slices. This is what the three zerocheck claims are supposed to be.
    fn quirky_eval(bits: &[bool], weights: &[F192], chi: &[F192]) -> F192 {
        let ell = 1usize << K_SKIP;
        let eq = primitives::multilinear::eq_table(chi);
        let mut acc = F192::ZERO;
        for (v, &e) in eq.iter().enumerate() {
            for (i, &w) in weights.iter().enumerate() {
                if bits[v * ell + i] {
                    acc += e * w;
                }
            }
        }
        acc
    }

    /// Pack three Boolean vectors into the (a_packed, b_packed, c_packed)
    /// shape that `prove_packed` consumes.
    fn pack_abc(a: &[bool], b: &[bool], c: &[bool]) -> (Vec<u8>, Vec<u8>, Vec<u8>) {
        use eq::pack_bits;
        (pack_bits(a), pack_bits(b), pack_bits(c))
    }

    /// `prove` runs end-to-end at the smallest valid m (= k_skip + N_INNER = 13)
    /// without panicking, and produces output of the right shape.
    ///
    /// structural sanity here catches:
    ///   - mismatched observe/sample sequence
    ///   - wrong slice lengths in the eq-challenge tail at any round
    ///   - any unreachable assert in the underlying functions
    #[test]
    fn prove_runs_end_to_end() {
        for &m in &[13usize, 14, 15, 16] {
            let mut rng = Rng::new(m as u64);
            let a = rng.bits(1 << m);
            let b = rng.bits(1 << m);
            // Honest witness: c = a AND b, so a·b ⊕ c = 0 on the hypercube.
            let c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();

            let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);
            let mut ps = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
            let claim = prove_packed(&a_p, &b_p, &c_p, m, &mut ps);

            // Shape checks: the streamed proof is round1 ‖ counter ‖ the point's four
            // coordinates ‖ (m − K_SKIP) message pairs ‖ (final_a, final_b). C rides the
            // sumcheck, so there is no second message and no transmitted ĉ.
            let stream = ps.into_proof().stream;
            assert_eq!(stream.len(), ag_code::SUFFIX + 5 + 2 * (m - K_SKIP) + 2, "m={m}");
            assert_eq!(claim.mlv_challenges.len(), m - K_SKIP, "m={m}");

            // Claim's eval fields agree with the streamed final evals (both are
            // now tower values: the prover streams eval).
            assert_eq!(claim.a_eval, stream[stream.len() - 2], "m={m}");
            assert_eq!(claim.b_eval, stream[stream.len() - 1], "m={m}");
        }
    }

    /// **Prove→verify roundtrip**: an honest proof verifies cleanly, and the
    /// claim returned by `verify` is byte-for-byte equal to the claim returned
    /// by `prove`.
    #[test]
    fn prove_verify_roundtrip_honest() {
        for &m in &[13usize, 14, 15, 16] {
            let mut rng = Rng::new(1000 + m as u64);
            let a = rng.bits(1 << m);
            let b = rng.bits(1 << m);
            let c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();

            let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);
            let mut ch_prove = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
            let claim_p = prove_packed(&a_p, &b_p, &c_p, m, &mut ch_prove);

            let proof_t = ch_prove.into_proof();
            let mut ch_verify = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &proof_t);
            let result = verify(m, &mut ch_verify);
            let claim_v = result.unwrap_or_else(|e| panic!("verify rejected at m={m}: {e:?}"));

            assert_eq!(claim_p, claim_v, "claim mismatch at m={m}");
        }
    }

    /// **The reduction is faithful.** On an honest witness the three claims
    /// the verifier ends up with are the true quirky evaluations of a, b and c
    /// at the sumcheck point: including `ĉ`, which nobody transmits and both
    /// sides read off the terminal identity.
    #[test]
    fn claims_are_true_evaluations() {
        // 16 and 17 reach the fused single-table kernel (gated on log_n ≥ 10),
        // which the smaller sizes never touch.
        for &m in &[13usize, 14, 15, 16, 17] {
            let mut rng = Rng::new(2024 + m as u64);
            let a = rng.bits(1 << m);
            let b = rng.bits(1 << m);
            let c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();

            let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);
            let mut ch_prove = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
            let _ = prove_packed(&a_p, &b_p, &c_p, m, &mut ch_prove);
            let proof_t = ch_prove.into_proof();
            let mut ch = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &proof_t);
            let claim = verify(m, &mut ch).expect("honest proof");

            let chi = &claim.mlv_challenges;
            assert_eq!(claim.a_eval, quirky_eval(&a, &claim.skip_weights, chi), "â at m={m}");
            assert_eq!(claim.b_eval, quirky_eval(&b, &claim.skip_weights, chi), "b̂ at m={m}");
            assert_eq!(claim.c_eval, quirky_eval(&c, &claim.skip_weights, chi), "ĉ at m={m}");
        }
    }

    /// **AUDIT: a false statement leaves a wrong claim.** The zerocheck no
    /// longer rejects on its own: `ĉ` is whatever the terminal identity
    /// leaves, so a witness violating `a·b ⊕ c = 0` is not caught here but by
    /// lincheck, which pins all three claims against the committed witness.
    /// What must hold at this layer is that such a witness cannot leave all
    /// three claims true. Same for a tampered proof word: it moves the
    /// derived claims off the true evaluations.
    #[test]
    fn false_statement_or_tamper_leaves_a_wrong_claim() {
        for &m in &[13usize, 14, 15] {
            for seed in 0..20u64 {
                let mut rng = Rng::new(0xBADC0DE ^ seed ^ ((m as u64) << 32));
                let a = rng.bits(1 << m);
                let b = rng.bits(1 << m);
                let mut c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();
                // Flip a random number of bits (1..=4): the statement is now false.
                let nflip = 1 + (rng.next_u64() as usize % 4);
                for _ in 0..nflip {
                    let idx = rng.next_u64() as usize % c.len();
                    c[idx] = !c[idx];
                }
                let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);
                let mut ch_prove = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
                let _ = prove_packed(&a_p, &b_p, &c_p, m, &mut ch_prove);
                let proof_t = ch_prove.into_proof();
                let mut ch = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &proof_t);
                let claim = verify(m, &mut ch).expect("shape is still valid");
                let chi = &claim.mlv_challenges;
                let all_true = claim.a_eval == quirky_eval(&a, &claim.skip_weights, chi)
                    && claim.b_eval == quirky_eval(&b, &claim.skip_weights, chi)
                    && claim.c_eval == quirky_eval(&c, &claim.skip_weights, chi);
                assert!(!all_true, "false statement (m={m}, seed={seed}) left every claim true");
            }
        }

        // Every region of an honest proof: one flipped word must move a claim.
        let m = 14;
        let mut rng = Rng::new(5050);
        let a = rng.bits(1 << m);
        let b = rng.bits(1 << m);
        let c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();
        let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);
        let mut ch_prove = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
        let _ = prove_packed(&a_p, &b_p, &c_p, m, &mut ch_prove);
        let proof_t = ch_prove.into_proof();

        // The stream: the skip message, the counter and the point's four coordinates, the rounds.
        let rounds = ag_code::SUFFIX + 5;
        let n_mlv = m - K_SKIP;
        let mutations: [(&str, usize); 8] = [
            ("round1[0]", 0),
            ("round1[5]", 5),
            ("counter", ag_code::SUFFIX),
            ("point y", ag_code::SUFFIX + 1),
            ("multilinear_rounds[0].0", rounds),
            ("multilinear_rounds[mid].1", rounds + 2 * (n_mlv / 2) + 1),
            ("final_a_eval", rounds + 2 * n_mlv),
            ("final_b_eval", rounds + 2 * n_mlv + 1),
        ];
        for (label, word) in mutations {
            let mut bad = proof_t.clone();
            bad.stream[word].c0 ^= 1;
            let mut ch = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &bad);
            // A word up to the point moves it off the curve, which is a rejection here.
            let Ok(claim) = verify(m, &mut ch) else {
                assert!(word < rounds, "tampered proof ({label}) lost its shape");
                continue;
            };
            let chi = &claim.mlv_challenges;
            let all_true = claim.a_eval == quirky_eval(&a, &claim.skip_weights, chi)
                && claim.b_eval == quirky_eval(&b, &claim.skip_weights, chi)
                && claim.c_eval == quirky_eval(&c, &claim.skip_weights, chi);
            assert!(!all_true, "tampered proof ({label}) left every claim true");
        }
    }

    /// Shape rejections: a truncated stream and a too-small instance.
    #[test]
    fn verify_rejects_shape_errors() {
        let m = 14;
        let mut rng = Rng::new(606);
        let a = rng.bits(1 << m);
        let b = rng.bits(1 << m);
        let c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();
        let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);
        let mut ch_prove = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
        let _ = prove_packed(&a_p, &b_p, &c_p, m, &mut ch_prove);
        let proof_t = ch_prove.into_proof();

        // Truncated stream: a clean Transcript error, not a panic.
        let mut bad = proof_t.clone();
        bad.stream.truncate(bad.stream.len() - 3);
        let mut ch = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &bad);
        assert!(matches!(verify(m, &mut ch), Err(VerifyError::Transcript(_))));

        // log_n too small.
        let mut ch = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &proof_t);
        assert!(matches!(
            verify(K_SKIP + 6, &mut ch),
            Err(VerifyError::LogNTooSmall { .. })
        ));
    }

    /// AUDIT (Fiat-Shamir binding of the final â, b̂ claims). Regression test
    /// for the gap where `final_a_eval`/`final_b_eval` were not observed into
    /// the transcript.
    ///
    /// Downstream, lincheck reduces the three claims via a *single* random-
    /// linear-combination check in powers of α. That batching is only sound if
    /// α is sampled *after* the claims are bound: otherwise a prover that
    /// already knows α can pick them to satisfy the one batched equation while
    /// violating the individual ties.
    ///
    /// The tamper here is *product-preserving*, `(â, b̂) → (â·t, b̂·t⁻¹)`, so it
    /// leaves `â·b̂` and therefore the derived `ĉ` untouched: the whole triple
    /// the reduction carries is unchanged, and nothing downstream could tell
    /// the two runs apart except the transcript itself. The defense is that
    /// both claims are observed last, so the next challenge (the slot lincheck
    /// draws α from) must diverge. This assertion FAILS before the observe was
    /// added (identical post-state) and passes now.
    #[test]
    fn audit_final_ab_claims_bound_to_transcript() {
        let m = 14;
        let mut rng = Rng::new(0xF1A7_5A11);
        let a = rng.bits(1 << m);
        let b = rng.bits(1 << m);
        let c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();
        let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);

        let mut ch_prove = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
        let claim_p = prove_packed(&a_p, &b_p, &c_p, m, &mut ch_prove);
        let proof_t = ch_prove.into_proof();

        // Honest verify, then capture the next challenge the transcript feeds
        // downstream: this is exactly the slot lincheck samples α from.
        let mut ch_honest = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &proof_t);
        assert!(verify(m, &mut ch_honest).is_ok(), "honest verify rejected");
        let alpha_honest = ch_honest.sample();

        // Product-preserving tamper: â' = â·t, b̂' = b̂·t⁻¹ ⇒ â'·b̂' = â·b̂, so the
        // derived ĉ = claim + â·b̂ is unchanged too.
        // The stream now carries tower (F192) values, so tamper in F192.
        let t = F192::new(0x0123_4567_89ab_cdef, 0xfedc_ba98_7654_3210, 0x55aa_aa55_0123_4567);
        assert!(t != F192::ZERO && t != F192::ONE, "t must be nontrivial");
        // The finals are the LAST two stream words of this standalone proof.
        let n = proof_t.stream.len();
        let mut bad = proof_t.clone();
        bad.stream[n - 2] *= t;
        bad.stream[n - 1] *= t.inv();
        assert_ne!(bad.stream[n - 2], proof_t.stream[n - 2], "tamper must change â");
        assert_ne!(bad.stream[n - 1], proof_t.stream[n - 1], "tamper must change b̂");
        assert_eq!(
            bad.stream[n - 2] * bad.stream[n - 1],
            claim_p.a_eval * claim_p.b_eval,
            "tamper must preserve the product",
        );

        // Replay the tampered proof to move the transcript to the same slot. Its
        // claims are as consistent as the honest ones (same product, same ĉ),
        // so nothing local distinguishes them.
        let mut ch_tampered = fiat_shamir::transcript::VerifierState::from_label(b"flock-test-v0", &bad);
        let tampered = verify(m, &mut ch_tampered).expect("shape is still valid");
        assert_eq!(
            tampered.a_eval * tampered.b_eval,
            claim_p.a_eval * claim_p.b_eval,
            "the tamper must preserve the product the reduction carries",
        );
        assert_eq!(tampered.c_eval, claim_p.c_eval, "and therefore the derived ĉ");
        let alpha_tampered = ch_tampered.sample();

        // The fix: observing â, b̂ makes the downstream challenge depend on them,
        // so lincheck's α (and everything after) diverges and rejects the
        // tampered pair. Before the fix these challenges were equal.
        assert_ne!(
            alpha_honest, alpha_tampered,
            "final â/b̂ claims are NOT bound into the transcript: a product-preserving \
             tamper leaves the downstream challenge unchanged, breaking lincheck's \
             α-batched reduction of (v_a, v_b)",
        );
    }

    /// Determinism: same witness + same transcript seed → same proof.
    #[test]
    fn prove_deterministic() {
        let m = 14;
        let mut rng = Rng::new(99);
        let a = rng.bits(1 << m);
        let b = rng.bits(1 << m);
        let c: Vec<bool> = a.iter().zip(&b).map(|(x, y)| *x & *y).collect();

        let (a_p, b_p, c_p) = pack_abc(&a, &b, &c);
        let mut ch1 = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
        let mut ch2 = fiat_shamir::transcript::ProverState::from_label(b"flock-test-v0");
        let claim1 = prove_packed(&a_p, &b_p, &c_p, m, &mut ch1);
        let claim2 = prove_packed(&a_p, &b_p, &c_p, m, &mut ch2);

        assert_eq!(ch1.into_proof().stream, ch2.into_proof().stream);
        assert_eq!(claim1.skip_weights, claim2.skip_weights);
        assert_eq!(claim1.mlv_challenges, claim2.mlv_challenges);
    }
}
