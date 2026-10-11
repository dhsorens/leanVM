# Zero-knowledge hash preimage and Merkle membership

`flock::membership` proves, in zero knowledge, one fixed statement, shaped for a verifier that pays for every scalar it reads and has a precompile answering plain multilinear evaluation claims.

## Statement

Public: `y` and `root`, 32 bytes each. The prover knows `x` (32 bytes), 32 siblings and 32 direction bits such that:

- `blake2s(x ‖ 0x11…11) = y`,
- the leaf `blake2s(x ‖ 0x22…22)` hashes up to `root` through 32 levels of `blake2s(left ‖ right)`.

Every hash input is 64 bytes, so the statement is 34 BLAKE2s compressions.

## Circuit

An R1CS `(Az) ∘ (Bz) = Cz` over `K = GF(2^64)`, with `C` the identity but for the wires of the zerocheck's mask, where it is zero. A wire of the computation holds one bit: free inputs carry the row `z = z·z`, and every wire computed from them is then a bit. The only other wires are free field elements that no row of the computation reads, there for zero knowledge (below): the hiding wires, read by their own product rows only, and the mask's, which are in no row at all.

The `2^22` wires are 64 compressions (34 real, the rest padding) of 32 blocks of 2048 wires. A compression is one `S` block (the 64-byte message: a left/right swap of the previous hash with a sibling, and the constant initial state), twenty `H` blocks (half a BLAKE2s round each: four G functions on the columns of the state) and one `F` block (the final XOR, and `x`).

The matrices are never written out. They are:

- **three dense local matrices**, one per block type, `2048 × 2048` bits each. They are the only circuit data behind a commitment: one polynomial `I` of `2^25` words, holding `A_T` and `A_T + B_T` for each type `T`.
- **wiring between blocks**, which the verifier evaluates itself: a state word goes to the same or a rotated position of the next block (the diagonal step is the column step on a rotated state), a message word follows the BLAKE2s schedule, and a hash goes to the next compression's message.

## Protocol

The prover commits `P = (z, m₀, m₁, m₂)`: the witness and three uniformly random tables of its size. The transcript is seeded with the circuit's commitment, `y` and `root`, and absorbs the commitment to `P` before any challenge. `ρ`, `q` are the two sumcheck points, 22 coordinates each.

1. **Zerocheck.** `Σ_x eq(r,x)·[(Az)(x)·(Bz)(x) + (Cz)(x) + λ·g(x)] = λ·S` for random `r`, `λ`, where `g(x) = c + Σ_i (g_i·x_i + h_i·x_i²)` is a mask whose coefficients are wires of `z`. The prover sends `S` first, two scalars a round, then `â = (Az)~(ρ)`, `b̂ = (Bz)~(ρ)` and `γ = g(ρ)`. The verifier derives `ĉ = (Cz)~(ρ)` from the final claim.
2. **Lincheck.** One linear claim on `z` gathers `â + α·b̂ + α²·ĉ`, the constant wire of every used block (`α³`; an unused block is all zeros, by its rows), the public values, and `γ` (`α⁴`): `Σ_y comb(y)·z(y) = v`, with `comb` the matrices' column weights at `ρ` plus the weights of those wires. The prover sends `S_k = Σ_y comb(y)·m_k(y)`, the verifier samples `μ`, and the sumcheck runs on the masked table `t = z + μ·m₀ + μ²·m₁ + μ³·m₂` against `v + μ·S₀ + μ²·S₁ + μ³·S₂`. Two scalars a round, then the three local-matrix evaluations `V_T = I~(ρ_local, q_local, T, α)`.
3. **Two claims.** The verifier evaluates `comb~(q)` from the `V_T` and the wiring. The sumcheck ends on `comb~(q)·t~(q)`, and `t~(q)` is one evaluation of `P`: its two top coordinates at `μ/(1 + μ)` and `μ²/(1 + μ²)`, scaled by `(1 + μ)(1 + μ²)`. The second claim is `I~(ρ_local, q_local, t', α) = Σ_T eq(t',T)·V_T` at a random `t'`.

The proof is `2·22 + 4` scalars for the zerocheck and `2·22 + 6` for the lincheck, plus the commitment root. `P` is `2^24` words, committed as `2^26`, and `I` is `2^25` words.

## Zero knowledge

The proof is honest-verifier zero knowledge, with statistical error below `2^-118` and the hash modelled as a random oracle where it hides unopened Merkle leaves: [membership-zk.md](membership-zk.md) states and proves it. In outline:

- **Zerocheck rounds.** Round `i` is the first to meet `g_i` and `h_i`, which shift its two scalars independently, so the rounds are uniform. The mask's wires are outside the constraint system, so the rounds' witness part does not depend on them. A multilinear mask times a public factor does not work: its round polynomial has a root the verifier knows, where the message is the witness's own.
- **Lincheck rounds.** `μ, μ², μ³` are a basis of `GF(2^192)` over `K` unless `μ` is in `K`, so `t` is a uniformly random table whatever `z` is, and every message is a function of `t` and the claim.
- **Evaluations.** `z~(q)` is never sent: only `t~(q)` reaches the commitment scheme. `â`, `b̂`, `ĉ` are made uniform by six product rows `w = u·v` per compression, on random `u`, `v` in `K`.
- **Commitment.** `P` is committed with two more variables of random values, placed for the commitment's structure. A Merkle leaf holds every lane (a block of the table along its top six variables) at one position: `P` takes the high half of each lane, and the random low half, a random polynomial of half the degree, makes the lane's values at any opened positions uniform. Half the lanes are random throughout, which makes the opening's first folded table uniform; everything the opening shows later is a function of that table.

The wiring terms and everything about `I` are public, and need no hiding.

The prover's randomness (the mask, the hiding wires, the three tables and the padding) must be uniform. The benchmark draws it from the test generator.
