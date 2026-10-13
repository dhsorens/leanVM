import QuotientSecurity.Cantor
import QuotientSecurity.Protocol

/-!
# The four claims, on tables

The verifier's claims are multilinear evaluations of committed tables. This file states each
claim on its table, at the point and with the value the verifier computes, and proves it
equivalent to the statement about polynomials that `Params.Accepts` makes. The tables' entries
are in the large field, which covers tables over the small one.
-/

set_option linter.unusedSectionVars false

open Finset Polynomial

namespace QuotientSecurity

variable {F : Type*} [Field F] [CharP F 2]

/-- The point of a claim, built from `t`: `w_k(t) / (1 + w_k(t))`, the digits from `first` on. -/
noncomputable def claimPoint (first m : ℕ) (t : F) : Fin m → F :=
  fun k => sq^[(k : ℕ) + first] t / (1 + sq^[(k : ℕ) + first] t)

/-- The scale of such a claim: the product of the `1 + w_k(t)`. -/
noncomputable def claimScale (first m : ℕ) (t : F) : F :=
  ∏ k : Fin m, (1 + sq^[(k : ℕ) + first] t)

/-- A first coordinate chooses between a table's two halves, like a last one. -/
theorem mle_cons {m : ℕ} (c : (Fin (m + 1) → Bool) → F) (e : F) (u : Fin m → F) :
    mle c (Fin.cons e u)
      = (1 + e) * mle (fun b => c (Fin.cons false b)) u
        + e * mle (fun b => c (Fin.cons true b)) u := by
  unfold mle
  rw [← Equiv.sum_comp (Fin.consEquiv fun _ : Fin (m + 1) => Bool), Fintype.sum_prod_type]
  simp only [Fin.consEquiv, Equiv.coe_fn_mk, Fin.prod_univ_succ, Fin.cons_zero, Fin.cons_succ,
    Fintype.sum_bool, Bool.false_eq_true, ite_false, ite_true]
  rw [Finset.mul_sum, Finset.mul_sum, add_comm]
  congr 1 <;> exact Finset.sum_congr rfl fun b _ => by ring

/-- A table's polynomial, by its last digit. -/
theorem tablePoly_snoc {m : ℕ} (c : (Fin (m + 1) → Bool) → F) :
    tablePoly c = tablePoly (fun b => c (Fin.snoc b false))
      + digitPoly m * tablePoly (fun b => c (Fin.snoc b true)) := by
  have hterm : ∀ (b : Fin m → Bool) (x : Bool),
      (∏ k : Fin (m + 1), (if (Fin.snoc b x : Fin (m + 1) → Bool) k then
          (digitPoly (k : ℕ) : F[X]) else 1))
        = (∏ k : Fin m, (if b k then (digitPoly (k : ℕ) : F[X]) else 1))
          * (if x then digitPoly m else 1) := by
    intro b x
    rw [Fin.prod_univ_castSucc]
    simp only [Fin.snoc_castSucc, Fin.snoc_last, Fin.val_last, Fin.val_castSucc]
  unfold tablePoly
  rw [← Equiv.sum_comp (Fin.snocEquiv fun _ : Fin (m + 1) => Bool), Fintype.sum_prod_type,
    Fintype.sum_bool]
  have e : ∀ (x : Bool) (b : Fin m → Bool),
      (Fin.snocEquiv fun _ : Fin (m + 1) => Bool) (x, b) = Fin.snoc b x := fun _ _ => rfl
  simp only [e, hterm, Bool.false_eq_true, ite_false, ite_true, mul_one]
  rw [Finset.mul_sum, add_comm]
  congr 1
  exact Finset.sum_congr rfl fun b _ => by ring

/-- The row of a point is its second digit. -/
theorem rowPoly_eval (t : F) : (rowPoly : F[X]).eval t = sq^[2] t := by
  have two : (2 : F) = 0 := CharTwo.two_eq_zero
  show (rowPoly : F[X]).eval t = sq (sq t)
  simp only [rowPoly, eval_add, eval_pow, eval_X]
  unfold sq
  linear_combination (-(t ^ 3) - t ^ 2) * two

/-- A claim at digits from the second on is an evaluation at the row. -/
theorem mle_claimPoint_two {m : ℕ} (c : (Fin m → Bool) → F) (t : F)
    (ht : ∀ k : Fin m, 1 + sq^[(k : ℕ) + 2] t ≠ 0) :
    mle c (claimPoint 2 m t) = ((tablePoly c).comp rowPoly).eval t / claimScale 2 m t := by
  refine (mle_eq_digitsEval_div c (fun k : Fin m => sq^[(k : ℕ) + 2] t) ht).trans ?_
  rw [eval_comp, tablePoly_eval, rowPoly_eval]
  unfold claimScale
  congr 2

/-- A claim at every digit is an evaluation. -/
theorem mle_claimPoint_zero {m : ℕ} (c : (Fin m → Bool) → F) (t : F)
    (ht : ∀ k : Fin m, 1 + sq^[(k : ℕ)] t ≠ 0) :
    mle c (claimPoint 0 m t) = (tablePoly c).eval t / claimScale 0 m t :=
  mle_eq_tablePoly_eval c t ht

/-- The two coordinates of the extension: with `y₀ = Y / (1 + Y)` and `y₁ = Y^2 / (1 + Y^2)`,
four values enter as `(1, Y, Y^2, Y^3)` over `(1 + Y)(1 + Y^2)`. -/
theorem limbs_combine {Y : F} (hY : 1 + Y ≠ 0) (hY2 : 1 + Y ^ 2 ≠ 0) (a b c d : F) :
    (1 + Y ^ 2 / (1 + Y ^ 2)) * ((1 + Y / (1 + Y)) * a + Y / (1 + Y) * b)
        + Y ^ 2 / (1 + Y ^ 2) * ((1 + Y / (1 + Y)) * c + Y / (1 + Y) * d)
      = (a + Y * b + Y ^ 2 * c + Y ^ 3 * d) / ((1 + Y) * (1 + Y ^ 2)) := by
  have h0 : 1 + Y / (1 + Y) = 1 / (1 + Y) := by
    rw [eq_div_iff hY, add_mul, one_mul, div_mul_cancel₀ _ hY, add_assoc,
      CharTwo.add_self_eq_zero, add_zero]
  have h1 : 1 + Y ^ 2 / (1 + Y ^ 2) = 1 / (1 + Y ^ 2) := by
    rw [eq_div_iff hY2, add_mul, one_mul, div_mul_cancel₀ _ hY2, add_assoc,
      CharTwo.add_self_eq_zero, add_zero]
  rw [h0, h1]
  field_simp
  ring

theorem claimScale_ne_zero {first m : ℕ} {t : F}
    (ht : ∀ k : Fin m, 1 + sq^[(k : ℕ) + first] t ≠ 0) : claimScale first m t ≠ 0 :=
  Finset.prod_ne_zero_iff.mpr fun k _ => ht k

/-! ## The wiring claim -/

/-- **The claim on the wiring table** is that the wiring polynomial takes the value sent. -/
theorem wiring_claim {m : ℕ} (c : (Fin m → Bool) → F) (t s : F)
    (ht : ∀ k : Fin m, 1 + sq^[(k : ℕ) + 0] t ≠ 0) :
    mle c (claimPoint 0 m t) = s / claimScale 0 m t ↔ (tablePoly c).eval t = s := by
  rw [mle_claimPoint_zero c t ht, div_left_inj' (claimScale_ne_zero ht)]

/-! ## The witness claim -/

/-- The four row polynomials a witness table holds: its first two coordinates choose one. -/
noncomputable def witnessOfTable {k : ℕ} (c : (Fin (k + 1 + 1) → Bool) → F) : Params.Witness F :=
  ![tablePoly fun b => c (Fin.cons false (Fin.cons false b)),
    tablePoly fun b => c (Fin.cons true (Fin.cons false b)),
    tablePoly fun b => c (Fin.cons false (Fin.cons true b)),
    tablePoly fun b => c (Fin.cons true (Fin.cons true b))]

/-- The witness table's claim, as its polynomials' values at the row. -/
theorem witness_mle {k : ℕ} (c : (Fin (k + 1 + 1) → Bool) → F) (t ρ : F)
    (ht : ∀ i : Fin k, 1 + sq^[(i : ℕ) + 2] t ≠ 0) :
    mle c (Fin.cons ρ (Fin.cons (ρ ^ 2) (claimPoint 2 k t)))
      = (∑ j, Params.opening ρ j * ((witnessOfTable c j).comp rowPoly).eval t)
        / claimScale 2 k t := by
  rw [mle_cons, mle_cons, mle_cons]
  simp only [mle_claimPoint_two _ t ht, Fin.sum_univ_four, Params.opening, witnessOfTable,
    Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val]
  ring

/-- **The claim on the witness table** is the opening of its four polynomials at the row, under
the weights of `ρ`. -/
theorem witness_claim {k : ℕ} (c : (Fin (k + 1 + 1) → Bool) → F) (t ρ : F) (a : Fin 4 → F)
    (ht : ∀ i : Fin k, 1 + sq^[(i : ℕ) + 2] t ≠ 0) :
    mle c (Fin.cons ρ (Fin.cons (ρ ^ 2) (claimPoint 2 k t)))
        = (∑ j, Params.opening ρ j * a j) / claimScale 2 k t
      ↔ ∑ j, Params.opening ρ j * ((witnessOfTable c j).comp rowPoly).eval t
        = ∑ j, Params.opening ρ j * a j := by
  rw [witness_mle c t ρ ht, div_left_inj' (claimScale_ne_zero ht)]

/-! ## The quotient table -/

/-- One of the sixteen tables the last four coordinates of the quotient table choose from. -/
def subTable {k : ℕ} (c : (Fin (k + 1 + 1 + 1 + 1) → Bool) → F) (κ τ e₀ e₁ : Bool) :
    (Fin k → Bool) → F :=
  fun b => c (Fin.snoc (Fin.snoc (Fin.snoc (Fin.snoc b κ) τ) e₀) e₁)

/-- The polynomial of a slot of the quotient table: its four limbs on `1, Y, Y^2, Y^3`. -/
noncomputable def slotPoly {k : ℕ} (Y : F) (c : (Fin (k + 1 + 1 + 1 + 1) → Bool) → F)
    (κ τ : Bool) : F[X] :=
  tablePoly (subTable c κ τ false false) + C Y * tablePoly (subTable c κ τ true false)
    + C (Y ^ 2) * tablePoly (subTable c κ τ false true)
    + C (Y ^ 3) * tablePoly (subTable c κ τ true true)

/-- The quotient table's claim at `t`, as its four slots' values. -/
theorem quotient_mle {k : ℕ} (c : (Fin (k + 1 + 1 + 1 + 1) → Bool) → F) (t e ρ Y : F)
    (hY : 1 + Y ≠ 0) (hY2 : 1 + Y ^ 2 ≠ 0) (ht : ∀ i : Fin k, 1 + sq^[(i : ℕ) + 0] t ≠ 0) :
    mle c (Fin.snoc (Fin.snoc (Fin.snoc (Fin.snoc (claimPoint 0 k t) e) ρ) (Y / (1 + Y)))
        (Y ^ 2 / (1 + Y ^ 2)))
      = ((1 + ρ) * ((1 + e) * (slotPoly Y c false false).eval t
            + e * (slotPoly Y c true false).eval t)
          + ρ * ((1 + e) * (slotPoly Y c false true).eval t
            + e * (slotPoly Y c true true).eval t))
        / ((1 + Y) * (1 + Y ^ 2)) / claimScale 0 k t := by
  have hS := claimScale_ne_zero ht
  have hsub : ∀ κ τ e₀ e₁, mle (subTable c κ τ e₀ e₁) (claimPoint 0 k t)
      = (tablePoly (subTable c κ τ e₀ e₁)).eval t / claimScale 0 k t := fun κ τ e₀ e₁ =>
    mle_claimPoint_zero _ t ht
  rw [mle_snoc, mle_snoc, mle_snoc, mle_snoc, mle_snoc, mle_snoc, mle_snoc]
  rw [mle_snoc, mle_snoc, mle_snoc, mle_snoc, mle_snoc, mle_snoc, mle_snoc, mle_snoc]
  change (1 + Y ^ 2 / (1 + Y ^ 2)) * ((1 + Y / (1 + Y)) *
        ((1 + ρ) * ((1 + e) * mle (subTable c false false false false) _
            + e * mle (subTable c true false false false) _)
          + ρ * ((1 + e) * mle (subTable c false true false false) _
            + e * mle (subTable c true true false false) _))
      + Y / (1 + Y) *
        ((1 + ρ) * ((1 + e) * mle (subTable c false false true false) _
            + e * mle (subTable c true false true false) _)
          + ρ * ((1 + e) * mle (subTable c false true true false) _
            + e * mle (subTable c true true true false) _)))
    + Y ^ 2 / (1 + Y ^ 2) * ((1 + Y / (1 + Y)) *
        ((1 + ρ) * ((1 + e) * mle (subTable c false false false true) _
            + e * mle (subTable c true false false true) _)
          + ρ * ((1 + e) * mle (subTable c false true false true) _
            + e * mle (subTable c true true false true) _))
      + Y / (1 + Y) *
        ((1 + ρ) * ((1 + e) * mle (subTable c false false true true) _
            + e * mle (subTable c true false true true) _)
          + ρ * ((1 + e) * mle (subTable c false true true true) _
            + e * mle (subTable c true true true true) _))) = _
  rw [limbs_combine hY hY2]
  simp only [hsub, slotPoly, eval_add, eval_mul, eval_C]
  field_simp
  ring

end QuotientSecurity
