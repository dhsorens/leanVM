import Verifier.Verification.Field.Base
import Verifier.Verification.Field.Ext3

/-! The extracted extension field `E` (`verifier::field`) is CompPoly's `Ext3`: its Karatsuba
product, six carry-less products folded by `y^3 = y + 1` and reduced limb by limb, is the
`Ext3` product. -/

open CoreModels Aeneas Aeneas.Std RustM CompPoly.Extension

namespace Verifier.Field

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
