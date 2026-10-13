import Mathlib
import VCVio.OracleComp.Constructions.SampleableType

/-!
# Zero knowledge of the reduction

The verifier sees four values `a_j = G_j(r)`, the wiring's value at its own challenge, which is
public, and four claims it computes from them. Each committed `G_j` is the witness's row
polynomial `g_j`, over the small field `K`, plus the rows' vanishing polynomial times a mask of
three uniform coefficients in `K`. The point `r` is in the cubic extension `E`. This file proves
that for every `r` outside `K` at which the vanishing polynomial is not zero, the four values are
exactly uniform in `E^4`, whatever the witness: a simulator samples them.
-/

open Module Polynomial IntermediateField

namespace QuotientSecurity

variable {K E : Type} [Field K] [Field E] [Algebra K E]

/-- In an extension of degree 3, an element outside the base field has a minimal polynomial of
degree 3. -/
theorem natDegree_minpoly_eq_three [FiniteDimensional K E] (h3 : finrank K E = 3) {r : E}
    (hr : r ∉ Set.range (algebraMap K E)) : (minpoly K r).natDegree = 3 := by
  have hint : IsIntegral K r := Algebra.IsIntegral.isIntegral r
  rw [← IntermediateField.adjoin.finrank hint]
  have hmul := Module.finrank_mul_finrank K K⟮r⟯ E
  rw [h3] at hmul
  have hdvd : finrank K K⟮r⟯ ∣ 3 := ⟨_, hmul.symm⟩
  rcases (Nat.dvd_prime Nat.prime_three).mp hdvd with h1 | h
  · exact absurd (IntermediateField.mem_bot.mp
      (IntermediateField.finrank_adjoin_simple_eq_one_iff.mp h1)) hr
  · exact h

/-- A value of a masked polynomial: the unmasked value `e`, plus the vanishing polynomial's value
`u` times the mask at `r`. -/
def maskedValue (e u r : E) (m : Fin 3 → K) : E := e + u * ∑ i, m i • r ^ (i : ℕ)

/-- **A mask of three coefficients covers one value.** The map from the mask to the value is a
bijection from `K^3` to `E`. -/
theorem maskedValue_bijective [Fintype K] [Fintype E] [FiniteDimensional K E]
    (h3 : finrank K E = 3) (e : E) {u r : E} (hu : u ≠ 0)
    (hr : r ∉ Set.range (algebraMap K E)) : Function.Bijective (maskedValue (K := K) e u r) := by
  classical
  have hdeg := natDegree_minpoly_eq_three h3 hr
  have hli : LinearIndependent K fun i : Fin 3 => r ^ (i : ℕ) := hdeg ▸ linearIndependent_pow r
  have hinj : Function.Injective fun m : Fin 3 → K => ∑ i, m i • r ^ (i : ℕ) := by
    intro m m' h
    have h0 : ∑ i, (m i - m' i) • r ^ (i : ℕ) = 0 := by
      simp only [sub_smul, Finset.sum_sub_distrib]
      exact sub_eq_zero.mpr h
    funext i
    exact sub_eq_zero.mp (Fintype.linearIndependent_iff.mp hli _ h0 i)
  have hcard : Fintype.card (Fin 3 → K) = Fintype.card E := by
    rw [Module.card_eq_pow_finrank (K := K) (V := E), h3]
    simp
  have hbij : Function.Bijective fun m : Fin 3 → K => ∑ i, m i • r ^ (i : ℕ) :=
    (Fintype.bijective_iff_injective_and_card _).mpr ⟨hinj, hcard⟩
  exact (AddGroup.addLeft_bijective e).comp ((mulLeft_bijective₀ u hu).comp hbij)

/-- The masked polynomial takes that value: `g + v * (m_0 + m_1 X + m_2 X^2)` at `r`. -/
theorem aeval_masked (g v : K[X]) (m : Fin 3 → K) (r : E) :
    aeval r (g + v * (C (m 0) + C (m 1) * X + C (m 2) * X ^ 2))
      = maskedValue (aeval r g) (aeval r v) r m := by
  simp only [maskedValue, map_add, map_mul, aeval_C, aeval_X, map_pow, Fin.sum_univ_three,
    Algebra.smul_def]
  simp

/-- The mask changes nothing where the vanishing polynomial vanishes: the witness is the same. -/
theorem eval_masked_of_vanishing (g v : K[X]) (m : Fin 3 → K) {x : K} (hx : v.eval x = 0) :
    (g + v * (C (m 0) + C (m 1) * X + C (m 2) * X ^ 2)).eval x = g.eval x := by
  simp [hx]

section Simulation

variable [Fintype K] [Fintype E] [FiniteDimensional K E] [SampleableType K] [SampleableType E]

/-- What the honest prover sends: the four masked values, under uniform masks. -/
noncomputable def realValues (e : Fin 4 → E) (u r : E) : ProbComp (Fin 4 → E) :=
  (fun (m : Fin 4 → Fin 3 → K) (j : Fin 4) => maskedValue (e j) u r (m j)) <$>
    ($ᵗ (Fin 4 → Fin 3 → K))

/-- **Honest-verifier zero knowledge.** For a challenge whose row `r` is outside `K` and not a
root of the rows' vanishing polynomial, the four values have exactly the distribution of four
uniform elements of `E`, whatever the witness's values `e`. -/
theorem realValues_uniform (h3 : finrank K E = 3) (e : Fin 4 → E) {u r : E} (hu : u ≠ 0)
    (hr : r ∉ Set.range (algebraMap K E)) (a : Fin 4 → E) :
    Pr[= a | realValues (K := K) e u r] = Pr[= a | $ᵗ (Fin 4 → E)] := by
  refine probOutput_map_bijective_uniform_cross _ _ ?_ a
  have hb := fun j => maskedValue_bijective (K := K) h3 (e j) hu hr
  constructor
  · intro m m' h
    funext j
    exact (hb j).injective (congrFun h j)
  · intro a
    choose m hm using fun j => (hb j).surjective (a j)
    exact ⟨m, funext hm⟩

/-- So two witnesses are indistinguishable. -/
theorem realValues_witness_independent (h3 : finrank K E = 3) (e e' : Fin 4 → E) {u r : E}
    (hu : u ≠ 0) (hr : r ∉ Set.range (algebraMap K E)) (a : Fin 4 → E) :
    Pr[= a | realValues (K := K) e u r] = Pr[= a | realValues (K := K) e' u r] := by
  rw [realValues_uniform h3 e hu hr, realValues_uniform h3 e' hu hr]

end Simulation

end QuotientSecurity
