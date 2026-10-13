import Mathlib

/-!
# A multilinear claim is a univariate evaluation

A table of `2^m` entries holds the coefficients `c` of a polynomial in the basis of products of
digits `w_k`. Its multilinear extension at the point `u_k = w_k / (1 + w_k)` is the polynomial's
value divided by the product of the `1 + w_k`. This is the identity that turns the verifier's
claims on tables into the evaluations the security proofs speak of.
-/

open Finset

namespace QuotientSecurity

variable {F : Type*} [Field F] [CharP F 2] {m : ℕ}

/-- The multilinear extension of a table at `u`: entry `b` weighs the product of `u_k` where
`b_k` is set and of `1 + u_k` elsewhere. -/
def mle (c : (Fin m → Bool) → F) (u : Fin m → F) : F :=
  ∑ b, c b * ∏ k, (if b k then u k else 1 + u k)

/-- The polynomial of coefficients `c` at a point whose digits are `w`. -/
def digitsEval (c : (Fin m → Bool) → F) (w : Fin m → F) : F :=
  ∑ b, c b * ∏ k, (if b k then w k else 1)

/-- **A claim is an evaluation.** -/
theorem mle_eq_digitsEval_div (c : (Fin m → Bool) → F) (w : Fin m → F)
    (hw : ∀ k, 1 + w k ≠ 0) :
    mle c (fun k => w k / (1 + w k)) = digitsEval c w / ∏ k, (1 + w k) := by
  unfold mle digitsEval
  rw [Finset.sum_div]
  refine Finset.sum_congr rfl fun b _ => ?_
  rw [mul_div_assoc, ← Finset.prod_div_distrib]
  congr 1
  refine Finset.prod_congr rfl fun k _ => ?_
  split_ifs
  · rfl
  · rw [eq_div_iff (hw k), add_mul, one_mul, div_mul_cancel₀ _ (hw k), add_assoc,
      CharTwo.add_self_eq_zero, add_zero]

/-- At the point of all ones, the extension is the last entry: the top coefficient. -/
theorem mle_ones (c : (Fin m → Bool) → F) : mle c (fun _ => 1) = c fun _ => true := by
  unfold mle
  rw [Finset.sum_eq_single fun _ => true]
  · simp
  · intro b _ hb
    obtain ⟨k, hk⟩ : ∃ k, b k = false := by
      by_contra h
      push_neg at h
      exact hb (funext fun k => by simpa using h k)
    rw [Finset.prod_eq_zero (Finset.mem_univ k), mul_zero]
    simp [hk, CharTwo.add_self_eq_zero]
  · intro h; exact absurd (Finset.mem_univ _) h

end QuotientSecurity
