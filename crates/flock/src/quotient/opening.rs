//! The commitment the four claims are opened against. Each table is known to vanish outside a fixed set of its
//! chunks, so it is committed as the WHIR lanes those chunks fill and nothing else. A claim stays a plain multilinear
//! claim on the whole table: its opening's weight is the claim's `eq` on the committed lanes.

use fiat_shamir::digest_words;
use fiat_shamir::merkle::Hash;
use fiat_shamir::transcript::{Challenger, Proof, ProverState, VerifierState};
use pcs::whir::{
    INITIAL_FOLDING_FACTOR, LOG_INV_RATE_0, ProverData, commit as whir_commit, config_for_rate,
    recursive_prover_with_basis, recursive_verifier_with_basis_succinct,
};
use primitives::field::{F64, F192};
use primitives::hash::hash;
use primitives::multilinear::{eq_eval, eq_table};

use super::Table;
use crate::standalone::Claim;

const LABEL: &[u8] = b"flock-quotient-opening";

/// Where a table's entries can be nonzero: lanes of `2^(log_n - INITIAL_FOLDING_FACTOR)` entries, each a slice of
/// one chunk.
pub struct Layout {
    pub vars: usize,
    pub log_chunk: usize,
    /// The committed message is `2^log_n` entries, of which only the lanes are encoded.
    pub log_n: usize,
    /// Each lane's chunk, and its place in that chunk.
    lanes: Vec<(usize, usize)>,
}

impl Layout {
    /// The leading `count` lanes of each listed chunk.
    pub fn new(vars: usize, log_chunk: usize, log_n: usize, chunks: &[(usize, usize)]) -> Self {
        let layout = Self {
            vars,
            log_chunk,
            log_n,
            lanes: chunks
                .iter()
                .flat_map(|&(chunk, count)| (0..count).map(move |j| (chunk, j)))
                .collect(),
        };
        let log_lane = layout.log_lane();
        assert!(log_lane <= log_chunk && log_chunk <= vars);
        assert!(layout.lanes.len() <= 1 << INITIAL_FOLDING_FACTOR);
        assert!(
            chunks
                .iter()
                .all(|&(chunk, count)| chunk >> (vars - log_chunk) == 0 && count << log_lane <= 1 << log_chunk)
        );
        layout
    }

    fn log_lane(&self) -> usize {
        self.log_n - INITIAL_FOLDING_FACTOR
    }

    /// What is committed: the lanes of `table`, in order. Panics on an entry of `table` outside them.
    pub fn message(&self, table: &Table) -> Vec<F64> {
        assert_eq!((table.vars, table.log_chunk), (self.vars, self.log_chunk));
        let lane = 1 << self.log_lane();
        let mut message = vec![F64::ZERO; self.lanes.len() * lane];
        for (index, chunk) in &table.chunks {
            let mut covered = 0;
            for (out, &(c, j)) in message.chunks_exact_mut(lane).zip(&self.lanes) {
                if c == *index {
                    out.copy_from_slice(&chunk[j * lane..(j + 1) * lane]);
                    covered += 1;
                }
            }
            let outside = chunk
                .iter()
                .enumerate()
                .any(|(i, x)| i >= covered * lane && !x.is_zero());
            assert!(!outside, "chunk {index} has entries outside its lanes");
        }
        message
    }

    /// Each lane's weight in a claim at `point`: `eq` on the coordinates above a lane's own.
    fn lane_weights(&self, point: &[F192]) -> Vec<F192> {
        assert_eq!(point.len(), self.vars);
        let (log_lane, log_chunk) = (self.log_lane(), self.log_chunk);
        self.lanes
            .iter()
            .map(|&(chunk, j)| {
                let index = chunk << (log_chunk - log_lane) | j;
                point[log_lane..].iter().enumerate().fold(F192::ONE, |w, (k, &p)| {
                    w * if (index >> k) & 1 == 1 { p } else { F192::ONE + p }
                })
            })
            .collect()
    }
}

/// A committed table, as its opening needs it.
pub struct Committed {
    pub root: Hash,
    message: Vec<F64>,
    data: ProverData,
}

pub fn commit(layout: &Layout, table: &Table) -> Committed {
    let message = layout.message(table);
    let (commitment, data) = whir_commit(&message, layout.log_n, INITIAL_FOLDING_FACTOR, LOG_INV_RATE_0);
    Committed {
        root: commitment.root,
        message,
        data,
    }
}

/// The opening's transcript, seeded by the root and the claims, and the powers of its one challenge.
fn seed(root: &Hash, claims: &[Claim]) -> [[F64; 4]; 2] {
    let mut bytes = root.to_vec();
    for claim in claims {
        for x in claim.point.iter().chain([&claim.value]) {
            for limb in [x.c0, x.c1, x.c2] {
                bytes.extend_from_slice(&limb.to_le_bytes());
            }
        }
    }
    [digest_words(&hash(LABEL)), digest_words(&hash(&bytes))]
}

fn powers(lambda: F192, count: usize) -> Vec<F192> {
    std::iter::successors(Some(F192::ONE), |&p| Some(p * lambda))
        .take(count)
        .collect()
}

/// Prove every claim of `claims` on one committed table, in one opening.
pub fn open(layout: &Layout, committed: &Committed, claims: &[Claim]) -> Proof {
    let config = config_for_rate(layout.log_n, LOG_INV_RATE_0).expect("WHIR configuration");
    let [iv, statement] = seed(&committed.root, claims);
    let mut ps = ProverState::new(iv, statement);
    let lambdas = powers(ps.sample(), claims.len());
    let lane = 1 << layout.log_lane();
    let mut weight = vec![F192::ZERO; committed.message.len()];
    let mut target = F192::ZERO;
    for (claim, &lambda) in claims.iter().zip(&lambdas) {
        target += lambda * claim.value;
        let low = eq_table(&claim.point[..layout.log_lane()]);
        let lanes = layout.lane_weights(&claim.point);
        parallel::chunks_mut(&mut weight, lane, |l, out| {
            let scale = lambda * lanes[l];
            for (w, &e) in out.iter_mut().zip(&low) {
                *w += scale * e;
            }
        });
    }
    recursive_prover_with_basis(
        &config,
        layout.log_n,
        &committed.message,
        weight,
        target,
        &committed.data.codeword,
        &committed.data.merkle_tree,
        &mut ps,
    );
    ps.into_proof()
}

/// Check an opening of `claims` against `root`.
pub fn verify(layout: &Layout, root: &Hash, claims: &[Claim], proof: &Proof) -> bool {
    let Ok(config) = config_for_rate(layout.log_n, LOG_INV_RATE_0) else {
        return false;
    };
    if claims.iter().any(|claim| claim.point.len() != layout.vars) {
        return false;
    }
    let [iv, statement] = seed(root, claims);
    let mut vs = VerifierState::new(iv, proof, statement);
    let lambdas = powers(vs.sample(), claims.len());
    let target = claims
        .iter()
        .zip(&lambdas)
        .fold(F192::ZERO, |acc, (c, &l)| acc + l * c.value);
    let log_lane = layout.log_lane();
    let lanes: Vec<Vec<F192>> = claims.iter().map(|claim| layout.lane_weights(&claim.point)).collect();
    let weight_at = |x: &[F192]| {
        let (low, high) = x.split_at(log_lane);
        let lane_eq: Vec<F192> = (0..layout.lanes.len())
            .map(|l| {
                high.iter().enumerate().fold(F192::ONE, |w, (k, &p)| {
                    w * if (l >> k) & 1 == 1 { p } else { F192::ONE + p }
                })
            })
            .collect();
        claims
            .iter()
            .zip(&lambdas)
            .zip(&lanes)
            .fold(F192::ZERO, |acc, ((claim, &lambda), lanes)| {
                let on_lanes = lanes.iter().zip(&lane_eq).fold(F192::ZERO, |s, (&w, &e)| s + w * e);
                acc + lambda * eq_eval(&claim.point[..log_lane], low) * on_lanes
            })
    };
    recursive_verifier_with_basis_succinct(
        &config,
        layout.log_n,
        layout.lanes.len(),
        target,
        root,
        weight_at,
        &mut vs,
    )
    .is_ok()
        && vs.finish().is_ok()
}
