import Verifier.Verification.Field.Bits

/-! The base field by bits, as `Scaled` (`verifier::field`) reads it: `times_x` multiplies by `x`
(`ofBitVec_timesX`), and a word is the sum over its six-bit windows of each window's bits weighed by
the powers of `x` they stand for (`sum_win`). -/

namespace Verifier.Field

open BinaryField

/-- `x` in `BF64`. -/
def X : BF64 := BF64.ofBitVec 2#64

/-- `Scaled::new`'s `times_x`: a word shifted up by one, its overflow past `x^63` reduced. -/
def timesX (v : BitVec 64) : BitVec 64 := v <<< 1 ^^^ ((0#64 - (v >>> 63)) &&& 0x1B#64)

set_option maxRecDepth 100000 in
set_option maxHeartbeats 0 in
theorem timesX_eq (v : BitVec 64) : timesX v = BF64.reduce (carryLessMul (w := 128) 2#64 v) := by
  simp only [timesX, BF64.reduce, BF64.foldStep, BF64.highHalf, BF64.lowHalf, BF64.reductionConstant,
    carryLessMul_eq_range, zeroExtendTo, List.range, List.range.loop, List.foldl]
  bv_decide (config := { timeout := 3600 })

theorem ofBitVec_timesX (v : BitVec 64) : BF64.ofBitVec (timesX v) = X * BF64.ofBitVec v := by
  rw [timesX_eq]; rfl

/-- A word is the sum of the powers of `x` its set bits stand for. -/
theorem ofBitVec_eq_sum (c : BitVec 64) :
    BF64.ofBitVec c = ∑ i ∈ Finset.range 64, if c.getLsbD i then X ^ i else 0 := by
  apply BF64.toQuot_injective
  have hX : BF64.toQuot X = AdjoinRoot.mk BF64.basePoly Polynomial.X := by
    rw [BF64.toQuot, BF64.toPolyBF64, X, BF64.toBitVec_ofBitVec,
      show (2#64 : BitVec 64) = 1 <<< 1 from rfl, toPoly_one_shiftLeft 1 (by omega), pow_one]
  let q : BF64 →+ BF64.BF64Quot := AddMonoidHom.mk' BF64.toQuot BF64.toQuot_add
  rw [show BF64.toQuot (∑ i ∈ Finset.range 64, if c.getLsbD i then X ^ i else 0) =
    q (∑ i ∈ Finset.range 64, if c.getLsbD i then X ^ i else 0) from rfl, map_sum]
  simp only [q, AddMonoidHom.mk'_apply, apply_ite BF64.toQuot, BF64.toQuot_npow, hX, BF64.toQuot_zero]
  rw [BF64.toQuot, BF64.toPolyBF64, BF64.toBitVec_ofBitVec, toPoly, map_sum, Finset.sum_range
    (fun i => if c.getLsbD i then AdjoinRoot.mk BF64.basePoly Polynomial.X ^ i else 0)]
  refine Finset.sum_congr rfl fun i _ => ?_
  simp [apply_ite (AdjoinRoot.mk BF64.basePoly), BitVec.getLsb, BitVec.getElem_eq_testBit_toNat]

/-- Window `j`'s value `n`, its bits weighed by the powers of `x` they stand for. -/
def win (j n : ℕ) : BF64 := ∑ b ∈ Finset.range 6, if n.testBit b then X ^ (6 * j + b) else 0

theorem sum_range_six_mul {M : Type} [AddCommMonoid M] (f : ℕ → M) (m : ℕ) :
    ∑ k ∈ Finset.range (6 * m), f k = ∑ j ∈ Finset.range m, ∑ b ∈ Finset.range 6, f (6 * j + b) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [Nat.mul_succ, Finset.sum_range_add, ih, Finset.sum_range_succ (fun j => ∑ b ∈ Finset.range 6, f (6 * j + b))]

/-- A word is the sum of its eleven six-bit windows, the last holding its top four bits. -/
theorem sum_win (c : BitVec 64) :
    ∑ j ∈ Finset.range 11, win j (c.toNat >>> (6 * j) % 64) = BF64.ofBitVec c := by
  rw [ofBitVec_eq_sum]
  have h66 : ∑ i ∈ Finset.range 64, (if c.getLsbD i then X ^ i else 0) =
      ∑ k ∈ Finset.range (6 * 11), if c.toNat.testBit k then X ^ k else 0 := by
    rw [show 6 * 11 = 64 + 2 by rfl, Finset.sum_range_add]
    have : ∀ x ∈ Finset.range 2, (if c.toNat.testBit (64 + x) then X ^ (64 + x) else 0) = 0 := by
      intro x _
      rw [Nat.testBit_lt_two_pow (lt_of_lt_of_le c.isLt (Nat.pow_le_pow_right (by omega) (by omega)))]
      rfl
    rw [Finset.sum_eq_zero this, add_zero]
    rfl
  rw [h66, sum_range_six_mul]
  refine Finset.sum_congr rfl fun j _ => Finset.sum_congr rfl fun b hb => ?_
  have hb : b < 6 := Finset.mem_range.mp hb
  have key : ((c.toNat >>> (6 * j)) % 2 ^ 6).testBit b = c.toNat.testBit (6 * j + b) := by
    rw [Nat.testBit_mod_two_pow, Nat.testBit_shiftRight]
    simp [hb]
  rw [show c.toNat >>> (6 * j) % 64 = c.toNat >>> (6 * j) % 2 ^ 6 from rfl, key]

end Verifier.Field
