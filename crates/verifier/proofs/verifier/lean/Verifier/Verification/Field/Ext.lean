import Verifier.Verification.Field.Base
import Verifier.Verification.Field.Ext3

/-! The extracted extension field `E` (`verifier::field`) is CompPoly's `Ext3`: its Karatsuba
product, six carry-less products folded by `y^3 = y + 1` and reduced limb by limb, is the
`Ext3` product. -/

open CoreModels Aeneas Aeneas.Std RustM CompPoly.Extension

namespace Verifier.Field

instance : Inhabited verifier.field.E := ⟨⟨0#u64, 0#u64, 0#u64⟩⟩

/-- An `E` as the `Ext3` element `c0 + c1 y + c2 y^2` its limbs denote. -/
def toExt3 (x : verifier.field.E) : BF64.Ext3 :=
  Ext.ofFn fun i => if i.val = 0 then BF64.ofBitVec x.c0.bv
    else if i.val = 1 then BF64.ofBitVec x.c1.bv else BF64.ofBitVec x.c2.bv

/-- The `E` whose limbs are an `Ext3` element's coefficients. -/
def ofExt3 (y : BF64.Ext3) : verifier.field.E :=
  { c0 := ⟨(c y 0).toBitVec⟩, c1 := ⟨(c y 1).toBitVec⟩, c2 := ⟨(c y 2).toBitVec⟩ }

theorem c_toExt3 (x : verifier.field.E) :
    c (toExt3 x) 0 = BF64.ofBitVec x.c0.bv ∧ c (toExt3 x) 1 = BF64.ofBitVec x.c1.bv ∧
      c (toExt3 x) 2 = BF64.ofBitVec x.c2.bv := by
  refine ⟨?_, ?_, ?_⟩ <;> rw [c_lt _ _ (by decide)] <;> simp only [toExt3, Ext.coeff_ofFn] <;> rfl

theorem reduce_clmul (u v : BitVec 64) :
    BF64.reduce (BinaryField.carryLessMul (w := 128) u v) =
      (BF64.ofBitVec u * BF64.ofBitVec v).toBitVec := rfl

theorem ofBitVec_xor (u v : BitVec 64) :
    BF64.ofBitVec (u ^^^ v) = BF64.ofBitVec u + BF64.ofBitVec v := rfl

/-- `reduce_xor` at the width the extracted `u128` carries. -/
theorem reduce_xor_u128 (x y : BitVec UScalarTy.U128.numBits) :
    BF64.reduce (x ^^^ y) = BF64.reduce x ^^^ BF64.reduce y := reduce_xor x y

/-- `ofBitVec_xor` at the width the extracted `u64` carries. -/
theorem ofBitVec_xor_u64 (u v : BitVec UScalarTy.U64.numBits) :
    BF64.ofBitVec (u ^^^ v) = BF64.ofBitVec u + BF64.ofBitVec v := rfl

theorem toBitVec_xor (p q : BF64) : p.toBitVec ^^^ q.toBitVec = (p + q).toBitVec := rfl

/-- The extracted product of `E` is `Ext3` multiplication. -/
theorem E_mul_ok (a b : verifier.field.E) :
    verifier.field.E.Insts.CoreOpsArithMulEE.mul a b = ok (ofExt3 (toExt3 a * toExt3 b)) := by
  obtain ⟨m0, m1, m2⟩ := mul_c (toExt3 a) (toExt3 b)
  obtain ⟨a0, a1, a2⟩ := c_toExt3 a
  obtain ⟨b0, b1, b2⟩ := c_toExt3 b
  simp only [verifier.field.E.Insts.CoreOpsArithMulEE.mul, clmul_ok, reduce_ok, lift, bind_ok,
    verifier.field.E.new, ofExt3, m0, m1, m2, a0, a1, a2, b0, b1, b2]
  simp only [U128.bv, U64.bv]
  simp only [UScalar.bv_xor, reduce_xor_u128, reduce_clmul, ofBitVec_xor_u64, toBitVec_xor]
  generalize BF64.ofBitVec a.c0.bv = A0
  generalize BF64.ofBitVec a.c1.bv = A1
  generalize BF64.ofBitVec a.c2.bv = A2
  generalize BF64.ofBitVec b.c0.bv = B0
  generalize BF64.ofBitVec b.c1.bv = B1
  generalize BF64.ofBitVec b.c2.bv = B2
  have h0 : A0 * B0 + ((A1 + A2) * (B1 + B2) + A1 * B1 + A2 * B2) = A0 * B0 + A1 * B2 + A2 * B1 := by
    grind
  have h1 : (A0 + A1) * (B0 + B1) + A0 * B0 + A1 * B1 + ((A1 + A2) * (B1 + B2) + A1 * B1 + A2 * B2) +
      A2 * B2 = A0 * B1 + A1 * B0 + A1 * B2 + A2 * B1 + A2 * B2 := by
    grind
  have h2 : (A0 + A2) * (B0 + B2) + A0 * B0 + A2 * B2 + A1 * B1 + A2 * B2 =
      A0 * B2 + A1 * B1 + A2 * B0 + A2 * B2 := by
    grind
  rw [h0, h1, h2]
end Verifier.Field

namespace Verifier.Field

/-- Two `Ext3`s with the same three coefficients are equal. -/
theorem ext3_eq {x y : BF64.Ext3} (h0 : c x 0 = c y 0) (h1 : c x 1 = c y 1) (h2 : c x 2 = c y 2) :
    x = y := by
  apply Ext.ext
  intro i
  rw [← Ext.coeffNat_coe, ← Ext.coeffNat_coe]
  have hi : (i : ℕ) < 3 := i.isLt
  interval_cases h : (i : ℕ)
  · exact h0
  · exact h1
  · exact h2

theorem toExt3_ofExt3 (y : BF64.Ext3) : toExt3 (ofExt3 y) = y := by
  obtain ⟨a0, a1, a2⟩ := c_toExt3 (ofExt3 y)
  exact ext3_eq (a0.trans rfl) (a1.trans rfl) (a2.trans rfl)

theorem c_add (x y : BF64.Ext3) (i : ℕ) (h : i < 3) : c (x + y) i = c x i + c y i := by
  rw [c_lt _ _ h, c_lt _ _ h, c_lt _ _ h, Ext.coeff_add]

/-- The extracted sum of `E` is `Ext3` addition. -/
theorem E_add_ok (a b : verifier.field.E) :
    verifier.field.E.Insts.CoreOpsArithAddEE.add a b = ok (ofExt3 (toExt3 a + toExt3 b)) := by
  obtain ⟨a0, a1, a2⟩ := c_toExt3 a
  obtain ⟨b0, b1, b2⟩ := c_toExt3 b
  simp only [verifier.field.E.Insts.CoreOpsArithAddEE.add, lift, bind_ok, verifier.field.E.new, ofExt3,
    c_add _ _ 0 (by decide), c_add _ _ 1 (by decide), c_add _ _ 2 (by decide), a0, a1, a2, b0, b1, b2]
  rfl

/-- The extracted `+=` of `E` is `Ext3` addition. -/
theorem E_add_assign_ok (a b : verifier.field.E) :
    verifier.field.E.Insts.CoreOpsArithAddAssignE.add_assign a b = ok (ofExt3 (toExt3 a + toExt3 b)) :=
  E_add_ok a b

theorem c_smul (k : BF64) (x : BF64.Ext3) (i : ℕ) (h : i < 3) : c (k • x) i = k * c x i := by
  rw [c_lt _ _ h, c_lt _ _ h, Ext.coeff_smul]

theorem base_mul_ok (a b : Std.U64) :
    verifier.field.base_mul a b = ok ⟨(BF64.ofBitVec a.bv * BF64.ofBitVec b.bv).toBitVec⟩ := by
  simp [verifier.field.base_mul, clmul_ok, reduce_ok, BF64.toBitVec_mul]

/-- The extracted product of an `E` by a `K` scales each limb: `Ext3`'s scalar multiplication. -/
theorem E_mulK_ok (a : verifier.field.E) (k : verifier.field.K) :
    verifier.field.E.Insts.CoreOpsArithMulKE.mul a k = ok (ofExt3 (toBF64 k • toExt3 a)) := by
  obtain ⟨a0, a1, a2⟩ := c_toExt3 a
  simp only [verifier.field.E.Insts.CoreOpsArithMulKE.mul, base_mul_ok, bind_ok, verifier.field.E.new, ofExt3,
    c_smul _ _ 0 (by decide), c_smul _ _ 1 (by decide), c_smul _ _ 2 (by decide), a0, a1, a2, toBF64]
  simp only [mul_comm (BF64.ofBitVec k.bv)]

theorem ZERO_ok : verifier.field.ZERO = ok (ofExt3 0) := by
  simp only [verifier.field.ZERO, verifier.field.E.new, ofExt3]
  rfl

theorem ONE_ok : verifier.field.ONE = ok (ofExt3 1) := by
  simp only [verifier.field.ONE, verifier.field.E.new, ofExt3]
  rfl

end Verifier.Field
