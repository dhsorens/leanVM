# Zero-knowledge hash preimage and Merkle membership

`flock::membership` proves, in zero knowledge, one fixed statement, shaped for a verifier that pays for every scalar it reads and has a precompile answering plain multilinear evaluation claims.

## Statement

Public: `y` and `root`, 32 bytes each. The prover knows `x` (32 bytes), 32 siblings and 32 direction bits such that:

- `blake2s(x ‖ 0x11…11) = y`,
- the leaf `blake2s(x ‖ 0x22…22)` hashes up to `root` through 32 levels of `blake2s(left ‖ right)`.

Every hash input is 64 bytes, so the statement is 34 BLAKE2s compressions.

## Circuit

An R1CS `(Az) ∘ (Bz) = z` over `K = GF(2^64)`. A wire holds one bit; free inputs carry the row `z = z·z`, and every other wire is then a bit by construction.

The `2^22` wires are 64 compressions (34 real, the rest padding) of 32 blocks of 2048 wires. A compression is one `S` block (the 64-byte message: a left/right swap of the previous hash with a sibling, and the constant initial state), twenty `H` blocks (half a BLAKE2s round each: four G functions on the columns of the state) and one `F` block (the final XOR, and `x`).

The matrices are never written out. They are:

- **three dense local matrices**, one per block type, `2048 × 2048` bits each. They are the only circuit data behind a commitment: one polynomial `I` of `2^25` words, holding `A_T` and `A_T + B_T` for each type `T`.
- **wiring between blocks**, which the verifier evaluates itself: a state word goes to the same or a rotated position of the next block (the diagonal step is the column step on a rotated state), a message word follows the BLAKE2s schedule, and a hash goes to the next compression's message.

## Protocol

The prover commits `P = (z ‖ m)`, the witness next to a uniformly random mask `m` of the same size. `ρ`, `q` are the two sumcheck points, 22 coordinates each.

1. **Zerocheck.** `Σ_x eq(r,x)·[(Az)(x)·(Bz)(x) + z(x) + λ·eq(τ,x)·m(x)] = λ·S` for random `r`, `τ`, `λ`. The prover sends `S` first, two scalars a round, then `â = (Az)~(ρ)`, `b̂ = (Bz)~(ρ)` and `μ = m~(ρ)`. The verifier derives `ĉ = z~(ρ)` from the final claim.
2. **Lincheck.** One sumcheck over the wires proves `â + α·b̂ + α²·ĉ`, the constant wire, the public values and `μ` together:
   `Σ_y comb(y)·z(y) + α⁴·eq(ρ,y)·m(y) = â + α·b̂ + α²·ĉ + (pins) + α⁴·μ`,
   where `comb(y) = Σ_x eq(ρ,x)·(A + α·B)(x,y) + α²·eq(ρ,y) + (pin weights)`. Two scalars a round, then the three local-matrix evaluations `V_T = I~(ρ_local, q_local, T, α)`.
3. **Two claims.** The verifier evaluates `w₀ = comb~(q)` from the `V_T` and the wiring, and `w₁ = α⁴·eq(ρ,q)`. What is left is `w₀·z~(q) + w₁·m~(q) = claim`, which is the single evaluation `P~(q, t) = claim / (w₀ + w₁)` at `t = w₁ / (w₀ + w₁)`. The second claim is `I~(ρ_local, q_local, t', α) = Σ_T eq(t',T)·V_T` at a random `t'`.

The proof is `2·22 + 4` scalars for the zerocheck and `2·22 + 3` for the lincheck, plus the commitment root. The prover commits `2^25` words (`P` is `2^23`), and the circuit polynomial `I` is `2^25` words.

## Zero knowledge

- **Rounds.** Every round message of both sumchecks is its real value plus a linear function of `m`, which appears nowhere else in the clear.
- **Evaluations.** `z~(q)` and `m~(q)` are never sent: only their combination reaches the commitment scheme. `â`, `b̂`, `ĉ` are hidden by six product rows `w = u·v` per compression, on random `u`, `v` in `K`.
- **Commitment.** `P` is committed with two more variables of random values, so that its one opening reveals only the claimed value.

The lincheck's wiring terms and everything about `I` are public, and need no hiding.

This is the design, not a proof of it: it rests on the values a verifier sees being independent linear functions of `m`, which is not shown here.
