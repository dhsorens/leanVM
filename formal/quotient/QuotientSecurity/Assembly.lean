import QuotientSecurity.Tables

/-!
# The verifier's four claims are the model's acceptance

`Params.Accepts`, on which the security theorems are stated, speaks of polynomials. This file
states the four claims the verifier of `flock::quotient` outputs, as multilinear evaluations of
the three committed tables at the points and with the values it computes, and proves that they
hold exactly when `Params.Accepts` does for the polynomials the tables hold.
-/

set_option linter.unusedSectionVars false

open Finset Polynomial

namespace QuotientSecurity

variable {F : Type*} [Field F] [DecidableEq F] [CharP F 2] (P : Params F)

/-- The second message a quotient table holds: its first slot's first chunk and the rest, and
its other three slots. -/
noncomputable def quotientsOfTable {m : ℕ} (Y : F)
    (c : (Fin (m + 1 + 1 + 1 + 1 + 1 + 1) → Bool) → F) : Params.Quotients F where
  h₀ := sumPolyLow Y c
  hHigh := (slotPoly_low Y c).choose
  q := slotPoly Y c true false
  qGate := slotPoly Y c false true
  junk := slotPoly Y c true true

theorem quotientsOfTable_h {m : ℕ} (Y : F) (c : (Fin (m + 1 + 1 + 1 + 1 + 1 + 1) → Bool) → F)
    (hv : P.vCells = digitPoly m) :
    (quotientsOfTable Y c).h P = slotPoly Y c false false := by
  unfold Params.Quotients.h
  rw [hv]
  exact (slotPoly_low Y c).choose_spec.symm

namespace Params

/-- The denominator the verifier inverts for the copy identity, from what it received. -/
noncomputable def claimDen (α β t : F) (a : Fin 4 → F) (s : F) : F :=
  (α + P.cellAt a t 0 + β * t) * (α + P.cellAt a t 0 + β * s) + P.vCells.eval t

/-- The value of the quotient table's claim at `t`, before the table's own scale. -/
noncomputable def claimValue (α β γ t ρ : F) (a : Fin 4 → F) (s : F) : F :=
  ((1 + ρ) * ((α + P.cellAt a t 0 + β * t) + (α + P.cellAt a t 0 + β * s)
        + (P.pub γ).eval t * P.cellAt a t 0
          * ((α + P.cellAt a t 0 + β * t) * (α + P.cellAt a t 0 + β * s))) * P.vRows.eval t
      + ρ * ((α + P.cellAt a t 0 + β * t) * (α + P.cellAt a t 0 + β * s))
        * gate P.θ (P.cellAt a t 0) (P.cellAt a t 1) (P.cellAt a t 2) (P.cellAt a t 3))
    / (P.claimDen α β t a s * P.vRows.eval t)

/-- `Accepts`, with its intermediate values named. -/
theorem accepts_iff (stmt : Fin P.words → F) (g : Witness F) (R : Quotients F)
    (α β γ t : F) (a : Fin 4 → F) (s ρ : F) :
    P.Accepts stmt g R α β γ t a s ρ ↔
      (∑ j, opening ρ j * ((g j).comp rowPoly).eval t = ∑ j, opening ρ j * a j) ∧
        P.sigmaPoly.eval t = s ∧ P.claimDen α β t a s * P.vRows.eval t ≠ 0 ∧
        (1 + ρ) * ((1 + P.vCells.eval t / P.claimDen α β t a s) * (R.h P).eval t
              + P.vCells.eval t / P.claimDen α β t a s * R.q.eval t)
            + ρ * ((1 + P.vCells.eval t / P.claimDen α β t a s) * R.qGate.eval t
              + P.vCells.eval t / P.claimDen α β t a s * R.junk.eval t)
          = P.claimValue α β γ t ρ a s ∧
        R.top P = P.target stmt γ :=
  Iff.rfl

end Params

/-- **The four claims are the model's acceptance.** Let the cells be the points of a Cantor
basis, the cells' vanishing polynomial its digit, and the wiring polynomial the wiring table's.
At a challenge where no `1 + w_k(t)` vanishes and the verifier does not reject, the four claims
on the three tables, at the verifier's points and with its values, hold exactly when
`Params.Accepts` holds of the polynomials the tables hold. -/
theorem claims_iff_accepts {n N : ℕ} (B : CantorBasis F N) (hN : n + 2 ≤ N)
    (cells : (Fin (n + 2) → Bool) ≃ P.T × Fin 4) (hcells : ∀ x, P.pt (cells x) = B.point x)
    (hv : P.vCells = digitPoly (n + 2))
    (cW : (Fin (n + 1 + 1 + 1) → Bool) → F)
    (cF : (Fin (n + 2) → Bool) → F) (hσ : P.sigmaPoly = tablePoly cF)
    (cQ : (Fin (n + 2 + 1 + 1 + 1 + 1 + 1 + 1) → Bool) → F)
    (Y : F) (hY : 1 + Y ≠ 0) (hY2 : 1 + Y ^ 2 ≠ 0)
    (stmt : Fin P.words → F) (α β γ t ρ s : F) (a : Fin 4 → F)
    (ht : ∀ i : Fin (n + 2 + 1 + 1), 1 + sq^[(i : ℕ)] t ≠ 0)
    (hnz : P.claimDen α β t a s * P.vRows.eval t ≠ 0) :
    (mle cW (Fin.cons ρ (Fin.cons (ρ ^ 2) (claimPoint 2 (n + 1) t)))
          = (∑ j, Params.opening ρ j * a j) / claimScale 2 (n + 1) t ∧
        mle cF (claimPoint 0 (n + 2) t) = s / claimScale 0 (n + 2) t ∧
        mle cQ (Fin.snoc (Fin.snoc (Fin.snoc (Fin.snoc (claimPoint 0 (n + 2 + 1 + 1) t)
            (P.vCells.eval t / P.claimDen α β t a s)) ρ) (Y / (1 + Y))) (Y ^ 2 / (1 + Y ^ 2)))
          = P.claimValue α β γ t ρ a s / ((1 + Y) * (1 + Y ^ 2))
            / claimScale 0 (n + 2 + 1 + 1) t ∧
        mle cQ (sumPoint (n + 2) Y) = P.target stmt γ / ((1 + Y) * (1 + Y ^ 2)))
      ↔ P.Accepts stmt (witnessOfTable cW) (quotientsOfTable Y cQ) α β γ t a s ρ := by
  have htW : ∀ i : Fin (n + 1), 1 + sq^[(i : ℕ) + 2] t ≠ 0 := fun i =>
    ht ⟨(i : ℕ) + 2, by omega⟩
  have htF : ∀ i : Fin (n + 2), 1 + sq^[(i : ℕ) + 0] t ≠ 0 := fun i => ht ⟨(i : ℕ), by omega⟩
  have htQ : ∀ i : Fin (n + 2 + 1 + 1), 1 + sq^[(i : ℕ) + 0] t ≠ 0 := fun i => ht i
  have hYY : (1 + Y) * (1 + Y ^ 2) ≠ 0 := mul_ne_zero hY hY2
  rw [P.accepts_iff, witness_claim cW t ρ a htW, wiring_claim cF t s htF, ← hσ,
    quotient_mle cQ t _ ρ Y hY hY2 htQ, div_left_inj' (claimScale_ne_zero htQ),
    div_left_inj' hYY, sum_mle B hN Y hY hY2 cQ, div_left_inj' hYY, quotientsOfTable_h P Y cQ hv]
  have htop : (quotientsOfTable Y cQ).top P
      = ∑ x : Fin (n + 2) → Bool, (sumPolyLow Y cQ).eval (B.point x) := by
    unfold Params.Quotients.top
    rw [← Equiv.sum_comp cells]
    exact Finset.sum_congr rfl fun x _ => by rw [hcells x]; rfl
  rw [htop]
  constructor
  · rintro ⟨h1, h2, h3, h4⟩
    exact ⟨h1, h2, hnz, h3, h4⟩
  · rintro ⟨h1, h2, -, h3, h4⟩
    exact ⟨h1, h2, h3, h4⟩

end QuotientSecurity
