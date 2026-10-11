# Zero knowledge of `flock::membership`: statement and proof

This is the proof that the protocol of [membership.md](membership.md) is honest-verifier zero knowledge. It follows the code: `membership::{prove, verify, committed, hidden_point}`, `zerocheck::prove_tables`, `lincheck::product_sumcheck`, and the opening `standalone::opening` over `pcs::whir`.

## 1. Setting

Symbols are local to a section where they must be: `ρ`, `r`, `λ` are the zerocheck's, `q`, `μ` the lincheck's, and section 4 names the opening's own challenges `φ`. `K = GF(2^64)`, `E = GF(2^192)`, `σ(x) = x^(2^64)` the Frobenius of `E` over `K`, `Tr(x) = x + σx + σ²x`. `n = 22`, and a table is indexed by `{0,1}^n`, variable 0 lowest. `eq(p, ·)` is the multilinear Lagrange vector of a point `p`, and `f~` the multilinear extension of a table `f`.

**The prover's randomness**, all uniform and independent:

- `G = (c, g_1, h_1, …, g_n, h_n) ∈ E^(2n+1)`, the zerocheck mask's coefficients, held as `3(2n+1)` wires of `z` (three `K` limbs each). These wires are in no row of `A` or `B`, and `C` is zero on them (`C` is the identity elsewhere).
- `(u_{c,i}, v_{c,i}) ∈ K²` for each compression `c < 64` and `i < 6`, the hiding wires; `w_{c,i} = u_{c,i}·v_{c,i}` is the third wire. Their rows are `u = u·1`, `v = v·1`, `w = u·v`.
- `m_0, m_1, m_2 ∈ K^(2^n)`, the lincheck masks, entering as `t = z + μ m_0 + μ² m_1 + μ³ m_2`.
- `R`, the `3·2^24` words of padding in the committed table.

**The view** of the verifier is the whole proof: the root of the commitment, the sumcheck transcript, and the opening of the witness claim (its scalars, the opened rows, and the Merkle siblings). The opening of the circuit's claim is a function of public data.

**Theorem.** Model BLAKE2s, as it hashes the rows of the first commitment, as a random oracle. There is an efficient simulator that, given the statement and the verifier's challenges, outputs a view such that, for every witness, over uniform challenges, the simulated and the honest views are within statistical distance `2^-118` to a distinguisher that does not query the oracle, and within `2^-118 + H·2^-3800` to one that makes `H` oracle queries. The honest prover aborts with probability below `2^-180`, on a condition on the challenges alone.

The bound is an average: it is the probability of a set of bad challenges, outside which the two views differ by at most `2^-11000` plus the oracle term. The challenges are uniform and independent (an honest verifier).

**The non-interactive proof.** The code derives the challenges from a transcript hash and, in the opening, grinds: at each level it sends the smallest nonce that makes a hash of the transcript start with 17 zero bits. Both are outside the interactive model above. Zero knowledge transfers by the standard argument for public-coin protocols in the programmable random oracle model, which this document does not reprove: the simulator draws the challenges, simulates the view, and programs the transcript hash at the transcript's prefixes; a nonce is a function of the transcript so far and of the oracle, so the simulator draws it from its distribution and programs the oracle accordingly. This uses the transcript hash as a programmable oracle, a second and separate use of the same function from the one in the theorem.

## 2. Algebra used throughout

- **(A1)** For `c ∈ E^m`, the `K`-linear map `K^m → E`, `x ↦ Σ c_j x_j`, is onto if and only if the `c_j` span `E` over `K`. It then maps the uniform distribution to the uniform distribution.
- **(A2)** A `K`-subspace `V` of `E` is all of `E` unless `Tr(s·x) = 0` on `V` for some `s ≠ 0` (the trace form is nondegenerate). For such `s`, `{x : Tr(s x) = 0}` has `K`-dimension 2, and every 2-dimensional `K`-subspace has this form.
- **(A3)** Every `K`-linear map `E → E` is `x ↦ s_0 x + s_1 σx + s_2 σ²x` for unique `s_i ∈ E`.
- **(A4)** `[E : K] = 3` is prime, so for `a ∈ E \ K`: `1, a, a²` is a `K`-basis, `a, σa, σ²a` are distinct, and `θ·span_K{1, a} ⊆ span_K{1, a}` only for `θ ∈ K`.
- **(A5)** `σ` fixes the coefficients of `eq`, so `σ(eq(p, l)) = eq(σp, l)`.
- **(A6)** Monomial span: if `a, b ∈ E \ K` then `{1, a, b, ab}` spans `E` over `K`. (If `b ∈ span{1, a}`, say `b = s + t a` with `t ≠ 0`, then `ab = s a + t a²` is outside it.) Hence the entries of `eq((a, b), ·)`, which span the same space as the monomials, span `E`.

## 3. The sumchecks

Fix the witness (the wires that are neither mask nor hiding wires) and all challenges.

### Lemma 1 (zerocheck rounds)

Let `r_i ≠ 1` for all `i` and `λ ≠ 0` (`λ` is the zerocheck's challenge, `μ` the lincheck's). The `2n + 1` scalars the prover sends up to the end of the rounds (the mask's sum `S`, then two per round) are uniform in `E^(2n+1)` and independent of the witness and of the hiding wires. `G` is a function of them and of the tables `a = Az`, `b = Bz`, `c = Cz`.

*Proof.* The tables `a, b, c` do not involve `G`: its wires are in no row, and `c` is zero on them. Round `i` sends an invertible affine function (given the running claim, and using `r_i ≠ 1`) of `(G_i(1), G_i(∞))`, where `G_i` is the round polynomial with its `eq` factor removed, and

`G_i(1) = W_i(1) + λ·M_i(1)`, `G_i(∞) = W_i(∞) + λ·M_i(∞)`,

with `W_i` a function of `a, b, c` and the earlier challenges, and, writing `g(x) = c + Σ_j (g_j x_j + h_j x_j²)`,

`M_i(∞) = h_i`, `M_i(1) = c + Σ_{j<i} (g_j ρ_j + h_j ρ_j²) + g_i + h_i + Σ_{j>i} r_j (g_j + h_j)`, `S = c + Σ_j r_j (g_j + h_j)`.

The map `G ↦ (S, M_1(1), M_1(∞), …, M_n(1), M_n(∞))` is an `E`-linear bijection of `E^(2n+1)`: the `M_i(∞)` give the `h_i`; then `M_i(1) + S` is, up to known terms in the `h_j`, `Σ_{j<i} (ρ_j + r_j) g_j + (1 + r_i) g_i`, a triangular system in the `g_i` with diagonal `1 + r_i ≠ 0`; and `S` then gives `c`. Since `G` is uniform and independent of everything else, so is its image, and so is that image times `λ` plus anything independent of `G`. ∎

The last three scalars are `â = (Az)~(ρ)`, `b̂ = (Bz)~(ρ)` and `γ = g(ρ)`. The verifier's final equation is `claim = â·b̂ + ĉ + λ·γ` with `ĉ = (Cz)~(ρ)`, so, given the rounds, `γ` and `ĉ` determine each other: the zerocheck's view is the `2n + 1` uniform scalars and `(â, b̂, ĉ)`.

### Lemma 2 (the three evaluations)

Coordinates of `ρ` are numbered from 0 here, as wire bits are. Let `ρ_j ∉ {0, 1}` for all `j`. Write `ρ_comp` for the six coordinates of `ρ` that index the compression (the top six), and `τ_j = ρ_j / (1 + ρ_j)`. Suppose some coordinate `ρ_a` of `ρ_comp` is outside `K`, and no product `Π_{j ∈ B} τ_j^(±1)` over a nonempty set `B` of the other five coordinates is in `K`. Then, for every fixed value of the other wires, `(â, b̂, ĉ)` is within `2^-11000` of uniform on `E³`.

*Proof.* Let `U_{c,i}, V_{c,i}, W_{c,i}` be the wires and `x^U_{c,i} = eq(ρ, U_{c,i})`, and likewise `x^V`, `x^W`. From the three rows,

- `â = â_0 + Σ (x^U + x^W)·u + Σ x^V·v`,
- `b̂ = b̂_0 + Σ x^W·v`,
- `ĉ = ĉ_0 + Σ x^U·u + Σ x^V·v + Σ x^W·u·v`,

sums over `(c, i)`, with `â_0, b̂_0, ĉ_0` independent of the hiding wires. The three wires of a triple differ in local bits 5 and 6 only (`57·32`, `58·32`, `59·32` are bits `{5}`, `{6}`, `{5,6}` above bits 8 to 10), so `x^U = θ·x^W` with `θ = (1 + ρ_6)/ρ_6` the same for every `(c, i)`. And `x^W_{c,i} = ν·l_i·χ_c`, with `ν ≠ 0` a product over fixed bits, `l_i ≠ 0` depending on `i`, and `χ_c = eq(ρ_comp, c)`.

*Claim: a 2-dimensional `K`-subspace `V` of `E` contains at most 33 of the 64 values `χ_c`.* Pair `c` with the index differing in coordinate `a`: the pair is `m(1 + ρ_a)` and `m ρ_a`, with `m` a product over the other five coordinates. If both are in `V` then `m` and `m ρ_a` are, so `V = m·span{1, ρ_a}`. If two pairs, with `m` and `m'`, are both in `V`, then `(m'/m)·span{1, ρ_a} = span{1, ρ_a}`, so `m'/m ∈ K` by (A4). But `m'/m` is a product `Π_{j∈B} τ_j^(±1)` with `B` the nonempty set of coordinates where the two indices differ, which is outside `K` by hypothesis. So at most one of the 32 pairs lies in `V`, and each other pair has a member outside it.

Consequently the `x^W_{c,i}` span `E` (they are not in one 2-dimensional subspace), so by (A1) `b̂` is uniform, as a function of the `v` alone.

Now fix the `v`. Then `(â, ĉ)` is, up to a constant, the `K`-linear image of the `u` under `u ↦ Σ x^W_{c,i}·(θ + 1, θ + v_{c,i})·u_{c,i}`. By (A2) applied to `E²`, it is onto `E²` (and then `(â, ĉ)` is uniform, independently of `b̂`) unless there is `(s, t) ≠ 0` in `E²` with

`Tr(x^W_{c,i}·((s + t)θ + s)) + v_{c,i}·Tr(x^W_{c,i}·t) = 0` for all `(c, i)`.

If `t = 0` this says `Tr(x^W_{c,i}·s/ρ_6) = 0` for all `(c, i)` (as `θ + 1 = 1/ρ_6`), which is false because the `x^W` span `E`. If `t ≠ 0`, the set `{x : Tr(x t) = 0}` is 2-dimensional, so by the claim, applied for each `i` to the subspace scaled by `ν l_i`, at least `6·31 = 186` of the `(c, i)` have `Tr(x^W_{c,i}·t) ≠ 0`, and each of them forces `v_{c,i}` to one value: probability at most `2^(-64·186)` over the `v`. A union over the fewer than `2^384` pairs `(s, t)` gives that the `v` are bad with probability below `2^(384 − 11904)`. The statistical distance of `(â, b̂, ĉ)` from uniform is at most that. ∎

### Lemma 3 (lincheck)

Let `μ ∉ K`. The table `t = z + μ m_0 + μ² m_1 + μ³ m_2` is uniform in `E^(2^n)` and independent of `z`, and the lincheck's messages (the three sums `S_k = Σ_y comb(y) m_k(y)`, then the rounds) are a function of `t`, the public `comb`, and the lincheck's claim `v`.

*Proof.* By (A4), `μ, μ², μ³` is a `K`-basis of `E`, so `(m_0, m_1, m_2) ↦ μ m_0 + μ² m_1 + μ³ m_2` is a bijection from `(K^(2^n))³` to `E^(2^n)`: `t` is uniform whatever `z` is. The rounds are the sumcheck of `comb·t`, a function of `comb` and `t`. Let `pr_k : E → K` be the coordinates in that basis. Then `m_k = pr_k(t + z)` entrywise, and `z` has entries in `K`, so `pr_k(z(y)) = z(y)·pr_k(1)` and

`S_k = Σ_y comb(y)·pr_k(t(y)) + pr_k(1)·Σ_y comb(y) z(y) = Σ_y comb(y)·pr_k(t(y)) + pr_k(1)·v`,

since the honest `z` satisfies `Σ comb·z = v`. ∎

The verifier's `v` is a function of `(â, b̂, ĉ, γ)`, the statement and the challenges. The sumcheck ends on `comb~(q)·t~(q)`, and the claim left to the commitment is `P~(q, s_1, s_2) = t~(q)/((1 + μ)(1 + μ²))` at `s_1 = μ/(1 + μ)`, `s_2 = μ²/(1 + μ²)`, on `P = (z, m_0, m_1, m_2)`: a function of `t`.

**Summary.** Outside the bad challenges of Lemmas 1 to 3, the sumcheck transcript is a fixed function of: `2n + 1` uniform scalars, a triple `2^-11000`-close to uniform on `E³`, and a uniform table `t`, the three independent. None depends on the witness.

## 4. The commitment and its opening

The committed table `T` has 26 variables: `y ∈ {0,1}^20` inside a lane (variables 0 to 19) and a lane index in `{0,1}^6` (variables 20 to 25). Lane `(b, l')`, with `b` variable 20 and `l' ∈ {0,1}^5`, holds, on its `2^19` entries with variable 19 equal to 1, the block `P_{l'}` of `P` if `b = 0` and padding `R¹_{l'}` if `b = 1`; and on its entries with variable 19 equal to 0, padding `L_{(b,l')}`. All padding is uniform over `K`.

The claim is `P~(p) = v`, which `hidden_point` writes as `T~(p_low, 1, 0, π) = v`, where `p_low` is the first 19 coordinates of `p` and `π` the last five. Let `x_y = eq(p_low, y)` for `y ∈ {0,1}^19`.

What the opening shows, in the order of `whir::recursive_prover_with_basis`:

1. six rounds of a sumcheck of `Σ T·eq((p_low, 1, 0, π), ·) = v` that bind the lane variables in order, with challenges `φ_0` and `φ = (φ_1, …, φ_5)`;
2. the folded table `f¹(y) = Σ_lanes eq((φ_0, φ), lane)·T(y, lane)`, an `E`-valued table of 20 variables. Everything after the lane rounds is a function of `f¹` and the challenges alone: the first in-lane round message, the commitment to `f¹`, its out-of-domain values, every later sumcheck message, commitment and opened row, and the final polynomial;
3. the rows of the first commitment at a set `Q` of positions: for each lane, the value at each `x ∈ Q` of the lane's codeword. A lane's codeword is the evaluation, on a domain of `2^21` points, of the polynomial whose coefficients in the novel basis are the lane's `2^20` entries; the basis polynomial of index `j` has degree `j` (`doc/leanvm`, annex D), so the entries with variable 19 equal to 0 carry an arbitrary polynomial of degree below `2^19`;
4. Merkle siblings of the first commitment: hashes of rows outside `Q`, and of nodes above them. (The later commitments' siblings are functions of `f¹`, under item 2.)

There is no out-of-domain sample on the first commitment (`ood_samples[0] = 0`).

### Lemma 4 (the opening depends on `P` through `v` only)

Suppose `|Q| ≤ 2^19`, `φ_0 ≠ 0`, `φ_j ≠ π_j` for `j ≤ 4`, `σ^i φ_5 ≠ π_5` for `i = 0, 1, 2`, the first two coordinates of `p_low` are outside `K`, `φ_1 ∉ K`, and at least one of the three determinants `Det_j = det[(1, σ^i φ_1, σ^i φ_j)]_{i=0,1,2}`, `j = 2, 3, 4`, is nonzero. Let `P` and `P'` be `K`-valued with `P~(p) = P'~(p)`. Then there is a translation of the padding, `(L, R¹) ↦ (L + ΔL, R¹ + ΔR¹)`, a bijection, under which items 1 to 3 for `P` equal items 1 to 3 for `P'`.

*Proof.* Let `D = P + P'`, so `D~(p) = 0`. Write `e_l = eq(φ, l)` for `l ∈ {0,1}^5`, and `κ = (1 + φ_0)/φ_0`. We need `ΔR¹` and `ΔL` over `K` such that the table `Δ = (D, ΔR¹, ΔL)` has no effect on items 1 to 3.

*Item 2, upper half.* For `y` with variable 19 equal to 1, the change of `f¹` is `(1 + φ_0)·Σ_l e_l D_l(y) + φ_0·Σ_l e_l ΔR¹_l(y)`. It vanishes if and only if

(i) `Σ_l e_l ΔR¹_l(y) = κ·Σ_l e_l D_l(y)` for every `y ∈ {0,1}^19`.

*Item 1.* The lane rounds see `T` through `g(lane) = Σ_y x_y T(y, lane)` (on the upper half; the weight is zero on the lower). Round `j` is `eq(point_j, X)` times a constant times `g~(φ_{<j}, X, point_{>j})`, a linear polynomial in `X`. So the rounds are unchanged if `Δg~` vanishes at `(φ_{<j}, b, point_{>j})` for every round `j` and `b ∈ {0, 1}`. With `d_l = Σ_y x_y D_l(y)` and `δ_l = Σ_y x_y ΔR¹_l(y)`: the first round asks `d~(π) = 0`, which is `D~(p) = 0`, and `δ~(π) = 0`; the others ask `(1 + φ_0) d~(w) + φ_0 δ~(w) = 0` at the ten points `w = (φ_{<i}, b, π_{>i})`. All of these follow from

(ii) `δ~(w_k) = κ·d~(w_k)` for `k = 0, …, 5`, where `w_k = (φ_1, …, φ_k, π_{k+1}, …, π_5)`,

because `w_0 = π` (where `d~` vanishes), and, as `φ_i ≠ π_i`, evaluation at `(φ_{<i}, b, π_{>i})` is a combination of evaluations at `w_{i-1}` and `w_i` (a function linear in variable `i` is determined by its values at `π_i` and `φ_i`). At `k = 5`, (ii) is (i) summed against `x_y`.

*Solving (i) and (ii) over `K`.* Let `Φ` be the `E`-linear map on tables `X = (X_l(y))`, `l ∈ {0,1}^5`, `y ∈ {0,1}^19`: `Φ(X) = ((Σ_l e_l X_l(y))_y, (Σ_{l,y} eq(w_k, l) x_y X_l(y))_{k=0..4})`. Conditions (i) and (ii) say `Φ(ΔR¹) = Φ(κD)`. Here `κD` has entries in `E`, so it is enough that `Φ` maps the `K`-valued tables onto the image of the `E`-valued ones. Suppose not. Then some nonzero `K`-linear functional of `E^(2^19) × E^5` vanishes on the image of the `K`-valued tables: there are `(a_y)` and `(t_k)` in `E`, not all zero, with

(∗) `Tr(a_y e_l + x_y β_l) = 0` for all `l, y`, where `β_l = Σ_k t_k eq(w_k, l)`.

First, the eight vectors `eq(σ^i φ, ·)` (`i = 0, 1, 2`) and `eq(w_k, ·)` (`k = 0..4`) of `E^32` are linearly independent over `E`. Indeed let `Σ_i s_i f(σ^i φ) = Σ_k t_k f(w_k)` for every multilinear `f` in five variables. Take `f = (X_5 + π_5)·A(X_1, …, X_4)`: it vanishes at every `w_k` with `k ≤ 4`, so `Σ_i s_i (σ^i φ_5 + π_5) A(σ^i φ_{1..4}) = 0` for every multilinear `A`. A nonzero `Det_j` makes the three points `σ^i φ_{1..4}` independent under the functions `1, X_1, X_j`, so `s_i (σ^i φ_5 + π_5) = 0` and `s_i = 0`. Then `f = Π_{j ≤ k} (X_j + π_j)` for `k = 4, 3, …, 0` gives `t_k = 0` in turn, using `φ_j ≠ π_j`.

In particular the `e_l` span `E` over `K`: otherwise `Tr(s e_l) = 0` for all `l` with `s ≠ 0`, which by (A5) reads `Σ_i σ^i(s)·eq(σ^i φ, l) = 0`. And the `x_y` span `E` over `K` by (A6).

Now take (∗). For a `K`-linear relation `Σ_l c_l e_l = 0`, summing (∗) gives `Tr(x_y·Σ_l c_l β_l) = 0` for all `y`, so `Σ_l c_l β_l = 0` by (A2). Hence `e_l ↦ β_l` extends to a well defined `K`-linear map `E → E`, which by (A3) and (A5) means `β = Σ_i s_i eq(σ^i φ, ·)`. By the independence, `β = 0` and `t = 0`; then (∗) reads `Tr(a_y e_l) = 0` for all `l`, so `a_y = 0`. Contradiction. So a `K`-valued `ΔR¹` satisfying (i) and (ii) exists.

*Items 2 (lower half) and 3.* Let `M : K^(2^19) → K^Q` evaluate a polynomial of degree below `2^19`, given by its novel-basis coefficients, at the points of `Q`. It is onto, since `|Q| ≤ 2^19` distinct points impose independent conditions; let `N` be a `K`-linear right inverse. Let `c_lane ∈ K^Q` be the change of the lane's codeword on `Q` caused by its upper half (`D_l` or `ΔR¹_l`), and set `ΔL_lane = N c_lane`. Then every opened row is unchanged. And the lower half of `f¹` changes by `Σ_lane ε_lane ΔL_lane = N(Σ_lane ε_lane c_lane)` (with `ε_lane` the lane's fold weight and `N` extended `E`-linearly), where `Σ_lane ε_lane c_lane` is the restriction to `Q` of the codeword of the change of the upper half of `f¹`, which is zero by (i). ∎

### Lemma 5 (the hashes)

Under the hypotheses of Lemma 4 with `|Q| < 2^19`, for each position `x ∉ Q` there is a `K`-space `C_x ⊆ K^64` of dimension at least 61 such that the joint law of (items 1 to 3, the row at `x`) is invariant under translating the row by any element of `C_x`. So, conditioned on items 1 to 3, the row at `x` takes any given value with probability at most `2^(-64·61)`.

*Proof.* Fix a `u ∈ K^(2^19)` whose polynomial vanishes on `Q` and is 1 at `x`. Let `C_x = {c ∈ K^64 : Σ_lane ε_lane c_lane = 0}`, one `E`-linear condition, that is three `K`-linear ones, so of dimension at least `64 − 3`. For `c ∈ C_x`, translating the padding by `ΔL_lane = c_lane·u` is a bijection that leaves items 1 (the weight is zero on the lower half), 2 (by the condition on `c`) and 3 unchanged, and moves the row at `x` by `c`. ∎

**The siblings.** Compare two worlds with the same challenges: `P` with padding `(L, R¹)`, and `P'` with the padding translated as in Lemma 4, so that items 1 to 3 coincide. Their views then differ only in the first commitment's siblings, each a hash chain over rows outside `Q`. Define the oracle of the second world from the first by exchanging its values on each pair (row of world one at `x`, row of world two at `x`), for `x ∉ Q`: it is again a random oracle, and under it the two views are identical. A distinguisher therefore tells the worlds apart only if it queries the oracle at an unopened row of either, which by Lemma 5 has probability at most `2·H·2^21·2^(-64·61) < H·2^-3800`. Inner nodes need no separate argument: under the exchange they are equal in the two worlds.

## 5. The simulator

Given the challenges:

1. Draw the `2n + 1` zerocheck scalars and `(â, b̂, ĉ)` uniformly; set `γ` by the verifier's final zerocheck equation.
2. Draw `t ∈ E^(2^n)` uniformly. Compute the lincheck's claim `v` as the verifier does, then `S_k = Σ comb·pr_k(t) + pr_k(1)·v`, and run the lincheck's sumcheck on `comb·t` honestly. The circuit's three evaluations and its opening are public.
3. The claim on the commitment is now fixed: `P~(p) = v'`. Choose any `K`-valued `P'` with `P'~(p) = v'` (one exists by (A1) and (A6)), draw fresh padding, commit `T'` and open it honestly.

**Correctness.** Steps 1 and 2 have the distribution of the honest sumcheck transcript by Lemmas 1 to 3, up to `2^-11000`. Given that transcript, the honest opening is the opening of `P` under uniform padding independent of the transcript, and step 3 is the opening of `P'` under uniform padding. By Lemma 4 items 1 to 3 have the same distribution in both. By the argument after Lemma 5 the siblings are indistinguishable but with probability `H·2^-3800`.

**Bad challenges**, where a lemma's hypothesis fails:

| hypothesis | probability at most |
| --- | --- |
| some `r_i = 1` (the prover aborts), `λ = 0`, a coordinate of `ρ` in `{0, 1}`; in the opening, a coincidence `φ_j = π_j` or `σ^i φ_5 = π_5`, or `φ_0 = 0` | `2^-180` |
| Lemma 2: `ρ_a ∈ K` | `2^-128` |
| Lemma 2: one of the 121 products of `τ_j^(±1)` in `K` | `121·2^-128` |
| Lemma 3: `μ ∈ K` | `2^-128` |
| Lemma 4: one of the first two coordinates of `p_low` in `K` | `2·2^-128` |
| Lemma 4: `φ_1 ∈ K` | `2^-128` |
| Lemma 4: `Det_2 = Det_3 = Det_4 = 0` given `φ_1 ∉ K` | `2^-192` |

For the last line: with `a = φ_1 ∉ K`, `Det_j = (a + σa)(b + σ²b) + (a + σ²a)(b + σb)` at `b = φ_j` is a nonzero `σ`-polynomial in `b` of `σ`-degree 2 (its coefficients `a + σa` and `a + σ²a` are nonzero by (A4)), whose roots form a `K`-subspace of dimension at most 2: probability at most `2^-64` for each `j`, independently. The product bound of Lemma 2: for fixed other coordinates, the product is in `K` for at most `2^64` values of one `τ_j`, and `ρ_j ↦ τ_j` is a bijection of `E \ {1}`. The total is below `2^-120`; the theorem's `2^-118` leaves room for the rest; the opening's `|Q| < 2^19` always holds (a few hundred queries).

## 6. What this does and does not establish

- It is a proof for an honest verifier with uniform challenges, turned into a statement about the non-interactive proof by the standard programmable random oracle argument, which is not repeated here.
- The prover's randomness must be uniform: `G`, the hiding wires, the three masks and the padding. The benchmark draws them from the test generator, which is not a cryptographic one.
- In the interactive statement the hash is a random oracle only where it hides unopened rows, and nothing else is computational. The non-interactive proof also needs the transcript hash as a programmable oracle.
- The hypotheses of Lemma 4 are sufficient, not necessary: its `2^-128` terms come from the proof, not from a known failure.
- It says nothing about timing or memory side channels of the prover.
- The statement is about the witness: the public `(y, root)` are of course not hidden, and neither is the circuit.
