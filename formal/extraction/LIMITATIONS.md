# What the extraction leaves out

Every crate in `crates/` is extracted to Lean and typechecks, with no `sorry`. Extracted is not the same as faithful, though: some Rust is only described by a signature, some was rewritten before extraction, and some is out of reach by design. This file says what and why. The authoritative lists are each crate's `hax.toml` (what is opaque or excluded, grouped by reason) and `patches/pre/` (what was rewritten); `report.sh` counts them.

## Coverage by crate

| crate | extracted with bodies | left opaque |
| --- | --- | --- |
| `primitives` | F64 and F192 arithmetic (the portable kernels), Keccak-f and Keccak-256, `g_pow`, `eq_eval`, `mle_eval`, the folds, the portable bit transpose | raw-pointer and uninitialized-memory helpers, the thread-pool entry points, `OnceLock` tables, host-dependent items |
| `parallel` | the topology arithmetic (`recommended_chunk_size`, `Topology`) | the pool itself: workers, atomics, `dyn Fn` jobs, raw pointers, OS calls |
| `fiat_shamir` | the duplex sponge, transcript and proof transport, Merkle pruning | the parallel proof-of-work search |
| `keccak_gkr` | the GKR reduction's sumchecks, power bases, RMFE and opening helpers | the parallel witness generation and its raw-pointer columns |
| `pcs` | the NTT, ring switch and WHIR building blocks that run sequentially | the Merkle tree (atomics, raw pointers), parallel kernels, the WHIR level loop, `f64` security estimates |
| `leanvm_core` | the ISA, hints, table shapes and constraint identities | the executor, the trace and witness builders, `prove`, the flush builders over `leaf::Coord` |
| `lean_compiler` | the AST and IR types (but the expression and statement types), constant folding, scope bookkeeping, the parser's top level | the lowering (its context holds `&mut` borrows) and most of the parser |
| `signatures` | leanXMSS and leanSPHINCS: tweaks and addresses, WOTS+C chains and codewords, the trees, signing, verification and the byte encodings | the secret key's `Mutex` cache, key generation (randomness) |
| `lean_da` | the commitment, its Merkle columns and the membership challenges | the Reed-Solomon encoding (the NTT, behind an unsafe cast) |
| `verifier` | Keccak, the field, the ring switch, most of the transcript, multilinear, Merkle and DA code | the top-level loops (the sumchecks, WHIR, the bus, the Keccak reduction), the tables' column layout, `dyn Fn` claims |
| `rec_aggregation` | the claim and signer-set digests, the statement digest, the deferred claim, `EthereumProof::verify` and its accessors | proving, the guest's zkDSL source, the bincode wire format, sorted-set checks |
| `leanvm` | the public API (re-exports) | |
| `bench` | `Timing`'s bookkeeping | the allocator, timing, tracing, terminal output |

## Out of scope by design

- **Hardware-specific code.** The extraction is of the portable code paths: `hax.sh` switches off the features the crates dispatch on (`aes` and `sha3` on aarch64; x86-64's are off once `target-cpu=native` is overridden), so every `cfg(target_feature)` choice takes its fallback. Items under a bare `cfg(target_arch)` differ between hosts, so they are excluded or opaque in every scenario, and CI checks the extraction regenerates identically on x86-64 Linux. The SIMD kernels the prover actually runs are stage 3 of the roadmap (verification against the compiled code).
- **`unsafe`, raw pointers and uninitialized memory.** Aeneas does not dereference raw pointers; such items are opaque.
- **Concurrency.** The `parallel` pool, atomics, thread-locals and `OnceLock`/`Mutex` caches are opaque; where a parallel loop was simple, a patch made it sequential.
- **The environment.** The global allocator, environment variables, timing, `tracing` spans (patched out where they wrapped extracted code), terminal output.
- **Floating point.** Aeneas has no `f64` arithmetic; the security estimates and benchmark statistics that use it are opaque.
- **Randomness and serialization.** Key generation (`rand`) and the serde and bincode wire formats are excluded or opaque.

## Across crates

Aeneas translates only the crate it runs on, and emits nothing for the items a crate uses from another workspace crate: it expects them declared elsewhere. They are: each extraction imports the extractions of the crates its crate depends on (`wire.py` derives the list from `cargo metadata`), so an item of another crate is that crate's own translation, with its body where it has one, and is opaque only where its own crate leaves it opaque. Nothing across crates is declared by hand. Two seams remain, both bridged by `wire.py` or the scenarios: a constant of another crate is a computation to Aeneas but a value in its own crate's translation, so each use is wrapped in `pure`; and a constant inside a module its crate keeps opaque is not reached by Charon at all (rustc inlines every use), so the scenario names it as a root (`leanvm_core`'s `include`).

## Toolchain gaps

Each gap was met by a patch, a model in `CoreModelsExt`, or an opaque item; most are worth reporting upstream.

**Aeneas**

- An early return or `?` inside a loop, or a `break` out of an outer loop, is not translated. It is the most common reason a verifier function is opaque (its `require(..)?` in a round).
- Borrows it cannot join or end: loops that hold a shared borrow of borrowed data, structs with `&mut` fields (`lean_compiler`'s lowering context), closures that capture `&mut` state, nested loops over two `&mut` tables.
- The `Iterator` trait: the signatures of `filter`, `copied`, `cloned`, `find` and `unzip` crash the translation of the whole trait. Patches replace their uses with folds and loops, and the scenarios exclude them.
- `dyn` trait objects, function pointers, higher-ranked closures and fn items used as closures are not translated, in a body or in a signature.
- A type recursive through `Vec` (`lean_compiler`'s `Expr`, `leanvm_core`'s `leaf::Coord`) becomes a nested inductive Lean's kernel rejects.
- Recursion through a closure forms a mixed declaration group it rejects.
- `&str` constants, `size_of::<T>()` (emitted without its type), and raw-pointer reads.
- A crate's opaque items are declared at the Lean root under `open <crate>`, not in the crate's namespace, so another crate cannot name them and two crates' can clash; `wire.py` moves them into the namespace.
- Another crate's constant is a computation (`RustM T`) where its own crate's translation is a value (`T`); `wire.py` wraps each use in `pure`.
- Generated names that clash or trip Lean's linters: a field and a module with one name, a local named `lift`, two trait fields both named `coremarkerCopyInst` (a `Copy` supertrait and a `Copy` bound on an associated type), and `__N` for the anonymous `const _` items `serde_derive` generates (below).
- Internal errors on a few functions of `verifier`, `pcs` and `leanvm_core`, named in their `hax.toml`; each is still to be reduced to a reportable case.

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

The workspace builds with Lean linter warnings that cannot be fixed without silencing the linter, which is the maintainers' call rather than this pipeline's:

- `nameCheck` on `<module>.__1` and the like in generated `Funs.lean`: Aeneas's names for the `const _: () = { .. }` items `serde_derive` wraps its impls in. No Charon pattern can name them, and the alternatives are a post-extraction patch per file or dropping the derives.
- `dupNamespace` on `alloc.alloc.Global.Insts.CoreAllocAllocatorClone` (in `CoreModelsExt`): the generated code names it, after the Rust path.

## What the patch tests establish

`hax.sh test` runs each patched crate's tests on the patched source, and on its portable paths, the ones the patches rewrite. That shows the patched code computes what the original does on what the tests exercise, which for most crates includes proving and verifying real programs; it is evidence, not proof, of equivalence. A patch that only renames an anonymous `const _: () = assert!(..)` stops that assertion from being evaluated in the patched build (Rust evaluates a named constant only when something uses it); the unpatched build still checks it.
