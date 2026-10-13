# Security of `flock::quotient`

A Lean 4 development over [ArkLib](https://github.com/Verified-zkEVM/ArkLib) for the proof system of `crates/flock/src/quotient.rs`, described in `doc/quotient/main.tex`.

**What is proved.**

- `QuotientSecurity.knowledgeSoundness` (`RandomOracle.lean`): knowledge soundness of the non-interactive proof in the random-oracle model. The transcript's hash is a random oracle on what it has absorbed, commitments are ideal, and the adversary makes at most `Q` adaptive queries before it outputs a statement and a proof. The probability that the verifier accepts while the cells read off the proof's first message do not satisfy the relation is at most `(Q + 3)` times the largest round error. The extractor is that reading: it is straight-line and needs neither the oracle nor a rewind.
- `QuotientSecurity.knowledgeSoundness_bits`: at the protocol's sizes (`q = 2^192`, `N = 2^22` cells, eight words, identities of degree at most `2^27`) that is `(Q + 3) / 2^128`.
- `QuotientSecurity.verifier_rbrKnowledgeSoundness` (`RoundByRound.lean`): the interactive protocol is round-by-round knowledge sound in ArkLib's definition (`Verifier.rbrKnowledgeSoundness`, through its worst-case form), with errors `(2 N^2 + 4 N + words) / q`, `d / q` and `3 / q` for its three challenges, each at most `2^-128` at those sizes (`rbrError_le`).

The relation is `Params.Sat`: the cells satisfy every gate, every copy constraint and the public words. All four theorems depend only on `propext`, `Classical.choice` and `Quot.sound`, which the root module pins.

**The model.** The protocol is stated on polynomials (`Protocol.lean`): a table is read as the polynomials it holds, a claim on a table as an evaluation of them, and the claim at the fixed point as the sum of the low part of the sum's polynomial over the cells. A commitment is ideal: the prover's message is the polynomials, of bounded degree, and the verifier's four claims are checked against them (`Params.Accepts`). The fields are abstract: any finite field of characteristic 2 with an element `theta`, `theta^2 + theta + 1 = 0`, any set of rows whose cells are distinct points, any polynomials vanishing on the cells and on the rows, any permutation carried by a polynomial, any public weights that sum to the public words.

**What is not proved here.**

- The encoding: that a multilinear claim on a coefficient table at the point built from `t` is the polynomial's value at `t` up to the scale the verifier applies, and that the claim at the fixed point is that sum. These are the two identities of the note's Section 2.
- That the circuit of `quotient::circuit` satisfies `Params`' hypotheses, and that `Params.Sat` for it means the BLAKE2s statement.
- The hash as a random oracle is an assumption, and so is the ideal commitment: a real commitment adds its own binding error and its own extractor. ArkLib's general theorem from round-by-round soundness to the Fiat-Shamir transform is not proved there, so the random-oracle theorem here is proved directly, from the three round bounds and VCVio's bound on fresh bad queries (`prEvent_randomOracle_le_of_bad_queries`).
- Zero knowledge.

**Files.** `LogDerivative.lean`, `Counting.lean`: the copy argument and the counts of the first challenge. `Protocol.lean`: the protocol. `Cells.lean`: what a consistent second message forces on the cells. `RoundOne.lean`, `RoundTwo.lean`, `RoundThree.lean`: the three challenges. `Degrees.lean`: the degree of the identities. `Spec.lean`: the protocol, extractor and state function in ArkLib's types. `RoundByRound.lean`: round-by-round knowledge soundness. `Bits.lean`: 128 bits. `RandomOracle.lean`: the non-interactive proof in the random-oracle model.

Build with `lake exe cache get` once, then `lake build`.
