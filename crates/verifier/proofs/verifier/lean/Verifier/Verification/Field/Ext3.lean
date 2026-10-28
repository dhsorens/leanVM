import CompPoly.Fields.Binary.BF64.Ext3

/-! CompPoly's cubic extension `Ext3 = BF64[y]/(y^3 + y + 1)` by coefficients: multiplying by `y`,
the reduced monomials `y^0..y^4`, and so the three coefficients of a product. -/

namespace Verifier.Field

open CompPoly.Extension BF64

@[simp] theorem bf64_neg (a : BF64) : -a = a := rfl

/-- Coefficient `i` of an `Ext3`, zero past the degree. -/
abbrev c (x : Ext3) (i : ℕ) : BF64 := Ext.coeffNat x i

theorem c_lt (x : Ext3) (i : ℕ) (h : i < 3) : c x i = Ext.coeff x ⟨i, h⟩ := Ext.coeffNat_of_lt x h

theorem shift_c (e : Ext3) :
    c (Ext.shiftReduce e) 0 = c e 2 ∧ c (Ext.shiftReduce e) 1 = c e 0 + c e 2 ∧
      c (Ext.shiftReduce e) 2 = c e 1 := by
  refine ⟨?_, ?_, ?_⟩ <;>
  · rw [c_lt _ _ (by decide), Ext.coeff_shiftReduce]
    simp [ExtensionParams.lowerCoeff, ext3Params]
    rfl

theorem one_c : c 1 0 = 1 ∧ c 1 1 = 0 ∧ c 1 2 = 0 := by
  refine ⟨?_, ?_, ?_⟩ <;> rfl

theorem mono_c (k : ℕ) (hk : k ≤ 4) :
    c (Ext.monomialMod (P := ext3Params) k) 0 = [1, 0, 0, 1, 0][k]! ∧
    c (Ext.monomialMod (P := ext3Params) k) 1 = [0, 1, 0, 1, 1][k]! ∧
    c (Ext.monomialMod (P := ext3Params) k) 2 = [0, 0, 1, 0, 1][k]! := by
  have s := shift_c
  have o := one_c
  interval_cases k <;>
  simp only [Ext.monomialMod, Function.iterate_succ_apply', Function.iterate_zero, id_eq, s, o] <;>
  simp

theorem sum3 (f : ℕ → BF64) : ∑ i : Fin ext3Params.d, f i = f 0 + f 1 + f 2 := by
  rw [Fin.sum_univ_eq_sum_range f, ext3Params_d, Finset.sum_range_succ, Finset.sum_range_succ,
    Finset.sum_range_one]

theorem sum33 (g : ℕ → ℕ → BF64) :
    ∑ i : Fin ext3Params.d, ∑ j : Fin ext3Params.d, g i j =
      g 0 0 + g 0 1 + g 0 2 + (g 1 0 + g 1 1 + g 1 2) + (g 2 0 + g 2 1 + g 2 2) := by
  rw [sum3 fun n => ∑ j : Fin ext3Params.d, g n j]
  simp only [sum3]

theorem mul_coeffNat (x y : Ext3) (m : ℕ) (hm : m < 3) :
    let g := fun a b => c x a * c y b * c (Ext.monomialMod (P := ext3Params) (a + b)) m
    c (x * y) m = g 0 0 + g 0 1 + g 0 2 + (g 1 0 + g 1 1 + g 1 2) + (g 2 0 + g 2 1 + g 2 2) := by
  intro g
  rw [c_lt _ _ hm, Ext.coeff_mul]
  simp only [← Ext.coeffNat_coe]
  exact sum33 g

theorem mul_c (x y : Ext3) :
    c (x * y) 0 = c x 0 * c y 0 + c x 1 * c y 2 + c x 2 * c y 1 ∧
    c (x * y) 1 = c x 0 * c y 1 + c x 1 * c y 0 + c x 1 * c y 2 + c x 2 * c y 1 + c x 2 * c y 2 ∧
    c (x * y) 2 = c x 0 * c y 2 + c x 1 * c y 1 + c x 2 * c y 0 + c x 2 * c y 2 := by
  have m := fun k hk => mono_c k hk
  obtain ⟨a0, a1, a2⟩ := m 0 (by decide); obtain ⟨b0, b1, b2⟩ := m 1 (by decide)
  obtain ⟨d0, d1, d2⟩ := m 2 (by decide); obtain ⟨e0, e1, e2⟩ := m 3 (by decide)
  obtain ⟨f0, f1, f2⟩ := m 4 (by decide)
  simp only [List.getElem!_cons_zero, List.getElem!_cons_succ] at *
  refine ⟨?_, ?_, ?_⟩ <;>
  · rw [mul_coeffNat _ _ _ (by decide)]
    simp only [Nat.add_zero, Nat.zero_add, show (1 : ℕ) + 1 = 2 from rfl, show (1 : ℕ) + 2 = 3 from rfl,
      show (2 : ℕ) + 2 = 4 from rfl]
    simp only [c] at a0 a1 a2 b0 b1 b2 d0 d1 d2 e0 e1 e2 f0 f1 f2
    simp only [a0, a1, a2, b0, b1, b2, d0, d1, d2, e0, e1, e2, f0, f1, f2]
    ring

end Verifier.Field
