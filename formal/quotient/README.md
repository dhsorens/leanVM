# Security of `flock::quotient`

A Lean 4 development over [ArkLib](https://github.com/Verified-zkEVM/ArkLib) for the proof system of `crates/flock/src/quotient.rs`, described in `doc/quotient/main.tex`.

**What is proved.**

- `QuotientSecurity.knowledgeSoundness` (`RandomOracle.lean`): knowledge soundness of the non-interactive proof in the random-oracle model. The transcript's hash is a random oracle on what it has absorbed, commitments are ideal, and the adversary makes at most `Q` adaptive queries before it outputs a statement and a proof. The probability that the verifier accepts while the cells read off the proof's first message do not satisfy the relation is at most `(Q + 3)` times the largest round error. The extractor is that reading: it is straight-line and needs neither the oracle nor a rewind.
- `QuotientSecurity.knowledgeSoundness_bits`: at the protocol's sizes (`q = 2^192`, `N = 2^22` cells, eight words, identities of degree at most `2^27`) that is `(Q + 3) / 2^128`.
- `QuotientSecurity.verifier_rbrKnowledgeSoundness` (`RoundByRound.lean`): the interactive protocol is round-by-round knowledge sound in ArkLib's definition (`Verifier.rbrKnowledgeSoundness`, through its worst-case form), with errors `(2 N^2 + 4 N + words) / q`, `d / q` and `3 / q` for its three challenges, each at most `2^-128` at those sizes (`rbrError_le`).

- `QuotientSecurity.realValues_uniform`, `QuotientSecurity.baseValues_uniform` (`ZeroKnowledge.lean`): honest-verifier zero knowledge of what the prover sends. The four values are those of committed polynomials over `K = GF(2^64)`, each the witness's plus the rows' vanishing polynomial times a mask of three uniform coefficients, at a row `r` of the cubic extension `E`. If `r` is outside `K` they are exactly uniform in `E^4`, and if `r` is in `K` exactly uniform in `K^4`, whatever the witness, as long as the vanishing polynomial is not zero at `r`. So a simulator that knows the challenge samples them, and the only challenges that leak are the `2^22` cells, of `2^192`. The fifth value sent is the wiring's, which is public, and the four claims are functions of these.

The relation is `Params.Sat`: the cells satisfy every gate, every copy constraint and the public words. All of these depend only on `propext`, `Classical.choice` and `Quot.sound`, which the root module pins.

**The model.** The protocol is stated on polynomials (`Protocol.lean`): a table is read as the polynomials it holds, a claim on a table as an evaluation of them, and the claim at the fixed point as the sum of the low part of the sum's polynomial over the cells. A commitment is ideal: the prover's message is the polynomials, of bounded degree, and the verifier's four claims are checked against them (`Params.Accepts`). The fields are abstract: any finite field of characteristic 2 with an element `theta`, `theta^2 + theta + 1 = 0`, any set of rows whose cells are distinct points, any polynomials vanishing on the cells and on the rows, any permutation carried by a polynomial, any public weights that sum to the public words.

**What is not proved here.**

- Half of the encoding. `Encoding.lean` proves that a multilinear claim on a coefficient table at the point `u_k = w_k / (1 + w_k)` is the polynomial's value divided by the product of the `1 + w_k`, and that the claim at the point of all ones is the last entry. Not proved: that the digits `w_k` of the note's basis make these the polynomials of `Protocol.lean` (the novel basis of a Cantor basis), and that the last entry of a table is the sum of its polynomial over the cells.
- That the circuit of `quotient::circuit` satisfies `Params`' hypotheses, and that `Params.Sat` for it means the BLAKE2s statement.
- The hash as a random oracle is an assumption, and so is the ideal commitment: a real commitment adds its own binding error and its own extractor. ArkLib's general theorem from round-by-round soundness to the Fiat-Shamir transform is not proved there, so the random-oracle theorem here is proved directly, from the three round bounds and VCVio's bound on fresh bad queries (`prEvent_randomOracle_le_of_bad_queries`).
- Zero knowledge beyond the honest verifier and the reduction: a malicious verifier, the non-interactive proof's simulator (which programs the oracle), and the commitments and openings themselves, which must hide the tables; the quotient table's polynomials are functions of the witness, and nothing here masks them.

**Files.** `LogDerivative.lean`, `Counting.lean`: the copy argument and the counts of the first challenge. `Protocol.lean`: the protocol. `Cells.lean`: what a consistent second message forces on the cells. `RoundOne.lean`, `RoundTwo.lean`, `RoundThree.lean`: the three challenges. `Degrees.lean`: the degree of the identities. `Spec.lean`: the protocol, extractor and state function in ArkLib's types. `RoundByRound.lean`: round-by-round knowledge soundness. `Bits.lean`: 128 bits. `RandomOracle.lean`: the non-interactive proof in the random-oracle model. `ZeroKnowledge.lean`: the masks. `Encoding.lean`: a claim on a table as an evaluation.

Build with `lake exe cache get` once, then `lake build`.
