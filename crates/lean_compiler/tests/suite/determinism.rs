//! One source compiles to one program, always, and the same program it compiled
//! to yesterday.
//!
//! The bytecode digest leads the Fiat--Shamir transcript, so two builds of one
//! source that disagree are two incompatible proof systems, and the symptom is a
//! proof that stops verifying rather than a crash.
//!
//! Two different properties, and only the first is about determinism:
//!
//! * *Within a process*, compiling twice is a real perturbation rather than a
//!   repeat, since `RandomState` bumps its seed once per map, so the second
//!   compilation hashes with different keys than the first.
//! * *Across commits*, `GOLDEN` is a SNAPSHOT of the compiler's output. It does
//!   not prove determinism (nothing iterating a hash container reaches the
//!   bytecode today, and deliberately reversing the branch-output order at a join
//!   moves no digest). It earns its place a different way: a codegen change that
//!   was not intended shows up here and nowhere else, and every entry that moved
//!   this far was a change someone then had to justify.
//!
//! So a moved digest is a question, not a chore: update `GOLDEN` in the same
//! commit and say in the message which change moved it.

use std::collections::BTreeMap;
use std::fs;

use lean_compiler::{compile, parse};
use leanvm_core::cpu::Program;

/// `tests/programs/<name>.py` against the digest of the bytecode it compiles to.
/// The list is closed: a new program must be added here, so one cannot be added
/// without a digest.
#[rustfmt::skip]
const GOLDEN: &[(&str, &str)] = &[
    ("conditionals", "d948493d0b1231fa676c9aba93c3c05668249eacd953a966bef9321a80b8fed3"),
    ("const_params", "25fdc774d2dbac3ca73f3d324babbd51cd874e415f96f2676e45cdc904711d2d"),
    ("fibonacci", "9b9208aa0f1f5a6948b69e8aa5faede8cac64036a1c3a844e10f68da50ff41e3"),
    ("hash_heap_chain", "3c565acf19b7ac4af703d849d4cf342891cb79314823a9287f76f74cdd9cc517"),
    ("hash_slices", "e09daf8be38cb7dd9a5864c5d80225df4752bc95b6a9165fe036a8b3e7649402"),
    ("heapbuf_dyn", "3599192b8c798c81916b380d350ff41ba63192ad8c420543ec36c9e62e9a97c5"),
    ("hint", "a5b7804cef34452176d369c23ea805896c633d788f16724740be0d13f6333b55"),
    ("identities", "fbab933c4d610d764abb6b18f69d0dd93e96f59d7abf2421df8d501daa57225f"),
    ("match", "dfe85bf9b4900336db710e3dbb249ffb2634aebbc74d23c9e427189a40c4b624"),
    ("match_arms", "bebfeca3b276968094115cea11cff618c354fbab24ccb98b3fe0796db4569c4a"),
    ("nested", "606d1ed8169d1c067c14abd2c90ace23031fcee3c086ac8b4a42066f72cab8ef"),
    ("runtime_loop", "cd448397d545add46a8bb202810f4e108e3d9e3ef6c2de77aeb7720e1cca00a2"),
    ("scoping", "cd1a67a07cc148a9dbb9e832445a3259da6d116504060c4f867d01937e339431"),
    ("unroll", "59e10f7ef4c8c7c05575439dea297d5dca2e5374a7b6e6f9d3448f3086957053"),
    ("wots_walk", "03e90f07664f28ce39a52ec2a2f759191da081d2b9442f205869c7235858015d"),
];

fn digest(p: &Program) -> String {
    primitives::hash::hash(format!("{:?}", p.prog).as_bytes())
        .iter()
        .map(|b| format!("{b:02x}"))
        .collect()
}

/// Every program in `tests/programs/`, compiled twice.
#[test]
fn bytecode_is_reproducible() {
    let dir = concat!(env!("CARGO_MANIFEST_DIR"), "/tests/programs");
    let mut paths: Vec<_> = fs::read_dir(dir)
        .expect("tests/programs")
        .map(|e| e.expect("dir entry").path())
        .filter(|p| p.extension().is_some_and(|x| x == "py"))
        .collect();
    paths.sort();
    assert!(!paths.is_empty(), "no .py programs found");

    let mut actual: Vec<(String, String)> = Vec::new();
    for path in &paths {
        let name = path.file_stem().expect("file stem").to_string_lossy().into_owned();
        let src = fs::read_to_string(path).unwrap_or_else(|e| panic!("{name}: read: {e}"));
        let one = compile(&parse(&src).unwrap_or_else(|e| panic!("{name}: parse: {e}")));
        let two = compile(&parse(&src).unwrap_or_else(|e| panic!("{name}: parse: {e}")));
        assert_eq!(
            digest(&one),
            digest(&two),
            "{name}: two compilations of one source produced different bytecode, \
             so the compiler is reading a hash seed"
        );
        actual.push((name, digest(&one)));
    }

    let want: BTreeMap<&str, &str> = GOLDEN.iter().copied().collect();
    let moved: Vec<&str> = actual
        .iter()
        .filter(|(n, d)| want.get(n.as_str()) != Some(&d.as_str()))
        .map(|(n, _)| n.as_str())
        .collect();
    let dropped: Vec<&str> = want
        .keys()
        .copied()
        .filter(|n| !actual.iter().any(|(a, _)| a == n))
        .collect();
    assert!(
        dropped.is_empty(),
        "GOLDEN names a program that no longer exists: {dropped:?}"
    );
    if !moved.is_empty() {
        let table: String = actual
            .iter()
            .map(|(n, d)| format!("    (\"{n}\", \"{d}\"),\n"))
            .collect();
        panic!("bytecode changed for {moved:?}\n\nif that was intended, GOLDEN is now:\n{table}");
    }
}
