# What the extraction leaves out

Seventeen crates are extracted to Lean and typecheck, with no `sorry`. Extracted is not the same as faithful, though: some Rust is only described by a signature, some was rewritten before extraction, and some is out of reach by design. This file says what and why. The authoritative lists are each crate's `hax.toml` (what is opaque or excluded, grouped by reason) and `patches/pre/` (what was rewritten); `report.sh` counts them.

## Coverage by crate

The counts are `report.sh`'s as of the sync with upstream of 2026-11-24: definitions extracted with a body, Rust items left opaque, and hand-written patches.

| crate | bodies | opaque | patches | extracted with bodies | left opaque |
| --- | ---: | ---: | ---: | --- | --- |
| `verifier` | 485 | 67 | 8 | Keccak, the field, the ring switch, most of the transcript, multilinear, Merkle and DA code | the top-level loops (the sumchecks, WHIR, the bus, the Keccak reduction), the tables' column layout, most of the wire format, `dyn Fn` claims |
| `keccak256` | 63 | 13 | 0 | Keccak-f and the scalar helpers | `absorb`, `digest_of`, `final_state`, and the multi-way `lanes` module, whole |
| `claims` | 14 | 7 | 0 | the claim types and their accessors | the byte encodings (`encode_claims`, `decode_claims`, `to_bytes`, `from_bytes`) |
| `isa` | 56 | 14 | 0 | the instruction set, the `Program` and its hints | formatting (`pretty`) and the hints' text form (`export_hints`), whole; `g_pow`'s table; `Program::encode` |
| `lean_xmss` | 131 | 25 | 0 | tweaks, WOTS chains and codewords, most of the tree code, signing, the byte layouts | `verify`, `wots_sign`, the tree's `levels` and `subtree`, the `Mutex` cache, key generation from an RNG |
| `lean_sphincs` | 177 | 18 | 0 | tweaks and addresses, WOTS+C chains, the FORS and hypertree helpers | `sign`, `verify`, the codeword and FORS recovery, the byte encodings, key generation |
| `fiat_shamir_prover` | 46 | 6 | 0 | the duplex sponge, transcript and proof transport, Merkle pruning | the proof-of-work search, sampling (`sample`, `sample_vec`), Merkle `open` |
| `stable_parallel` | 1 | 5 | 0 | the chunk-size arithmetic | the pool itself: workers, atomics, `dyn Fn` jobs, raw pointers, OS calls |
| `stable_primitives` | 231 | 35 | 0 | F64 and F128 arithmetic (the portable kernels), `eq_eval`, the folds, the portable bit transpose | raw-pointer and uninitialized-memory helpers, the thread-pool entry points, `OnceLock` tables, `mle_eval`, host-dependent items |
| `stable_pcs` | 150 | 54 | 0 | the NTT, ring switch and WHIR building blocks that run sequentially | the Merkle tree (atomics, raw pointers), parallel kernels, the WHIR level loop and query sampling, `f64` security estimates |
| `stable_keccak_gkr` | 121 | 36 | 0 | the GKR reduction's sumchecks, power bases and opening helpers | the parallel witness generation and its raw-pointer columns, the vector kernels |
| `stable_lean_vm_core` | 46 | 35 | 0 | table shapes outside `tables`, `GPow`'s lookups, the constants other crates read | the `tables` module, whole; the executor, the trace and witness builders, `prove`, the flush builders over `leaf::Coord` |
| `zkdsl_compiler` | 110 | 262 | 0 | the AST and IR types (but the expression and statement types), constant folding, scope bookkeeping, the parser's top level | the lowering (its context holds `&mut` borrows), the optimiser (`opt`), most of the parser |
| `lean_da` | 25 | 13 | 0 | the membership challenges and the commitment's plain helpers | the Reed-Solomon encoding (the NTT, behind an unsafe cast), the Merkle columns and cell proofs |
| `aggregation` | 109 | 66 | 0 | the claim and signer-set types, the deferred claim, accessors | proving, the statement and claim-list digests, the proof's `verify` and byte encodings, the guest's zkDSL source, sorted-set checks |
| `lean_vm` | 3 | 0 | 0 | the public API (re-exports) |  |
| `bench_harness` | 4 | 1 | 0 | `Timing`'s bookkeeping | the allocator, timing, tracing, terminal output |

Not extracted: `experimental_prover/*`, `experimental_dispatch` and `experimental_tiers` (the prover under development and its per-CPU builds), `lean_vrf`, and `allocator`.

## What the sync of November 2026 cost

Upstream reorganised the crates (the verifier became a crate of its own with no dependencies, the provers moved under `stable_prover/` and `experimental_prover/`, the signature schemes split in two) and replaced the cubic extension field by a quadratic one. The extraction was brought back by `repair.py` (see the [README](README.md#syncing-with-upstream)), which keeps what still applies and leaves the rest opaque, so the coverage above is lower than before the sync:

- **The patches outside the verifier are gone.** None of their roughly 130 hunks met the code it was written for. What they rewrote (iterator chains into loops, parallel loops into sequential ones, function-pointer fields into methods) is opaque again where Aeneas or Lean rejects it. The verifier keeps eight patches.
- **Each scenario's `opaque` list has a dated heading**, "Rejected since the sync with upstream of ...", with what Aeneas or Lean reported for each item. Those entries were added mechanically, with no patch or model attempted: they are the first work to take up. Most are missing standard-library models (`as_chunks`, `Iterator::sum`, `IterMut`, `split_first_chunk`, `RangeInclusive`) that one addition to `CoreModelsExt` would clear in several crates at once.
- **The second pass, a day later, cost one crate.** The 28 commits upstream added overnight changed three extractions, and only `zkdsl_compiler` needed entries: 17 opaque and 2 excluded, its new optimiser.
- **Entry points are among them:** `verify` of both signature schemes, `sign` of leanSPHINCS, `aggregation`'s statement digest and its proof's `verify`, and Keccak-256's `absorb` and `digest_of`.
- **Three modules are opaque whole:** `keccak256::lanes` (one body per instruction set), `isa::pretty` and `isa::export_hints` (string patterns, reported with no position), and `stable_lean_vm_core::tables`, where Aeneas stops without naming an item. The last is the one to narrow.

## Out of scope by design

- **Hardware-specific code.** The extraction is of the portable code paths: `hax.sh` switches off the features the crates dispatch on (`aes` and `sha3` on aarch64; x86-64's are off once `target-cpu=native` is overridden), so every `cfg(target_feature)` choice takes its fallback. Items under a bare `cfg(target_arch)` differ between hosts, so they are excluded or opaque in every scenario, and CI checks the extraction regenerates identically on x86-64 Linux. The SIMD kernels the prover actually runs are stage 3 of the roadmap (verification against the compiled code).
- **`unsafe`, raw pointers and uninitialized memory.** Aeneas does not dereference raw pointers; such items are opaque.
- **Concurrency.** The `parallel` pool, atomics, thread-locals and `OnceLock`/`Mutex` caches are opaque; a parallel loop could be made sequential by a patch, though none does today.
- **The environment.** The global allocator, environment variables, timing, `tracing` spans (patched out where they wrapped extracted code), terminal output.
- **Floating point.** Aeneas has no `f64` arithmetic; the security estimates and benchmark statistics that use it are opaque.
- **Randomness and serialization.** Key generation (`rand`) and the serde and bincode wire formats are excluded or opaque.

## Across crates

Aeneas translates only the crate it runs on, and emits nothing for the items a crate uses from another workspace crate: it expects them declared elsewhere. They are: each extraction imports the extractions of the crates its crate depends on (`wire.py` derives the list from `cargo metadata`), so an item of another crate is that crate's own translation, with its body where it has one, and is opaque only where its own crate leaves it opaque. Nothing across crates is declared by hand. Two seams remain, both bridged by `wire.py` or the scenarios: a constant of another crate is a computation to Aeneas but a value in its own crate's translation, so each use is wrapped in `pure`; and a constant inside a module its crate keeps opaque is not reached by Charon at all (rustc inlines every use), so the scenario names it as a root (`stable_lean_vm_core`'s `include`).

## Toolchain gaps

Each gap was met by a patch, a model in `CoreModelsExt`, or an opaque item; most are worth reporting upstream.

**Aeneas**

- An early return or `?` inside a loop, or a `break` out of an outer loop, is not translated. It is the most common reason a verifier function is opaque (its `require(..)?` in a round).
- Borrows it cannot join or end: loops that hold a shared borrow of borrowed data, structs with `&mut` fields (`zkdsl_compiler`'s lowering context), closures that capture `&mut` state, nested loops over two `&mut` tables.
- The `Iterator` trait: the signatures of `filter`, `copied`, `cloned`, `find` and `unzip` crash the translation of the whole trait, and so does an impl of `Sum` or `Product`, which takes an `I: Iterator`. The scenarios exclude them (`repair.py` adds the excludes when it meets the crash), and the verifier's patches replace its uses with folds and loops.
- `dyn` trait objects, function pointers, higher-ranked closures and fn items used as closures are not translated, in a body or in a signature.
- A type recursive through `Vec` (`zkdsl_compiler`'s `Expr`, `stable_lean_vm_core`'s `leaf::Coord`) becomes a nested inductive Lean's kernel rejects.
- Recursion through a closure forms a mixed declaration group it rejects.
- `&str` constants, `size_of::<T>()` (emitted without its type), and raw-pointer reads.
- A crate's opaque items are declared at the Lean root under `open <crate>`, not in the crate's namespace, so another crate cannot name them and two crates' can clash; `wire.py` moves them into the namespace.
- Another crate's constant is a computation (`RustM T`) where its own crate's translation is a value (`T`); `wire.py` wraps each use in `pure`.
- Generated names that clash or trip Lean's linters: a field and a module with one name, a local named `lift`, two trait fields both named `coremarkerCopyInst` (a `Copy` supertrait and a `Copy` bound on an associated type), and `__N` for the anonymous `const _` items `serde_derive` generates (below).
- Internal errors on functions of most crates, named in their `hax.toml`; each is still to be reduced to a reportable case.

**Charon**

- Name patterns cannot name an inherent impl whose type has a lifetime parameter, nor a disambiguated anonymous item (`_#1`), and split on commas.
- `--targets`, which would select the target to extract for, switches to a multi-target mode that translates differently (and crashes Aeneas on the `Iterator` trait), so the host's target is used, with its features switched off.

**The hax Lean library (CoreModels)**

- No `Iterator` instance for `IterMut` (its write-back return does not fit), and most adapters' methods beyond `next` (`fold` on `Zip`, `Rev` and `Filter`, `all`, `flatten`, `flat_map`, `sum`); no `as_chunks`, `concat`, `RangeInclusive` iteration.
- No `HashMap`, `HashSet`, `BTreeMap`, `Mutex`, `OnceLock`, and few `String` and `str` operations.
- Its interfaces disagree with Aeneas's output in places: Aeneas's builtin `Clone` of a tuple is not CoreModels' `Clone`; `Vec`'s `IntoIterator` and `Cow` take different numbers of type arguments; `fmt` gets a `Formatter` write-back `Debug` and `Display` do not have (`wire.py` drops it); `Error` has no `source`.

`CoreModelsExt` holds the models written to fill these gaps, definitions where the Rust is short and `opaque` declarations otherwise.

**hax**

- Its default opaque set names `serde::ser::Serialize`, but the derives resolve to `serde_core`, so it does not apply; the scenarios exclude the serde impls themselves.
- It seeds a new package's `Assumptions/` from the raw template; `wire.py` corrects the seeded declarations on the same run.

## Warnings left in the build

The workspace builds with one Lean linter warning, which cannot be fixed without silencing the linter, the maintainers' call rather than this pipeline's: `dupNamespace` on `alloc.alloc.Global.Insts.CoreAllocAllocatorClone` (in `CoreModelsExt`), a name the generated code uses, after the Rust path.

## What the patch tests establish

`hax.sh test` runs each patched crate's tests on the patched source, and on its portable paths, the ones the patches rewrite. That shows the patched code computes what the original does on what the tests exercise, which for the verifier, the one crate with patches today, includes verifying real proofs; it is evidence, not proof, of equivalence. Naming an anonymous `const _: () = assert!(..)`, as `mechanical.py` does, stops that assertion from being evaluated in the patched build (Rust evaluates a named constant only when something uses it); the unpatched build still checks it.
