# Security of `flock::quotient`

A Lean 4 development over [ArkLib](https://github.com/Verified-zkEVM/ArkLib) for the proof system of `crates/flock/src/quotient.rs`, described in `doc/quotient/main.tex`.

**What is proved.** `QuotientSecurity.verifier_rbrKnowledgeSoundness`: with ideal commitments, the verifier is round-by-round knowledge sound in ArkLib's definition (`Verifier.rbrKnowledgeSoundness`, reached through its worst-case form), for the relation "the cells satisfy every gate, every copy constraint and the public words" (`Params.Sat`), with an extractor that reads the cells off the first message. The error of the three challenges is `(2 N^2 + 4 N + words) / q`, `d / q` and `3 / q`, for `N` cells, a field of `q` elements and identities of degree `d`. `QuotientSecurity.rbrError_le`: at the protocol's sizes (`q = 2^192`, `N = 2^22`, eight words, `d <= 2^27`) each is at most `2^-128`. Both depend only on `propext`, `Classical.choice` and `Quot.sound`, which the root module pins.

**The model.** The protocol is stated on polynomials (`Protocol.lean`): a table is read as the polynomials it holds, a claim on a table as an evaluation of them, and the claim at the fixed point as the sum of the low part of the sum's polynomial over the cells. A commitment is ideal: the prover's message is the polynomials, of bounded degree, and the verifier's four claims are checked against them (`Params.Accepts`). The fields are abstract: any finite field of characteristic 2 with an element `theta`, `theta^2 + theta + 1 = 0`, any set of rows whose cells are distinct points, any polynomials vanishing on the cells and on the rows, any permutation carried by a polynomial, any public weights that sum to the public words.

**What is not proved here.**

- The encoding: that a multilinear claim on a coefficient table at the point built from `t` is the polynomial's value at `t` up to the scale the verifier applies, and that the claim at the fixed point is that sum. These are the two identities of the note's Section 2.
- That the circuit of `quotient::circuit` satisfies `Params`' hypotheses, and that `Params.Sat` for it means the BLAKE2s statement.
- The Fiat-Shamir step. Round-by-round knowledge soundness is the hypothesis under which a hash-chain transcript is knowledge sound in the random-oracle model, but ArkLib does not yet prove that implication (its `Security/Implications.lean` and `FiatShamir/Basic.lean` state it with `sorry`), so it is not claimed here.
- Zero knowledge.

**Files.** `LogDerivative.lean`, `Counting.lean`: the copy argument and the counts of the first challenge. `Protocol.lean`: the protocol. `Cells.lean`: what a consistent second message forces on the cells. `RoundOne.lean`, `RoundTwo.lean`, `RoundThree.lean`: the three challenges. `Degrees.lean`: the degree of the identities. `Spec.lean`: the protocol, extractor and state function in ArkLib's types. `RoundByRound.lean`: the theorem. `Bits.lean`: 128 bits.

Build with `lake exe cache get` once, then `lake build`.
