//! The preimage and Merkle membership proof without sumcheck (`flock::quotient`), end to end: the proof, then the
//! openings of its four claims, the quotient table's two in one.
//!
//! ```text
//! BENCH_REPEAT=3 cargo bench -p flock --bench quotient
//! ```
//!
//! `BENCH_TRACING=1` prints the final pass's span tree.

use std::time::Instant;

use bench::{Plan, Timing};
use flock::membership::Secret;
use flock::quotient::opening::{self, Committed};
use flock::quotient::{self, Index, Table, circuit};
use primitives::{field::F64, test_rng::Rng};

#[global_allocator]
static ALLOCATOR: bench::Jemalloc = bench::Jemalloc;

const STAGES: [&str; 5] = [
    "cells",
    "prove, commitments excluded",
    "commit",
    "open",
    "verify openings",
];

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

    // The circuit is fixed: its wiring is committed once, and the root is part of the statement.
    let t = Instant::now();
    let circuit = circuit::membership();
    let index = Index::new(&circuit);
    let wiring = opening::commit(index.table());
    let setup_s = t.elapsed().as_secs_f64();
    let log_rows = circuit.log_rows;
    let inputs = circuit::membership_inputs(&secret);

    let prove_pass = |rng: &mut Rng| {
        let _span = tracing::info_span!("Quotient prove").entered();
        let mut secs = [0.0; STAGES.len()];
        let t = Instant::now();
        let cells = circuit.cells(&inputs);
        secs[0] = t.elapsed().as_secs_f64();

        let masks = std::array::from_fn(|_| std::array::from_fn(|_| F64(rng.next_u64())));
        let mut committed: Vec<Committed> = vec![];
        let mut commit_s = 0.0;
        let mut commit = |table: &Table| {
            let t = Instant::now();
            let table = opening::commit(table);
            commit_s += t.elapsed().as_secs_f64();
            let root = table.root;
            committed.push(table);
            root
        };
        let t = Instant::now();
        let proved = quotient::prove(&circuit, &index, &wiring.root, &statement, &cells, &masks, &mut commit);
        secs[1] = t.elapsed().as_secs_f64() - commit_s;
        secs[2] = commit_s;

        let t = Instant::now();
        let claims = &proved.claims;
        let opened = [
            (&proved.witness, &committed[0], vec![claims.witness.clone()]),
            (index.table(), &wiring, vec![claims.wiring.clone()]),
            (
                &proved.quotient,
                &committed[1],
                vec![claims.quotient.clone(), claims.sum.clone()],
            ),
        ]
        .map(|(table, committed, claims)| {
            let proof = opening::open(table, committed, &claims);
            (&table.layout, committed.root, claims, proof)
        });
        secs[3] = t.elapsed().as_secs_f64();

        let t = Instant::now();
        for (layout, root, claims, proof) in &opened {
            assert!(opening::verify(layout, root, claims, proof));
        }
        secs[4] = t.elapsed().as_secs_f64();
        drop(opened);
        (proved.proof, secs)
    };

    let plan = Plan::from_env();
    let mut stages: [Timing; STAGES.len()] = std::array::from_fn(|_| Timing::default());
    let mut pass_rng = Rng::new(1);
    let (proof, _) = plan.warm_then_measure(|final_pass| {
        let _quiet = (!final_pass).then(bench::suppress_tracing);
        let (proof, secs) = prove_pass(&mut pass_rng);
        for (timing, s) in stages.iter_mut().zip(secs) {
            timing.push(s);
        }
        proof
    });

    println!("\nPreimage and Merkle membership without sumcheck, 2^{log_rows} rows");
    println!("  setup, wiring committed once      : {:>8.1} ms", setup_s * 1e3);
    for (name, timing) in STAGES.iter().zip(&stages) {
        // The warmup pass pushed a sample too.
        let mut kept = Timing::default();
        timing.samples()[1..].iter().for_each(|&s| kept.push(s));
        println!("  {name:<34}: {:>8.1} ms{}", kept.mean() * 1e3, kept.spread());
    }
    println!(
        "  proof                             : {} scalars = {} bytes",
        proof.stream.len(),
        24 * proof.stream.len()
    );
    println!(
        "  peak memory                       : {:.1} GiB",
        bench::peak_rss_bytes() as f64 / (1u64 << 30) as f64
    );
}
