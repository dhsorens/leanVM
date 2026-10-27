# Rust to Lean extraction

Stage 1 of the [verification roadmap](../../VERIFICATION.md): the Rust crates are translated to Lean by [hax](https://hax.cryspen.com/)'s Lean backend (Charon, then Aeneas), the translation is committed beside the crate it comes from, and CI keeps it in step with the Rust. Nothing here is proved yet; what is checked is that the extraction is current and typechecks.

## Layout

```
hax.toml                                  pins charon, aeneas, the Lean toolchain and the hax Lean library
crates/verifier/hax.toml                  the crate's scenario: what is extracted, what is left opaque
crates/verifier/proofs/verifier/
  patches/pre/NN-*.patch                  Rust rewrites, applied only while extracting
  patches/post/NN-*.patch                 rewrites of the generated Lean (none; a last resort)
  lean/                                   the Lean package hax scaffolds (package `Verifier`)
    Verifier/Extraction/                  generated: hax rewrites it on every extraction, never edit
    Verifier/Assumptions/                 hand-maintained: what the extraction takes on trust
      TypesExternal.lean, FunsExternal.lean   the Rust items left opaque, as axioms
      Std.lean                            models of standard-library items the hax Lean library lacks
    Verifier/Verification/                hand-written proofs (none yet)
formal/extraction/
  hax.sh                                  setup, extract, and run commands on the patched source
  sync_assumptions.py                     keeps Assumptions/ in step with the regenerated templates
  report.sh                               the trusted surface of each extraction, as a table
  lakefile.toml                           the workspace requiring every extraction by path
```

A crate opts in with a `hax.toml` declaring a [proof scenario](https://github.com/cryspen/hax/blob/main/docs/manual/tools.md#proof-scenarios); everything else follows from the conventions above. The scenario's `opaque` list names the items extracted as signatures only, each with the reason it is opaque, so the list is also the work remaining to extract them.

The workspace in this directory is where the extractions share their dependencies: Lake resolves Aeneas, the hax Lean library and Mathlib (and later CompPoly, ArkLib) once, in `formal/extraction/.lake/packages`, for every package it requires. `lake build` here builds them all.

## Using it

```bash
formal/extraction/hax.sh setup                  # once: cargo-hax, charon, aeneas, charon's nightly
formal/extraction/hax.sh extract                # regenerate every extraction
cd formal/extraction && lake exe cache get && lake build
```

After changing an extracted crate, run `hax.sh extract` and commit what changes under `crates/<crate>/proofs`; CI fails otherwise. Most changes regenerate cleanly. The ones that need attention:

- **A patch no longer applies.** `hax.sh extract` names it. Refresh it: apply the patches before it (`git apply`), apply it with `git apply --reject` or redo its rewrite by hand on the new code, then write it back with `git diff crates/<crate>/src > <patch>` and revert the source (`git checkout crates/<crate>/src`).
- **Aeneas rejects new code.** Its errors are in `lean/aeneas-error.log`. Rewrite the construct in a patch (below), or add the item to the scenario's `opaque` list with the reason.
- **The opaque items change.** Nothing to do: hax regenerates `Extraction/*External_Template.lean`, and `hax.sh extract` adds the new declarations to `Assumptions/` and drops the stale ones, keeping those already there as they are.
- **A missing standard-library model.** Lean reports an unknown `core.*` or `alloc.*` constant: model it in `Assumptions/Std.lean`, as a definition where the Rust is short, as an `opaque` otherwise.

## Patches

A patch in `pre/` rewrites Rust the toolchain cannot translate into Rust it can, without changing what it computes: an iterator adapter whose closure takes a reference (`filter`, `copied`) becomes a fold or a loop, a mutable iterator becomes an indexed loop, a function-pointer field becomes a method. They are applied in name order for the length of `hax.sh extract` and reverted after, so the committed source never carries them. Generated Lean is never edited by hand: what cannot be fixed in the Rust or in `Assumptions/` goes in a `post/` patch, applied to the output of every extraction, which is preferred only over leaving the item opaque.

Each patch is held to two checks, in CI:

- the patched crate is clippy-clean, and
- the tests that pin the crate's behaviour pass on the patched source: `hax.sh patched cargo test --release -p verifier` runs the verifier's own tests, and `hax.sh patched cargo test --release -p leanvm_core --test verifiers` the suite that checks it against real proofs, through both encodings and every rate.

`hax.sh patched <command>` runs any command on the patched source, which is also how to inspect it.

## What the extraction trusts

`report.sh` counts, per extraction, the definitions extracted, the Rust items left opaque, the standard-library models, the bodies Aeneas could not translate (`sorry`), and the patches; CI prints it on every run. Three things stand between the Lean and the Rust that runs:

- **The toolchain.** Charon, Aeneas, and the hax Lean library's models of `core` and `alloc` are trusted to translate faithfully.
- **The assumptions.** Opaque items are axioms with no body; the standard-library models in `Std.lean` are as good as their definitions.
- **The patches.** The Lean describes the patched Rust; the tests above are the evidence that it computes what the committed Rust does. Source spans in the generated files point into the patched source.
