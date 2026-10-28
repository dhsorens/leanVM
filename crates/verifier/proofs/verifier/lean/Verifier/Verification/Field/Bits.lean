import CompPoly.Fields.Binary.BF64.Impl
import Std.Tactic.BVDecide

/-! The verifier's base-field kernels (`crates/verifier/src/field.rs`) as bit-vector functions,
each equal to CompPoly's: the carry-less product by masked integer multiplication, its high half
by bit reversal, and the reduction modulo `x^64 + x^4 + x^3 + x + 1` by one spilled fold. -/

namespace Verifier.Field

open BinaryField

/-- `clmul_low`: the four classes of bit positions mod 4, multiplied as integers and masked. -/
def clmulLow (a b : BitVec 64) : BitVec 64 :=
  let M0 : BitVec 64 := 0x1111111111111111#64
  let M1 := M0 <<< 1
  let M2 := M0 <<< 2
  let M3 := M0 <<< 3
  let x0 := a &&& M0
  let x1 := a &&& M1
  let x2 := a &&& M2
  let x3 := a &&& M3
  let y0 := b &&& M0
  let y1 := b &&& M1
  let y2 := b &&& M2
  let y3 := b &&& M3
  let z0 := x0 * y0 ^^^ x1 * y3 ^^^ x2 * y2 ^^^ x3 * y1
  let z1 := x0 * y1 ^^^ x1 * y0 ^^^ x2 * y3 ^^^ x3 * y2
  let z2 := x0 * y2 ^^^ x1 * y1 ^^^ x2 * y0 ^^^ x3 * y3
  let z3 := x0 * y3 ^^^ x1 * y2 ^^^ x2 * y1 ^^^ x3 * y0
  z0 &&& M0 ||| z1 &&& M1 ||| z2 &&& M2 ||| z3 &&& M3

/-- `clmul`: the low half directly, the high half from the reversed operands. -/
def clmul (a b : BitVec 64) : BitVec 128 :=
  let low := clmulLow a b
  let high := (clmulLow a.reverse b.reverse).reverse >>> 1
  high.setWidth 128 <<< 64 ||| low.setWidth 128

/-- `reduce`: the high half folded in by `x^4 + x^3 + x + 1`, its overflow past `x^63` once more. -/
def reduce (p : BitVec 128) : BitVec 64 :=
  let lo := p.setWidth 64
  let hi := (p >>> 64).setWidth 64
  let spill := hi >>> 63 ^^^ hi >>> 61 ^^^ hi >>> 60
  let v := hi ^^^ spill
  lo ^^^ v ^^^ v <<< 1 ^^^ v <<< 3 ^^^ v <<< 4

theorem fin_foldl_eq_range_foldl {α : Type} (n : ℕ) (g : α → ℕ → α) (x : α) :
    Fin.foldl n (fun acc (i : Fin n) => g acc i) x = (List.range n).foldl g x := by
  induction n generalizing x with
  | zero => simp
  | succ n ih =>
    rw [Fin.foldl_succ_last, List.range_succ, List.foldl_append]
    simp only [Fin.val_castSucc, Fin.val_last, List.foldl_cons, List.foldl_nil]
    rw [ih]

/-- CompPoly's carry-less product as a fold over `List.range`, which `simp` unrolls. -/
theorem carryLessMul_eq_range {v w : ℕ} (a b : BitVec v) :
    carryLessMul (w := w) a b = (List.range v).foldl
      (fun acc i => if a.getLsbD i then acc ^^^ (zeroExtendTo b : BitVec w) <<< i else acc) 0 := by
  unfold carryLessMul
  exact fin_foldl_eq_range_foldl v
    (fun acc i => if a.getLsbD i then acc ^^^ (zeroExtendTo b : BitVec w) <<< i else acc) 0

set_option maxRecDepth 100000 in
set_option maxHeartbeats 0 in
theorem clmulLow_eq (a b : BitVec 64) :
    clmulLow a b = BF64.lowHalf (carryLessMul (w := 128) a b) := by
  simp only [clmulLow, BF64.lowHalf, carryLessMul_eq_range, zeroExtendTo, List.range, List.range.loop,
    List.foldl]
  bv_decide (config := { timeout := 3600 })

set_option maxRecDepth 100000 in
set_option maxHeartbeats 0 in
theorem clmul_eq (a b : BitVec 64) : clmul a b = carryLessMul (w := 128) a b := by
  simp only [clmul, clmulLow_eq, BF64.lowHalf, carryLessMul_eq_range, zeroExtendTo, List.range,
    List.range.loop, List.foldl]
  bv_decide (config := { timeout := 3600 })

set_option maxRecDepth 100000 in
set_option maxHeartbeats 0 in
theorem reduce_eq (p : BitVec 128) : reduce p = BF64.reduce p := by
  simp only [reduce, BF64.reduce, BF64.foldStep, BF64.highHalf, BF64.lowHalf, BF64.reductionConstant,
    carryLessMul_eq_range, zeroExtendTo, List.range, List.range.loop, List.foldl]
  bv_decide (config := { timeout := 3600 })

set_option maxRecDepth 100000 in
set_option maxHeartbeats 0 in
/-- The reduction is linear, so a sum of products reduces term by term. -/
theorem reduce_xor (x y : BitVec 128) : BF64.reduce (x ^^^ y) = BF64.reduce x ^^^ BF64.reduce y := by
  simp only [BF64.reduce, BF64.foldStep, BF64.highHalf, BF64.lowHalf, BF64.reductionConstant,
    carryLessMul_eq_range, zeroExtendTo, List.range, List.range.loop, List.foldl]
  bv_decide (config := { timeout := 3600 })

end Verifier.Field
