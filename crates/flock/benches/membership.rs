//! The zero-knowledge preimage and Merkle membership proof (`flock::membership`), end to end: the proof, then
//! the opening of each of its two claims.
//!
//! ```text
//! BENCH_REPEAT=3 cargo bench -p flock --bench membership
//! ```
//!
//! `BENCH_TRACING=1` prints the final pass's span tree.

use std::time::Instant;

use bench::{Plan, Timing};
use fiat_shamir::transcript::{Proof, ProverState, Receiver, Transmitter, VerifierState};
use flock::membership::{self, Circuit, DEPTH, N_VARS, Secret};
use flock::standalone::opening;
use primitives::{field::F64, test_rng::Rng};

#[global_allocator]
static ALLOCATOR: bench::Jemalloc = bench::Jemalloc;

const STAGES: [&str; 5] = ["witness", "commit", "sumchecks", "open witness", "open circuit"];

fn opening_bytes(proof: &Proof) -> usize {
    let merkle = |m: &fiat_shamir::merkle::PrunedMerklePaths| {
        32 * m.sibling_hashes.len() + m.leaf_data.iter().map(|row| 8 * row.len()).sum::<usize>()
    };
    24 * proof.stream.len() + proof.merkle.iter().map(merkle).sum::<usize>()
}

fn main() {
    bench::init_tracing_from_env();
    let mut rng = Rng::new(0x9E37_79B9_7F4A_7C15);
    let mut bytes = || std::array::from_fn(|_| rng.next_u64() as u8);
    let secret = Secret {
        x: bytes(),
        siblings: std::array::from_fn(|_| bytes()),
        directions: 0x5A3C_96E1,
    };
    let statement = secret.statement();

    // The circuit is fixed: its local matrices are committed once, and the root is part of the statement.
    let t = Instant::now();
    let circuit = Circuit::new();
    let index = circuit.index();
    let (index_root, index_data) = opening::commit(&index);
    let setup_s = t.elapsed().as_secs_f64();
    let label = [b"membership".as_slice(), &index_root, &statement.y, &statement.root].concat();

    let prove_pass = |rng: &mut Rng| {
        let _span = tracing::info_span!("Membership prove").entered();
        let mut secs = [0.0; STAGES.len()];
        let mut stage = 0;
        let mut timed = |secs: &mut [f64; STAGES.len()], t: Instant| {
            secs[stage] = t.elapsed().as_secs_f64();
            stage += 1;
        };

        let t = Instant::now();
        let witness = circuit.witness(&secret, &mut || rng.next_u64());
        timed(&mut secs, t);

        let t = Instant::now();
        let mask: Vec<F64> = (0..1 << N_VARS).map(|_| F64(rng.next_u64())).collect();
        let table = membership::committed(&witness, &mask, &mut || rng.next_u64());
        let (root, data) = opening::commit(&table);
        timed(&mut secs, t);

        let t = Instant::now();
        let mut ps = ProverState::from_label(&label);
        ps.add_root(&root);
        let claims = membership::prove(&circuit, &statement, &witness, &mask, &mut ps);
        let proof = ps.into_proof();
        timed(&mut secs, t);

        let t = Instant::now();
        let hidden = membership::hidden_point(&claims.witness);
        let witness_opening = opening::open(&table, &root, &data, &hidden);
        timed(&mut secs, t);

        let t = Instant::now();
        let index_opening = opening::open(&index, &index_root, &index_data, &claims.index);
        timed(&mut secs, t);
        ((proof, witness_opening, index_opening), secs)
    };

    let plan = Plan::from_env();
    let mut stages: [Timing; STAGES.len()] = std::array::from_fn(|_| Timing::default());
    let mut pass_rng = Rng::new(1);
    let ((proof, witness_opening, index_opening), _) = plan.warm_then_measure(|final_pass| {
        let _quiet = (!final_pass).then(bench::suppress_tracing);
        let (out, secs) = prove_pass(&mut pass_rng);
        for (timing, s) in stages.iter_mut().zip(secs) {
            timing.push(s);
        }
        out
    });

    let ((root, claims), verify_time) = Plan::new(plan.repeat, 0).measure_quiet(|_| {
        let mut vs = VerifierState::from_label(&label, &proof);
        let root = vs.next_root().expect("witness root");
        let claims = membership::verify(&statement, &mut vs).expect("the sumchecks verify");
        vs.finish().expect("proof fully consumed");
        (root, claims)
    });
    let (_, openings_time) = Plan::new(plan.repeat, 0).measure_quiet(|_| {
        assert!(opening::verify(
            &root,
            &membership::hidden_point(&claims.witness),
            &witness_opening
        ));
        assert!(opening::verify(&index_root, &claims.index, &index_opening));
    });

    println!("\nPreimage and Merkle membership, depth {DEPTH}, 2^{N_VARS} wires");
    println!("  setup, circuit committed once     : {:>8.1} ms", setup_s * 1e3);
    for (name, timing) in STAGES.iter().zip(&stages) {
        // The warmup pass pushed a sample too.
        let mut kept = Timing::default();
        timing.samples()[1..].iter().for_each(|&s| kept.push(s));
        println!("  {name:<34}: {:>8.1} ms{}", kept.mean() * 1e3, kept.spread());
    }
    println!(
        "  verify sumchecks                  : {:>8.3} ms",
        verify_time.mean() * 1e3
    );
    println!(
        "  verify openings                   : {:>8.3} ms",
        openings_time.mean() * 1e3
    );
    // The witness root rides the proof as two scalars; everything after it is sumcheck messages.
    println!(
        "  proof                             : {} scalars + root = {} bytes",
        proof.stream.len() - 2,
        24 * (proof.stream.len() - 2) + 32
    );
    println!(
        "  witness opening                   : {:.1} KiB",
        opening_bytes(&witness_opening) as f64 / 1024.0
    );
    println!(
        "  circuit opening                   : {:.1} KiB",
        opening_bytes(&index_opening) as f64 / 1024.0
    );
    println!(
        "  peak memory                       : {:.1} GiB",
        bench::peak_rss_bytes() as f64 / (1u64 << 30) as f64
    );
}
