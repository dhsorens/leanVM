import QuotientSecurity.PublicWeight
import QuotientSecurity.ConcreteZK
import QuotientSecurity.Sequence
import QuotientSecurity.Joint
import QuotientSecurity.Notation

/-!
# The statements

What is proved about `flock::quotient`, in one place. Read this file first: each theorem here is
a short restatement of one proved elsewhere, on the protocol's own instance and with its
hypotheses reduced to what cannot be removed.

* `Membership`: the fixed data of the protocol, a Cantor basis, a wiring and the constants.
* `Membership.Relation`: what is proved of the cells, written on cells indexed by their bits.
* `Membership.soundness`: knowledge soundness in the random-oracle model, `(Q + 3) / 2^128`.
* `Membership.zero_knowledge`: zero knowledge, `1 / 2^128` plus the stale handles.
* `Membership.completeness`: the honest proof is accepted, but for `2 / 2^128` plus the same.
* `Membership.nonempty`: the data exists over every field of `2^192` elements.

The commitment is ideal and the hash is a random oracle: `README.md` says what that means here.
-/

set_option linter.unusedSectionVars false

open OracleSpec OracleComp Polynomial Module NNReal

namespace QuotientSecurity

/-- **The fixed data of the protocol** over a field `F`: a Cantor basis of 22 vectors (the cells
are its span, `2^20` rows of four), the wiring, a permutation of the cells, and the verifier's
constants: `b`, which inverts the basis, and `c`, the weights of the public bits. -/
structure Membership (F : Type) [Field F] [CharP F 2] where
  basis : CantorBasis F (20 + 2)
  wiring : Equiv.Perm (Fin (20 + 2) → Bool)
  b : ℕ → F
  c : ℕ → F
  hb0 : b 0 = 1
  hb : ∀ d, 1 ≤ d → d < 11 → ∑ e ∈ Finset.range (d + 1), b e * basis.β (d - e) = 0

namespace Membership

variable {F : Type} [Field F] [DecidableEq F] [CharP F 2] (I : Membership F)

omit [DecidableEq F] in
theorem size : 20 + 2 ≤ 20 + 2 := Nat.le_refl _

/-- The protocol's parameters and the degree bounds of its messages. -/
noncomputable def params : Params F :=
  membershipParams I.basis size I.wiring I.b I.c I.hb0 I.hb

noncomputable def bounds : I.params.Bounds :=
  membershipBounds I.basis size I.wiring I.b I.c I.hb0 I.hb

/-- The cells, by their bits. -/
noncomputable def cellEquiv : (Fin (20 + 2) → Bool) ≃ I.params.T × Fin 4 :=
  cantorCells (n := 20) I.basis size

/-- **The relation.** Cells are indexed by their 22 bits: two for the role in the row (`X`, `Y`,
`C`, `V`), twenty for the row. Every row is a full adder, cells wired together are equal, and
each of the eight public words is the weighted sum of its cells. -/
def Relation (stmt : Fin 8 → F) (w : (Fin (20 + 2) → Bool) → F) : Prop :=
  (∀ y : Fin 20 → Bool, gate (I.basis.β 1) (w (cellBits (y, 0))) (w (cellBits (y, 1)))
      (w (cellBits (y, 2))) (w (cellBits (y, 3))) = 0) ∧
    (∀ x, w (I.wiring x) = w x) ∧
    ∀ J : Fin 8, ∑ x, regionWeight I.c J x * w x = stmt J

/-- The witness polynomial of a first message: `sum_j X_j * g_j(X^4 + X)`. -/
noncomputable def witnessPoly (g : Params.Witness F) : F[X] := ∑ j, digit j * (g j).comp rowPoly

/-- **The cells a first message holds**: its witness polynomial at each cell's point. -/
noncomputable def cellsOf (g : Params.Witness F) (x : Fin (20 + 2) → Bool) : F :=
  (witnessPoly g).eval (I.basis.point x)

theorem cellsOf_eq (g : Params.Witness F) (x : Fin (20 + 2) → Bool) :
    I.cellsOf g x = I.params.cells g (I.cellEquiv x) := by
  have h := Params.cellPoly_zero_eval_pt I.params g (I.cellEquiv x)
  have hp : I.params.pt (I.cellEquiv x) = I.basis.point x :=
    cantorCells_point (n := 20) I.basis size x
  rw [← h, hp]
  unfold cellsOf witnessPoly Params.cellPoly
  congr 1
  refine Finset.sum_congr rfl fun j _ => ?_
  simp [shift]

/-- The model's relation on its own cells is `Relation` on cells indexed by bits. -/
theorem sat_iff (stmt : Fin 8 → F) (w : I.params.T × Fin 4 → F) :
    I.params.Sat stmt w ↔ I.Relation stmt fun x => w (I.cellEquiv x) := by
  set e := I.cellEquiv with he
  have hrow : ∀ (y : Fin 20 → Bool) (c : Fin 4),
      e (cellBits (y, c)) = (cantorRows (n := 20) I.basis size y, c) := by
    intro y c
    rw [he]
    show (Equiv.prodCongr _ _) (cellBits.symm (cellBits (y, c))) = _
    rw [Equiv.symm_apply_apply]
    rfl
  have hσ : ∀ x, I.params.σ (e x) = e (I.wiring x) := fun x => by
    show (e.permCongr I.wiring) (e x) = _
    simp [Equiv.permCongr_apply]
  have hword : ∀ J : Fin 8, I.params.wordSum J w = ∑ x, regionWeight I.c J x * w (e x) :=
    fun J => membershipParams_wordSum I.basis size I.wiring I.b I.c I.hb0 I.hb J w
  unfold Params.Sat Relation
  refine and_congr ⟨fun h y => ?_, fun h x => ?_⟩ (and_congr ⟨fun h x => ?_, fun h i => ?_⟩
    (forall_congr' fun J => by rw [hword J]))
  · have := h (cantorRows (n := 20) I.basis size y)
    simp only [hrow]
    exact this
  · obtain ⟨y, rfl⟩ := (cantorRows (n := 20) I.basis size).surjective x
    have := h y
    simp only [hrow] at this
    exact this
  · have := h (e x)
    rwa [hσ x] at this
  · obtain ⟨x, rfl⟩ := e.surjective i
    rw [hσ x]
    exact h x

private theorem cells_eq (g : Params.Witness F) :
    (fun x => I.params.cells g (I.cellEquiv x)) = I.cellsOf g :=
  funext fun x => (I.cellsOf_eq g x).symm

/-! ## Knowledge soundness -/

section Soundness

variable [Fintype F] [SampleableType F]

/-- A statement and a proof of it: eight public words, the first message (four polynomials of
degree at most `2^21`), the second (five of degree at most `2^24`) and five field elements. With
ideal commitments the hash absorbs the messages themselves. -/
abbrev Proof := QuotientSecurity.Proof I.params I.bounds

/-- An adversary: any computation that asks the random oracle and outputs a statement and a
proof. -/
abbrev Adversary := OracleComp (ofFn (Answer I.params I.bounds)) I.Proof

private theorem bound_eq (Q : ℕ) :
    ((Q + 3 : ℕ) : ENNReal) * (((1 / 2 ^ 128 : ℝ≥0) : ℝ≥0) : ENNReal)
      = (Q + 3 : ENNReal) / 2 ^ 128 := by
  rw [ENNReal.coe_div (by positivity)]
  simp [div_eq_mul_inv]

/-- **Knowledge soundness.** Over a field of `2^192` elements, for every adversary making at
most `Q` oracle queries: the probability that the verifier accepts its proof while the cells its
first message holds do not satisfy the relation is at most `(Q + 3) / 2^128`. -/
theorem soundness (hq : Fintype.card F = 2 ^ 192) (adv : I.Adversary) (Q : ℕ)
    (hQ : IsTotalQueryBound adv Q) :
    Pr{let r ← (simulateQ randomOracle (experiment adv)).run' ∅}[
        r.2 = true ∧ ¬ I.Relation r.1.stmt (I.cellsOf r.1.g.1)]
      ≤ (Q + 3 : ENNReal) / 2 ^ 128 := by
  have h := knowledgeSoundness_membership I.basis size I.wiring I.b I.c I.hb0 I.hb hq adv Q hQ
  rw [bound_eq] at h
  refine le_trans (prEvent_mono _ _ _ fun r hr => ⟨hr.1, fun hsat => hr.2 ?_⟩) h
  have := (I.sat_iff r.1.stmt _).mp hsat
  exact (I.cells_eq r.1.g.1) ▸ this

end Soundness

/-! ## Zero knowledge and completeness

The witness lives in a field `K` of which `E` is an extension of degree 3, and so does the basis.
Commitments are ideal and hiding: the hash absorbs handles drawn at random, in `H`. The prover's
row polynomials are `gK`, each masked by `digitPoly 20`, which vanishes on the rows, times three
random coefficients (`committed`). `realNI` is the honest prover against the oracle in the state
`c₀`, and `simNI` the simulator, which is given the statement only. Both output the proof, its
verdict and the oracle's table. -/

section ZeroKnowledge

variable {K E : Type} [Field K] [Field E] [Algebra K E] [DecidableEq E] [CharP E 2] [Fintype E]
variable [CharP K 2] [Fintype K] [DecidableEq K] [FiniteDimensional K E]
variable [SampleableType K] [SampleableType E]
variable {H : Type} [SampleableType H] [Fintype H] [DecidableEq H]
variable (I : Membership E)

omit [Fintype E] [Fintype K] [DecidableEq K] [FiniteDimensional K E] [SampleableType K]
  [SampleableType E] [SampleableType H] [Fintype H] [DecidableEq H] [CharP K 2] [DecidableEq E]
  [CharP E 2] [Algebra K E] [Field K] in
private theorem coe_bit : (((1 / 2 ^ 128 : ℝ≥0) : ℝ≥0) : ENNReal) = 1 / 2 ^ 128 := by
  rw [ENNReal.coe_div (by positivity)]
  simp

omit [Fintype E] [Fintype K] [DecidableEq K] [FiniteDimensional K E] [SampleableType K]
  [SampleableType E] [SampleableType H] [Fintype H] [DecidableEq H] [CharP K 2] in
/-- The mask's polynomial vanishes on the rows. -/
theorem mask_vanishes (x : I.params.T) :
    aeval (rowPoly.eval (x : E)) (digitPoly 20 : K[X]) = 0 := by
  obtain ⟨y, -, hy⟩ := Finset.mem_image.mp x.2
  rw [← eval_map_algebraMap, digitPoly_map, digitPoly_eval, rowPoly_eval,
    ← Function.iterate_add_apply, ← hy]
  exact I.basis.iterate_point size _

omit [Fintype K] [DecidableEq K] [FiniteDimensional K E] [SampleableType K]
  [SampleableType E] [SampleableType H] [Fintype H] [DecidableEq H] [CharP K 2] [Algebra K E]
  [Field K] in
theorem exact : I.params.Exact :=
  Params.ofCantor_exact I.basis size I.wiring 8 _ _
    (membershipPub_hPub I.basis I.b I.c size I.hb0 I.hb)

omit [DecidableEq H] [SampleableType H] in
private theorem zkBound_le (hq : Fintype.card E = 2 ^ 192) (U : Finset H) :
    zkBound I.params (digitPoly 20 : K[X]) U ≤ 1 / 2 ^ 128 + U.card / Fintype.card H := by
  have he : zkError I.params (digitPoly 20 : K[X]) ≤ 1 / 2 ^ 128 :=
    zkError_le hq (Params.ofCantor_nCells I.basis size I.wiring 8 _ _
      (membershipPub_hPub I.basis I.b I.c size I.hb0 I.hb)) _ (digitPoly_monic_natDegree 20).2.le
  unfold zkBound
  rw [← coe_bit]
  exact add_le_add_left (ENNReal.coe_le_coe.mpr he) _

variable (H) in
/-- The oracle's table: what it has answered so far. -/
abbrev Table := (ofFn (ZAnswer I.params H)).QueryCache

variable (H) in
/-- What an experiment outputs: the proof with its verdict and challenges, and the table. -/
abbrev View := Outcome (E := E) H × I.Table H

/-- **The real experiment**: the honest prover, on the witness `gK`, against the random oracle in
the state `c₀`. -/
noncomputable def real (c₀ : I.Table H) (stmt : Fin 8 → E) (gK : Fin 4 → K[X]) :
    ProbComp (I.View H) :=
  realNI c₀ stmt gK (digitPoly 20)

variable (K) in
/-- **The simulator**: it is given the statement and the oracle's state, and no witness. -/
noncomputable def sim (c₀ : I.Table H) (stmt : Fin 8 → E) : ProbComp (I.View H) :=
  simNI (K := K) c₀ stmt

set_option linter.deprecated false in
private theorem real_event (c₀ : I.Table H) (stmt : Fin 8 → E) (gK : Fin 4 → K[X])
    (S : I.View H → Prop) :
    Pr{let o ← I.real c₀ stmt gK}[S o] = Pr[S | realNI c₀ stmt gK (digitPoly 20)] :=
  prEvent_eq_probEvent _ S

set_option linter.deprecated false in
private theorem sim_event (c₀ : I.Table H) (stmt : Fin 8 → E) (S : I.View H → Prop) :
    Pr{let o ← I.sim K c₀ stmt}[S o] = Pr[S | simNI (K := K) c₀ stmt] :=
  prEvent_eq_probEvent _ S

/-- **Zero knowledge.** For a statement, a witness over `K` that satisfies the relation, and any
oracle state, of which `U` holds the handles already asked about with this statement: every
event on the outcome has probabilities in the real experiment and in the simulator's that differ
by at most `1 / 2^128 + |U| / |H|`. -/
theorem zero_knowledge (h3 : finrank K E = 3) (hq : Fintype.card E = 2 ^ 192)
    (c₀ : I.Table H) (stmt : Fin 8 → E)
    (U : Finset H) (hU : ∀ c₁, c₁ ∉ U → Fresh c₀ stmt c₁) (gK : Fin 4 → K[X])
    (hsat : I.Relation stmt (I.cellsOf (committed gK (digitPoly 20) 0)))
    (S : I.View H → Prop) :
    Pr{let o ← I.real c₀ stmt gK}[S o]
        ≤ Pr{let o ← I.sim K c₀ stmt}[S o] + (1 / 2 ^ 128 + U.card / Fintype.card H) ∧
      Pr{let o ← I.sim K c₀ stmt}[S o]
        ≤ Pr{let o ← I.real c₀ stmt gK}[S o] + (1 / 2 ^ 128 + U.card / Fintype.card H) := by
  have hsat' : I.params.Sat stmt (I.params.cells (committed gK (digitPoly 20) 0)) :=
    (I.sat_iff stmt _).mpr ((I.cells_eq _).symm ▸ hsat)
  have h := zeroKnowledge h3 I.exact c₀ stmt U hU gK (digitPoly 20)
    (digitPoly_monic_natDegree 20).1.ne_zero I.mask_vanishes hsat' S
  have hle := I.zkBound_le (K := K) hq U
  rw [I.real_event, I.sim_event]
  exact ⟨h.1.trans (add_le_add_right hle _), h.2.trans (add_le_add_right hle _)⟩

/-- **Completeness.** In the same experiment, with row polynomials of degree at most `2^21`: the
verifier's verdict on the honest proof is false with probability at most
`2 / 2^128 + |U| / |H|`. -/
theorem completeness (hq : Fintype.card E = 2 ^ 192)
    (c₀ : I.Table H) (stmt : Fin 8 → E)
    (U : Finset H) (hU : ∀ c₁, c₁ ∉ U → Fresh c₀ stmt c₁) (gK : Fin 4 → K[X])
    (hdeg : ∀ j, (gK j).natDegree ≤ 2 ^ 21)
    (hsat : I.Relation stmt (I.cellsOf (committed gK (digitPoly 20) 0))) :
    Pr{let o ← I.real c₀ stmt gK}[o.1.verdict = false]
      ≤ 2 / 2 ^ 128 + U.card / Fintype.card H := by
  have hsat' : I.params.Sat stmt (I.params.cells (committed gK (digitPoly 20) 0)) :=
    (I.sat_iff stmt _).mpr ((I.cells_eq _).symm ▸ hsat)
  have hvdeg : (digitPoly 20 : K[X]).natDegree = 2 ^ 20 := (digitPoly_monic_natDegree 20).2
  have hg : ∀ m j, (committed (E := E) gK (digitPoly 20) m j).natDegree ≤ I.bounds.witness := by
    intro m j
    refine (natDegree_committed_le gK _ m j).trans (max_le (hdeg j) ?_)
    rw [hvdeg]
    show 2 ^ 20 + 2 ≤ 2 ^ (20 + 1)
    norm_num
  have h := completeness_prob I.exact c₀ stmt U hU gK (digitPoly 20)
    (digitPoly_monic_natDegree 20).1.ne_zero I.mask_vanishes hsat'
    (I.cellEquiv fun _ => false) I.bounds hg
  have hid : I.bounds.identity ≤ 2 ^ 27 :=
    Params.ofCantor_identity I.basis size I.wiring _ _
      (membershipPub_hPub I.basis I.b I.c size I.hb0 I.hb) (natDegree_membershipPub_le I.b I.c)
  have hpos : 0 < Fintype.card E := Fintype.card_pos
  have e2 : (I.bounds.identity : ENNReal) / (Fintype.card E : ENNReal) ≤ 1 / 2 ^ 128 := by
    have hle := div_le_two_pow hpos (a := I.bounds.identity) (by
      rw [hq]; exact (Nat.mul_le_mul_right (2 ^ 128) hid).trans (by norm_num))
    have hc : (I.bounds.identity : ENNReal) / (Fintype.card E : ENNReal)
        = (((I.bounds.identity : ℝ≥0) / (Fintype.card E : ℝ≥0) : ℝ≥0) : ENNReal) := by
      rw [ENNReal.coe_div (by exact_mod_cast hpos.ne')]
      simp
    rw [hc, ← coe_bit]
    exact ENNReal.coe_le_coe.mpr hle
  rw [I.real_event]
  refine (h.trans (add_le_add (I.zkBound_le (K := K) hq U) e2)).trans (le_of_eq ?_)
  rw [show (2 : ENNReal) / 2 ^ 128 = 1 / 2 ^ 128 + 1 / 2 ^ 128 by
    rw [ENNReal.div_add_div_same]; norm_num]
  ring

end ZeroKnowledge

end Membership

/-! ## The data exists -/

/-- The constants that invert a basis: `b 0 = 1`, `b d = sum_{e < d} b e * beta (d - e)`. -/
noncomputable def invSeq {F : Type} [Field F] (β : ℕ → F) : ℕ → F
  | 0 => 1
  | d + 1 => ∑ e : Fin (d + 1), invSeq β e * β (d + 1 - e)
decreasing_by exact e.2

theorem invSeq_sum {F : Type} [Field F] [CharP F 2] (β : ℕ → F) (h0 : β 0 = 1) (d : ℕ)
    (hd : 1 ≤ d) : ∑ e ∈ Finset.range (d + 1), invSeq β e * β (d - e) = 0 := by
  obtain ⟨k, rfl⟩ : ∃ k, d = k + 1 := ⟨d - 1, by omega⟩
  rw [Finset.sum_range_succ, Nat.sub_self, h0, mul_one]
  conv_lhs => rw [invSeq]
  rw [Fin.sum_univ_eq_sum_range (fun e => invSeq β e * β (k + 1 - e)) (k + 1)]
  exact CharTwo.add_self_eq_zero _

/-- **The data exists** over every field of `2^192` elements. -/
theorem Membership.nonempty {F : Type} [Field F] [CharP F 2] [Fintype F]
    (hq : Fintype.card F = 2 ^ 192) : Nonempty (Membership F) := by
  obtain ⟨B⟩ := exists_cantorBasis_big hq (20 + 2) (by norm_num) (by norm_num)
  exact ⟨⟨B, Equiv.refl _, invSeq B.β, 0, by rw [invSeq], fun d hd _ =>
    invSeq_sum B.β B.zero d hd⟩⟩

end QuotientSecurity
