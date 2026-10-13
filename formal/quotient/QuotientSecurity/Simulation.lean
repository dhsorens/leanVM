import QuotientSecurity.Completeness
import QuotientSecurity.ZeroKnowledge

/-!
# The honest verifier's view is simulated

The witness's row polynomials are over the small field `K`, each committed with a mask: the rows'
vanishing polynomial times three uniform coefficients. Beyond its own challenges the verifier
sees the five values sent and whether its four claims are true. This file proves that this view
has exactly the distribution a simulator without the witness produces: four uniform values, the
wiring's public value, and the verdict the verifier's own nonzero check gives.
-/

set_option linter.unusedSectionVars false

open Polynomial Module

namespace QuotientSecurity

variable {K E : Type} [Field K] [Field E] [Algebra K E]

/-- A mask, as a polynomial. -/
noncomputable def maskPoly (m : Fin 3 → K) : K[X] := C (m 0) + C (m 1) * X + C (m 2) * X ^ 2

/-- The first message: each row polynomial plus the vanishing polynomial times its mask. -/
noncomputable def committed (gK : Fin 4 → K[X]) (van : K[X]) (m : Fin 4 → Fin 3 → K) :
    Params.Witness E :=
  fun j => (gK j + van * maskPoly (m j)).map (algebraMap K E)

theorem committed_comp_eval (gK : Fin 4 → K[X]) (van : K[X]) (m : Fin 4 → Fin 3 → K) (j : Fin 4)
    (x : E) :
    ((committed (E := E) gK van m j).comp rowPoly).eval x
      = maskedValue (aeval (rowPoly.eval x) (gK j)) (aeval (rowPoly.eval x) van) (rowPoly.eval x)
        (m j) := by
  rw [eval_comp, committed, eval_map_algebraMap, maskPoly, aeval_masked]

variable [DecidableEq E] [CharP E 2] [Fintype E] (P : Params E)

/-- The masks do not move the cells, the vanishing polynomial being zero on the rows. -/
theorem cells_committed (gK : Fin 4 → K[X]) (van : K[X])
    (hvan : ∀ x : P.T, aeval (rowPoly.eval (x : E)) van = 0) (m m' : Fin 4 → Fin 3 → K) :
    P.cells (committed gK van m) = P.cells (committed gK van m') := by
  funext i
  simp only [Params.cells, Params.cellPoly, eval_finsetSum, eval_mul]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [committed_comp_eval, committed_comp_eval, maskedValue, maskedValue, hvan i.1]
  simp

/-- The verifier's own check on what it received: the product it inverts is not zero. -/
def NotRejected (α β t : E) (a : Fin 4 → E) : Prop :=
  ((α + P.cellAt a t 0 + β * t) * (α + P.cellAt a t 0 + β * P.sigmaPoly.eval t)
    + P.vCells.eval t) * P.vRows.eval t ≠ 0

/-- **For an honest prover the verdict is the verifier's own check.** -/
theorem accepts_iff_notRejected (hE : P.Exact) (stmt : Fin P.words → E) (g : Params.Witness E)
    (α β γ t ρ : E) (hsat : P.Sat stmt (P.cells g))
    (hd : ∀ i, α + P.cells g i + β * P.pt i ≠ 0)
    (hd' : ∀ i, α + P.cells g i + β * P.pt (P.σ i) ≠ 0) :
    P.Accepts stmt g (Params.honest P g α β γ) α β γ t (Params.opened g t) (P.sigmaPoly.eval t) ρ
      ↔ NotRejected P α β t (Params.opened g t) := by
  constructor
  · intro h
    exact h.2.2.1
  · intro h
    refine Params.accepts_of_consistent stmt g _ α β γ t ρ
      (Params.honest_consistent hE stmt g α β γ hsat hd hd') ?_
    have e := Params.cellAt_opened P g t 0
    unfold NotRejected at h
    rw [e] at h
    exact h

section View

variable [Fintype K] [FiniteDimensional K E] [SampleableType K] [SampleableType E]

open Classical in
/-- What the verifier sees beyond its challenges: the four values, the wiring's value, and
whether its four claims are true of the two messages. -/
noncomputable def realView (stmt : Fin P.words → E) (gK : Fin 4 → K[X]) (van : K[X])
    (α β γ t ρ : E) : ProbComp ((Fin 4 → E) × E × Bool) :=
  (fun m : Fin 4 → Fin 3 → K =>
    let g : Params.Witness E := committed gK van m
    (Params.opened g t, P.sigmaPoly.eval t,
      decide (P.Accepts stmt g (Params.honest P g α β γ) α β γ t (Params.opened g t)
        (P.sigmaPoly.eval t) ρ))) <$> ($ᵗ (Fin 4 → Fin 3 → K))

open Classical in
/-- The simulator, which has neither the witness nor the masks. -/
noncomputable def simView (α β t : E) : ProbComp ((Fin 4 → E) × E × Bool) :=
  (fun a : Fin 4 → E => (a, P.sigmaPoly.eval t, decide (NotRejected P α β t a))) <$>
    ($ᵗ (Fin 4 → E))

/-- **Honest-verifier zero knowledge.** For challenges at which no denominator vanishes on a
cell, and whose row is outside `K` and not a root of the vanishing polynomial, the view of the
verifier has exactly the simulator's distribution. -/
theorem realView_eq_simView (h3 : finrank K E = 3) (hE : P.Exact) (stmt : Fin P.words → E)
    (gK : Fin 4 → K[X]) (van : K[X])
    (hvan : ∀ x : P.T, aeval (rowPoly.eval (x : E)) van = 0)
    (hsat : P.Sat stmt (P.cells (committed gK van 0)))
    (α β γ t ρ : E)
    (hd : ∀ i, α + P.cells (committed gK van 0) i + β * P.pt i ≠ 0)
    (hd' : ∀ i, α + P.cells (committed gK van 0) i + β * P.pt (P.σ i) ≠ 0)
    (hu : aeval (rowPoly.eval t) van ≠ 0)
    (hr : rowPoly.eval t ∉ Set.range (algebraMap K E))
    (v : (Fin 4 → E) × E × Bool) :
    Pr[= v | realView P stmt gK van α β γ t ρ] = Pr[= v | simView P α β t] := by
  classical
  have hview : realView P stmt gK van α β γ t ρ
      = (fun a : Fin 4 → E => (a, P.sigmaPoly.eval t, decide (NotRejected P α β t a))) <$>
        realValues (K := K) (fun j => aeval (rowPoly.eval t) (gK j)) (aeval (rowPoly.eval t) van)
          (rowPoly.eval t) := by
    unfold realView realValues
    rw [Functor.map_map]
    congr 1
    funext m
    have hc := cells_committed P gK van hvan m 0
    have hopen : Params.opened (committed (E := E) gK van m) t
        = fun j => maskedValue (aeval (rowPoly.eval t) (gK j)) (aeval (rowPoly.eval t) van)
          (rowPoly.eval t) (m j) := by
      funext j
      exact committed_comp_eval gK van m j t
    have hiff := accepts_iff_notRejected P hE stmt (committed gK van m) α β γ t ρ
      (by rw [hc]; exact hsat) (by rw [hc]; exact hd) (by rw [hc]; exact hd')
    simp only [Function.comp_apply]
    rw [← hopen]
    exact Prod.ext rfl (Prod.ext rfl (decide_eq_decide.mpr hiff))
  rw [hview, simView]
  exact probOutput_map_eq_of_evalSPMF_eq
    (evalSPMF_ext (realValues_uniform h3 _ hu hr)) _ v

end View

end QuotientSecurity
