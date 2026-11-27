# Changelog

## [0.20.0](https://github.com/dhsorens/leanVM/compare/bindings-v0.19.1...bindings-v0.20.0) (2026-11-27)


### ⚠ BREAKING CHANGES

* `lean_xmss::MAX_CACHED_BOTTOM_TREES` (and its `lean_vm::lean_xmss` re-export) is renamed `DEFAULT_BOTTOM_TREE_CACHE_SIZE`.
* the bindings' Sidecar API is replaced by in-process aggregate/from_bytes and setup(threads); the leanvm-sidecar binary and lean_vm's `sidecar` feature are removed.
* guest and compiler optimizations for the recursion node, with the formal port ([#847](https://github.com/dhsorens/leanVM/issues/847))
* **formal:** the guest is complete on every child the verifier accepts ([#844](https://github.com/dhsorens/leanVM/issues/844))
* the guest's prover is complete ([#755](https://github.com/dhsorens/leanVM/issues/755))
* leanXMSS keys store 2^8 nodes per tree and cache 4 bottom trees (at most 20 KiB of cache per key)
* aggregate(), setup() and Aggregate.from_bytes are replaced by Sidecar.aggregate and Sidecar.verify on a running leanvm-sidecar (Unix only); the C ABI's aggregate calls take a sidecar handle.
* the Go module is leanvm.org/go, the Nim package is bindings/nim at tag bindings-vX.Y.Z (`?subdir=bindings/nim`), and an aggregate from 0.11.x and one from 0.12.0 reject each other.

### Features

* bindings prove in-process with jemalloc and runtime CPU tiers; remove the sidecar ([#848](https://github.com/dhsorens/leanVM/issues/848)) ([be190e9](https://github.com/dhsorens/leanVM/commit/be190e90a2797dd2a0778ff483554e6446536c49))
* bindings: aggregate/verify through a leanVM sidecar instead of in-process ([#804](https://github.com/dhsorens/leanVM/issues/804)) ([dbd30ec](https://github.com/dhsorens/leanVM/commit/dbd30ec2c6f2475b4e996994f80b1ee5404ea1c2))
* **bindings:** .NET bindings, packaged for NuGet as Ethereum.LeanPq ([#854](https://github.com/dhsorens/leanVM/issues/854)) ([6337032](https://github.com/dhsorens/leanVM/commit/63370326843afc1246e00f9a70b7527cff205b01))
* **formal:** extract every crate again ([836c7ce](https://github.com/dhsorens/leanVM/commit/836c7ce50617845841b62cbb8f61451a01f94897))
* **formal:** extract keccak256's sponge step, digest and permutation with their bodies ([316eca6](https://github.com/dhsorens/leanVM/commit/316eca65f1b4a890cd452fe9863c81e7784aac42))
* **formal:** extract leanSPHINCS's verify with its body ([6ec9173](https://github.com/dhsorens/leanVM/commit/6ec9173d48fa39d62d175884fddbd61942636875))
* **formal:** extract leanXMSS's verify with its body ([f0f5884](https://github.com/dhsorens/leanVM/commit/f0f5884b69cbc44307e1fa7920583d1e3148d99d))
* **formal:** extract the verifier and signature crates to Lean with hax ([fbc390f](https://github.com/dhsorens/leanVM/commit/fbc390f8fd6473a088cd405784395cc5c153bf44))
* **formal:** the guest is complete on every child the verifier accepts ([#844](https://github.com/dhsorens/leanVM/issues/844)) ([a176276](https://github.com/dhsorens/leanVM/commit/a176276568ee9bf6851c2185da1aea0734bcba71))
* guest and compiler optimizations for the recursion node, with the formal port ([#847](https://github.com/dhsorens/leanVM/issues/847)) ([3841ca2](https://github.com/dhsorens/leanVM/commit/3841ca2307ab46eccfd7c68439ba68bb42d57c35))
* **lean_xmss, lean_sphincs, keccak256:** build without std ([#843](https://github.com/dhsorens/leanVM/issues/843)) ([7c53d26](https://github.com/dhsorens/leanVM/commit/7c53d265e551f8fe93cf777535d7ef1a8e329b3f))
* leanXMSS keys cache 8 bottom trees by default, tunable per key ([3d84ffc](https://github.com/dhsorens/leanVM/commit/3d84ffc3c866d66f4c632848f8fc6f30a3350f76))
* leanXMSS keys store 2^10 nodes per tree, and load from their tree cache ([#802](https://github.com/dhsorens/leanVM/issues/802)) ([5b43139](https://github.com/dhsorens/leanVM/commit/5b43139d50272f996ca884669b1d51555af1f35d))
* leanXMSS keys store 2^8 nodes per tree and cache 4 bottom trees (at most 20 KiB of cache per key) ([3c48956](https://github.com/dhsorens/leanVM/commit/3c48956771ac909669b7ee54110170dbb6f21339))
* move the bindings into leanVM ([#789](https://github.com/dhsorens/leanVM/issues/789)) ([39acb3f](https://github.com/dhsorens/leanVM/commit/39acb3fe0c19586767075733496cb5ee6d7ce3c1))
* PROTOCOL_VERSION ([3f51bd5](https://github.com/dhsorens/leanVM/commit/3f51bd5cd4ace29196705369cf2934fedc3af922))
* setup picks the experimental prover's CPU tier ([c0fc37f](https://github.com/dhsorens/leanVM/commit/c0fc37f24d53bf347e2642d5f6ceba687e70ecf3))
* the guest's prover is complete ([#755](https://github.com/dhsorens/leanVM/issues/755)) ([f1e43da](https://github.com/dhsorens/leanVM/commit/f1e43dac43e98e1eb6fb873634fccae5ca13603a))
* VRF tree, with pruning + with a cached middle layer ([#805](https://github.com/dhsorens/leanVM/issues/805)) ([c38f2ba](https://github.com/dhsorens/leanVM/commit/c38f2bac8ec30f1ab1d6e5d55908be2377abdc77))


### Bug Fixes

* 15 ([f83b6f9](https://github.com/dhsorens/leanVM/commit/f83b6f93d981dfe44e7d6cd33e521ec472710a27))
* 16 ([eff783d](https://github.com/dhsorens/leanVM/commit/eff783d43f93d9187c84dbcca8bcd701bfd520d4))
* 646 ([a39758d](https://github.com/dhsorens/leanVM/commit/a39758de10f35c7b34023d061cc05dfc0b36d43a))
* 647 ([05931b7](https://github.com/dhsorens/leanVM/commit/05931b78c2238e7b86e758cf5be4f6f9bc393166))
* a sidecar at its 16 connections closes another rather than leave it waiting ([5e6a518](https://github.com/dhsorens/leanVM/commit/5e6a5189ffaf0fc354c186079a7276f8eaa06dd9))
* add leanvm-sidecar --version ([8895fd1](https://github.com/dhsorens/leanVM/commit/8895fd13d33acd90192f5d3ccc2f11f2332ce72e))
* experimental mle_eval_par returns zero on an empty table below three variables ([b37b369](https://github.com/dhsorens/leanVM/commit/b37b369ce255ef1b3c0fdad4e815a3fcbda05244))
* **experimental_pcs:** combiner_within accepts only once the left side fits ([73c2cc0](https://github.com/dhsorens/leanVM/commit/73c2cc094c0be4a1c5af6ec613e8021c9e16da87))
* **experimental:** type unwritten buffers as MaybeUninit ([20a75c1](https://github.com/dhsorens/leanVM/commit/20a75c102288b6016b5ff8057f8c51c80a222f77))
* **lean_vm_core:** bounds-check hint addresses ([a24121a](https://github.com/dhsorens/leanVM/commit/a24121a6e41e8c3622ce05c56d536a662e3bbee0))
* **lean_vm_core:** KECCAK addresses only the cells it accesses ([cfb0460](https://github.com/dhsorens/leanVM/commit/cfb0460fc308f282fd71aaaaf1b1ead138fedf91))
* pass a log-size as placeholder_map's dummy taus ([51b2fcc](https://github.com/dhsorens/leanVM/commit/51b2fccaf77f1909484ea1559fcdb2044a4505de))
* **sidecar:** reject &gt; DA_MAX_ROWS on decode and avoid stderr panics ([#833](https://github.com/dhsorens/leanVM/issues/833)) ([6b7107a](https://github.com/dhsorens/leanVM/commit/6b7107a00592776f750b0714077556afb0e98d26))
* staged native archives carry no LLVM bitcode, which Go 1.27 refuses ([41ca15b](https://github.com/dhsorens/leanVM/commit/41ca15b4fd3c5830fca434ec2f78aa49a709d80d))
* **verifier:** use checked_add for stack_log in verify_keccak_batch ([#834](https://github.com/dhsorens/leanVM/issues/834)) ([fdb3179](https://github.com/dhsorens/leanVM/commit/fdb317982286422300def1519931e090a5a3d32b))
* **zkdsl_compiler:** `x ** 0` evaluates `x` ([82f1c78](https://github.com/dhsorens/leanVM/commit/82f1c782552e5bdb1e6e1eca2e204e2afc1a1e6a))
* **zkdsl_compiler:** hint_windows_exponent's bounds do not wrap u32 ([a38d0f1](https://github.com/dhsorens/leanVM/commit/a38d0f16e7816a780fd61967bcc74949f7606ea4))
* **zkdsl_compiler:** keccak cap= rejects pad_tail= ([5090e6f](https://github.com/dhsorens/leanVM/commit/5090e6fd25ce6f412a2a6fdb7df4913a82c7b521))
* **zkdsl_compiler:** loop captures, slice spans, reserved names and integer heap indexes ([b18e7d3](https://github.com/dhsorens/leanVM/commit/b18e7d3c36f73c595930c14809e336673af59ffa))


### Performance Improvements

* **aggregation:** skip the top leanXMSS layer's walk in its hints ([12d9a7d](https://github.com/dhsorens/leanVM/commit/12d9a7d2da1de41227ca37919705c21522f8849f))
* faster XMSS key generation and signing ([#859](https://github.com/dhsorens/leanVM/issues/859)) ([fef5de5](https://github.com/dhsorens/leanVM/commit/fef5de5088e6abbe17db7f2f9be663e85d4e4c8c))
* **keccak:** normalize equality-factored layer sumchecks ([#767](https://github.com/dhsorens/leanVM/issues/767)) ([41e89f2](https://github.com/dhsorens/leanVM/commit/41e89f2e50fd452529dda9a58778e87427e0d58e))
* **lean_vrf:** hash whole subtrees in batches ([fdd593c](https://github.com/dhsorens/leanVM/commit/fdd593cb6c207b21cb824db5bd19311e67e0a8aa))
* **lean_xmss:** hash a signature's chain steps in batches ([c5a6c88](https://github.com/dhsorens/leanVM/commit/c5a6c88f7c494694815cb06e8b6a63b99e4505cc))

## [0.19.1](https://github.com/leanEthereum/leanVM/compare/bindings-v0.19.0...bindings-v0.19.1) (2026-11-27)


### Performance Improvements

* **lean_vrf:** hash whole subtrees in batches ([fdd593c](https://github.com/leanEthereum/leanVM/commit/fdd593cb6c207b21cb824db5bd19311e67e0a8aa))

## [0.19.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.18.0...bindings-v0.19.0) (2026-11-26)


### ⚠ BREAKING CHANGES

* `lean_xmss::MAX_CACHED_BOTTOM_TREES` (and its `lean_vm::lean_xmss` re-export) is renamed `DEFAULT_BOTTOM_TREE_CACHE_SIZE`.

### Features

* leanXMSS keys cache 8 bottom trees by default, tunable per key ([3d84ffc](https://github.com/leanEthereum/leanVM/commit/3d84ffc3c866d66f4c632848f8fc6f30a3350f76))
* PROTOCOL_VERSION ([3f51bd5](https://github.com/leanEthereum/leanVM/commit/3f51bd5cd4ace29196705369cf2934fedc3af922))


### Bug Fixes

* **experimental:** type unwritten buffers as MaybeUninit ([20a75c1](https://github.com/leanEthereum/leanVM/commit/20a75c102288b6016b5ff8057f8c51c80a222f77))


### Performance Improvements

* **aggregation:** skip the top leanXMSS layer's walk in its hints ([12d9a7d](https://github.com/leanEthereum/leanVM/commit/12d9a7d2da1de41227ca37919705c21522f8849f))
* **lean_xmss:** hash a signature's chain steps in batches ([c5a6c88](https://github.com/leanEthereum/leanVM/commit/c5a6c88f7c494694815cb06e8b6a63b99e4505cc))

## [0.18.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.17.0...bindings-v0.18.0) (2026-11-24)


### Features

* setup picks the experimental prover's CPU tier ([c0fc37f](https://github.com/leanEthereum/leanVM/commit/c0fc37f24d53bf347e2642d5f6ceba687e70ecf3))


### Performance Improvements

* faster XMSS key generation and signing ([#859](https://github.com/leanEthereum/leanVM/issues/859)) ([fef5de5](https://github.com/leanEthereum/leanVM/commit/fef5de5088e6abbe17db7f2f9be663e85d4e4c8c))

## [0.17.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.16.0...bindings-v0.17.0) (2026-11-24)


### ⚠ BREAKING CHANGES

* the bindings' Sidecar API is replaced by in-process aggregate/from_bytes and setup(threads); the leanvm-sidecar binary and lean_vm's `sidecar` feature are removed.

### Features

* bindings prove in-process with jemalloc and runtime CPU tiers; remove the sidecar ([#848](https://github.com/leanEthereum/leanVM/issues/848)) ([be190e9](https://github.com/leanEthereum/leanVM/commit/be190e90a2797dd2a0778ff483554e6446536c49))
* **bindings:** .NET bindings, packaged for NuGet as Ethereum.LeanPq ([#854](https://github.com/leanEthereum/leanVM/issues/854)) ([6337032](https://github.com/leanEthereum/leanVM/commit/63370326843afc1246e00f9a70b7527cff205b01))

## [0.16.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.15.0...bindings-v0.16.0) (2026-11-20)


### Features

* VRF tree, with pruning + with a cached middle layer ([#805](https://github.com/leanEthereum/leanVM/issues/805)) ([c38f2ba](https://github.com/leanEthereum/leanVM/commit/c38f2bac8ec30f1ab1d6e5d55908be2377abdc77))


### Bug Fixes

* staged native archives carry no LLVM bitcode, which Go 1.27 refuses ([41ca15b](https://github.com/leanEthereum/leanVM/commit/41ca15b4fd3c5830fca434ec2f78aa49a709d80d))

## [0.15.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.14.0...bindings-v0.15.0) (2026-11-20)


### ⚠ BREAKING CHANGES

* leanXMSS keys store 2^8 nodes per tree and cache 4 bottom trees (at most 20 KiB of cache per key)

### Features

* leanXMSS keys store 2^8 nodes per tree and cache 4 bottom trees (at most 20 KiB of cache per key) ([3c48956](https://github.com/leanEthereum/leanVM/commit/3c48956771ac909669b7ee54110170dbb6f21339))

## [0.14.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.13.1...bindings-v0.14.0) (2026-11-20)


### Features

* leanXMSS keys store 2^10 nodes per tree, and load from their tree cache ([#802](https://github.com/leanEthereum/leanVM/issues/802)) ([5b43139](https://github.com/leanEthereum/leanVM/commit/5b43139d50272f996ca884669b1d51555af1f35d))

## [0.13.1](https://github.com/leanEthereum/leanVM/compare/bindings-v0.13.0...bindings-v0.13.1) (2026-11-20)


### Bug Fixes

* add leanvm-sidecar --version ([8895fd1](https://github.com/leanEthereum/leanVM/commit/8895fd13d33acd90192f5d3ccc2f11f2332ce72e))

## [0.13.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.12.0...bindings-v0.13.0) (2026-11-19)


### ⚠ BREAKING CHANGES

* aggregate(), setup() and Aggregate.from_bytes are replaced by Sidecar.aggregate and Sidecar.verify on a running leanvm-sidecar (Unix only); the C ABI's aggregate calls take a sidecar handle.

### Features

* bindings: aggregate/verify through a leanVM sidecar instead of in-process ([#804](https://github.com/leanEthereum/leanVM/issues/804)) ([dbd30ec](https://github.com/leanEthereum/leanVM/commit/dbd30ec2c6f2475b4e996994f80b1ee5404ea1c2))

## [0.12.0](https://github.com/leanEthereum/leanVM/compare/bindings-v0.11.1...bindings-v0.12.0) (2026-11-19)


### ⚠ BREAKING CHANGES

* the Go module is leanvm.org/go, the Nim package is bindings/nim at tag bindings-vX.Y.Z (`?subdir=bindings/nim`), and an aggregate from 0.11.x and one from 0.12.0 reject each other.

### Features

* move the bindings into leanVM ([#789](https://github.com/leanEthereum/leanVM/issues/789)) ([39acb3f](https://github.com/leanEthereum/leanVM/commit/39acb3fe0c19586767075733496cb5ee6d7ce3c1))

## [0.11.1](https://github.com/ethereum/lean-pq-bindings/compare/v0.11.0...v0.11.1) (2026-11-19)


### Bug Fixes

* **go:** read native error messages on the failing call's OS thread ([#52](https://github.com/ethereum/lean-pq-bindings/issues/52)) ([d7a77e8](https://github.com/ethereum/lean-pq-bindings/commit/d7a77e8ad042d97b21eca8722e573dc22aaffe53))


### Performance Improvements

* aggregate with leanVM's experimental prover ([#54](https://github.com/ethereum/lean-pq-bindings/issues/54)) ([142a54a](https://github.com/ethereum/lean-pq-bindings/commit/142a54a627c94d1cc0bce2942bcba0234aaa34a1))

## [0.11.0](https://github.com/ethereum/lean-pq-bindings/compare/v0.10.1...v0.11.0) (2026-11-18)


### ⚠ BREAKING CHANGES

* update leanVM to 28368657 with proof-only aggregates ([#53](https://github.com/ethereum/lean-pq-bindings/issues/53))

### Features

* **nim:** add Nim bindings with Nimble packaging ([#50](https://github.com/ethereum/lean-pq-bindings/issues/50)) ([1663509](https://github.com/ethereum/lean-pq-bindings/commit/1663509ec6b503bf9c267da1e2d313ee77c6c12a))
* update leanVM to 28368657 with proof-only aggregates ([#53](https://github.com/ethereum/lean-pq-bindings/issues/53)) ([9b6dcd3](https://github.com/ethereum/lean-pq-bindings/commit/9b6dcd3c1465f93597cba514f78ce63e9287a59d))

## [0.10.1](https://github.com/ethereum/lean-pq-bindings/compare/v0.10.0...v0.10.1) (2026-11-16)


### Bug Fixes

* **zig:** link the Windows synchronization library ([#48](https://github.com/ethereum/lean-pq-bindings/issues/48)) ([a6e3827](https://github.com/ethereum/lean-pq-bindings/commit/a6e382705f8ac41bc8ccbf97131508bb824f1996))

## [0.10.0](https://github.com/ethereum/lean-pq-bindings/compare/v0.9.0...v0.10.0) (2026-11-16)


### ⚠ BREAKING CHANGES

* update leanVM to 5e3ade21 for its FIPS 205 leanSPHINCS layout ([#45](https://github.com/ethereum/lean-pq-bindings/issues/45))

### Features

* update leanVM to 5e3ade21 for its FIPS 205 leanSPHINCS layout ([#45](https://github.com/ethereum/lean-pq-bindings/issues/45)) ([1b8f279](https://github.com/ethereum/lean-pq-bindings/commit/1b8f2792499af2ffb438da6cf7cc8de43263c332))

## [0.9.0](https://github.com/ethereum/lean-pq-bindings/compare/v0.8.0...v0.9.0) (2026-11-04)


### ⚠ BREAKING CHANGES

* update leanVM to ed7d2b9 and its new leanSPHINCS ([#44](https://github.com/ethereum/lean-pq-bindings/issues/44))

### Features

* **rust:** expose the leanXMSS lifetime as xmss::LOG_LIFETIME ([#42](https://github.com/ethereum/lean-pq-bindings/issues/42)) ([0cc7bc6](https://github.com/ethereum/lean-pq-bindings/commit/0cc7bc6c7de965ce166498546b2a549dac65ca1d))
* update leanVM to ed7d2b9 and its new leanSPHINCS ([#44](https://github.com/ethereum/lean-pq-bindings/issues/44)) ([f262172](https://github.com/ethereum/lean-pq-bindings/commit/f262172eb107ebaa102938d958f27e6aad571270))

## [0.8.0](https://github.com/ethereum/lean-pq-bindings/compare/v0.7.0...v0.8.0) (2026-10-28)


### ⚠ BREAKING CHANGES

* **rust:** rebuild the Rust facade with typed errors ([#39](https://github.com/ethereum/lean-pq-bindings/issues/39))

### Features

* **rust:** make leanVM aggregation an optional default feature ([#41](https://github.com/ethereum/lean-pq-bindings/issues/41)) ([39cd44b](https://github.com/ethereum/lean-pq-bindings/commit/39cd44bd9bbe558b946abea257a6b77750cc6620))


### Code Refactoring

* **rust:** rebuild the Rust facade with typed errors ([#39](https://github.com/ethereum/lean-pq-bindings/issues/39)) ([03d576e](https://github.com/ethereum/lean-pq-bindings/commit/03d576ec7b958d03ffc963a5ecb6b86d64a19bf0))

## [0.7.0](https://github.com/ethereum/lean-pq-bindings/compare/v0.6.2...v0.7.0) (2026-10-27)


### Features

* Windows x86-64 for every binding, and a Go module that needs no Rust ([#37](https://github.com/ethereum/lean-pq-bindings/issues/37)) ([5d6313c](https://github.com/ethereum/lean-pq-bindings/commit/5d6313c4e76184ac3f390f6b90e99aab23644d3c))

## [0.6.2](https://github.com/ethereum/lean-pq-bindings/compare/v0.6.1...v0.6.2) (2026-10-27)


### Documentation

* **python:** point to the Node.js, Java, and Zig packages ([b33080e](https://github.com/ethereum/lean-pq-bindings/commit/b33080ea8477e03a77ca764e778a13c908f9e15c))

## [0.6.1](https://github.com/ethereum/lean-pq-bindings/compare/v0.6.0...v0.6.1) (2026-10-26)


### Miscellaneous Chores

* **python:** link the changelog from the PyPI page ([9534b44](https://github.com/ethereum/lean-pq-bindings/commit/9534b447de26e14114a4dc6cb6250adac3a2a634))

## [0.6.0](https://github.com/ethereum/lean-pq-bindings/compare/v0.4.0...v0.6.0) (2026-10-26)


### ⚠ BREAKING CHANGES

* the Claim/slot, Signature, MultiClaimProof, and merge APIs are replaced by leanXMSS/leanSPHINCS secret keys, byte signatures, and Aggregate. The PyPI package is now py-lean-pq.
* replace Python bindings with safe facade ([#10](https://github.com/ethereum/lean-pq-bindings/issues/10))

### Features

* add Java 25 bindings ([#12](https://github.com/ethereum/lean-pq-bindings/issues/12)) ([3690a76](https://github.com/ethereum/lean-pq-bindings/commit/3690a7628c0148f61419c4f3de189880e6f356f7))
* rename to lean-pq and port bindings to upstream leanVM ([c7edcc4](https://github.com/ethereum/lean-pq-bindings/commit/c7edcc46a55d4525c862f6eba89d76c6f4726fcb))
* replace Python bindings with safe facade ([#10](https://github.com/ethereum/lean-pq-bindings/issues/10)) ([4a0f276](https://github.com/ethereum/lean-pq-bindings/commit/4a0f27634d94633a756fac7639a67a4e353df31b))

## [0.4.0](https://github.com/ethereum/py-lean-multisig/compare/v0.3.0...v0.4.0) (2026-05-08)


### Features

* Fix license line formatting in README.md ([#7](https://github.com/ethereum/py-lean-multisig/issues/7)) ([18bbc35](https://github.com/ethereum/py-lean-multisig/commit/18bbc3598a59281a8e966570b01ce935ea9836a3))

## [0.3.0](https://github.com/kevaundray/py-lean-multisig/compare/v0.2.0...v0.3.0) (2026-05-06)


### Features

* use basic binary encoding with signature and public key ([188c183](https://github.com/kevaundray/py-lean-multisig/commit/188c183f45a38c7975fa842f934fd0d26acb68db))

## [0.2.0](https://github.com/kevaundray/py-lean-multisig/compare/v0.0.1...v0.2.0) (2026-05-06)


### Features

* trigger release please ([4896bdf](https://github.com/kevaundray/py-lean-multisig/commit/4896bdf2d5b42b31dcc7197a532676e88dc7c5b5))


### Bug Fixes

* typo ([864ded7](https://github.com/kevaundray/py-lean-multisig/commit/864ded7a7849c753317037619373a4d736a913cb))


### Miscellaneous Chores

* release 0.2.0 ([d0c57d0](https://github.com/kevaundray/py-lean-multisig/commit/d0c57d09c7383d5e252ec3d07b777c54ce903f91))
