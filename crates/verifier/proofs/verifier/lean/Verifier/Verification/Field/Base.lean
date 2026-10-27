import Verifier.Extraction
import Verifier.Verification.Field.Bits

/-! The extracted base field `K` (`verifier::field`) is CompPoly's `BF64`: each kernel returns
the bit-vector function of `Field/Bits.lean`, so the product of two `K`s is their `BF64` product. -/

open CoreModels Aeneas Aeneas.Std RustM

namespace Verifier.Field

/-- A `K` as the CompPoly field element its word denotes. -/
def toBF64 (x : verifier.field.K) : BF64 := BF64.ofBitVec x.bv

theorem clmul_low_ok (a b : Std.U64) : verifier.field.clmul_low a b = ok ⟨clmulLow a.bv b.bv⟩ := by
  unfold verifier.field.clmul_low verifier.field.clmul_low.M1 verifier.field.clmul_low.M2
    verifier.field.clmul_low.M3 verifier.field.clmul_low.M0
  simp only [lift, bind_ok, HShiftLeft.hShiftLeft, UScalar.shiftLeft_IScalar, UScalar.shiftLeft,
    CoreModels.core.num.U64.wrapping_mul, CoreModels.rust_primitives.arithmetic.wrapping_mul_u64]
  simp [clmulLow]
  rw [UScalar.eq_equiv_bv_eq]
  simp

theorem clmul_ok (a b : Std.U64) :
    verifier.field.clmul a b = ok ⟨BinaryField.carryLessMul (w := 128) a.bv b.bv⟩ := by
  unfold verifier.field.clmul
  simp only [clmul_low_ok, CoreModels.core.num.U64.reverse_bits, lift, bind_ok, HShiftLeft.hShiftLeft,
    HShiftRight.hShiftRight, UScalar.shiftLeft_IScalar, UScalar.shiftRight_IScalar, UScalar.shiftLeft,
    UScalar.shiftRight]
  simp [← clmul_eq, clmul]
  rw [UScalar.eq_equiv_bv_eq]
  simp

theorem reduce_ok (p : Std.U128) : verifier.field.reduce p = ok ⟨BF64.reduce p.bv⟩ := by
  unfold verifier.field.reduce
  simp only [lift, bind_ok, HShiftLeft.hShiftLeft, HShiftRight.hShiftRight, UScalar.shiftLeft_IScalar,
    UScalar.shiftRight_IScalar, UScalar.shiftLeft, UScalar.shiftRight]
  simp [← reduce_eq, reduce]
  rw [UScalar.eq_equiv_bv_eq]
  simp

/-- The extracted product of `K` is `BF64` multiplication. -/
theorem mul_ok (a b : verifier.field.K) :
    verifier.field.K.Insts.CoreOpsArithMulKK.mul a b = ok ⟨(toBF64 a * toBF64 b).toBitVec⟩ := by
  simp [verifier.field.K.Insts.CoreOpsArithMulKK.mul, verifier.field.base_mul, clmul_ok, reduce_ok,
    toBF64, BF64.toBitVec_mul]

end Verifier.Field
