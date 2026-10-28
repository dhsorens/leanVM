import Verifier.Verification.Scaled
import ArkLib.Data.CodingTheory.Prelims

/-! `eq_kernel(point)` is the table of ArkLib's `multilinearWeight point i` over every index `i`
(`eq_kernel_spec`, `eqw_eq_multilinearWeight`), for points of at most 31 coordinates, whose `1 << len` fits
a 32-bit `usize`, through `Scaled`'s table or not. -/

open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM Std.Do
open Verifier.Field

namespace Verifier

/-- `Scaler::mul` of a plain scaler is the product. -/
theorem scaler_plain_mul (r v : verifier.field.E) :
    verifier.multilinear.Scaler.mul (.Plain r) v = ok (ofExt3 (toExt3 v * toExt3 r)) := by
  simp [verifier.multilinear.Scaler.mul, E_mul_ok]

/-- A `Scaler` multiplies by its factor, through `Scaled`'s table or not. -/
@[spec]
theorem scaler_new_spec (r : verifier.field.E) (uses : Std.Usize) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.multilinear.Scaler.new r uses
    ⦃ ⇓ sc => ⌜ ∀ v, verifier.multilinear.Scaler.mul sc v = ok (ofExt3 (toExt3 v * toExt3 r)) ⌝ ⦄ := by
  unfold verifier.multilinear.Scaler.new
  split
  · obtain ⟨s, hs⟩ := Hax.triple_noThrow_exists_ok (new_spec r)
    rw [hs, Aeneas.Std.bind_ok]
    exact Hax.triple_of_ok rfl fun v => scaled_mul r s hs v
  · exact Hax.triple_of_ok rfl fun v => scaler_plain_mul r v

/-- What the inner loop of `eq_kernel` leaves at entry `j`, after `i` of its `half` steps. -/
def innerAt (out0 : List verifier.field.E) (r : BF64.Ext3) (half i j : ℕ) : BF64.Ext3 :=
  if j < i then toExt3 out0[j]! * (1 + r)
  else if j < half then toExt3 out0[j]!
  else if j < half + i then toExt3 out0[j - half]! * r
  else toExt3 out0[j]!
theorem innerAt_step (out0 : List verifier.field.E) (r : BF64.Ext3) (half i j : ℕ)
    (hi : j ≠ i) (hk : j ≠ i + half) : innerAt out0 r half (i + 1) j = innerAt out0 r half i j := by
  unfold innerAt
  split_ifs <;> first | omega | rfl

/-- The inner loop's invariant after `i` steps. -/
def innerInv (out0 : alloc.vec.Vec verifier.field.E) (r : verifier.field.E) (half : Std.Usize)
    (i : Std.Usize) (out : alloc.vec.Vec verifier.field.E) : RustM Prop :=
  ok (out.length = out0.length ∧
    ∀ j < out0.length, toExt3 out.val[j]! = innerAt out0.val (toExt3 r) half.val i.val j)

theorem inner_spec (half : Std.Usize) (r : verifier.field.E) (scale : verifier.multilinear.Scaler)
    (hmul : ∀ v, scale.mul v = ok (ofExt3 (toExt3 v * toExt3 r)))
    (out0 : alloc.vec.Vec verifier.field.E) (hh : 2 * half.val ≤ out0.length) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.multilinear.eq_kernel_loop0_loop0 { start := 0#usize, «end» := half } out0 half scale
    ⦃ ⇓ out => ⌜ (innerInv out0 r half half out).holds ⌝ ⦄ := by
  unfold verifier.multilinear.eq_kernel_loop0_loop0
  apply Hax.loop_range_spec_unsigned (inv := innerInv out0 r half)
  · simp
  · simp only [innerInv, holds_ok]
    refine ⟨trivial, fun j hj => ?_⟩
    simp only [innerAt]
    split_ifs <;> first | rfl | scalar_tac
  · intro acc i h0 hi hinv
    simp only [innerInv, holds_ok] at hinv
    obtain ⟨hlen, hval⟩ := hinv
    hax_mvcgen [verifier.multilinear.eq_kernel_loop0_loop0.body, hmul, E_add_assign_ok]
    case vc1.h => scalar_tac
    case vc2.h => scalar_tac
    case vc3.h p hp =>
      rename_i pr
      show _ < (pr.2 _).val.length
      rw [hp.2]
      simp only [List.length_set]
      scalar_tac
    case vc4.hQ =>
      rename_i hlt s hs x hx k hk p1 o1 hp1 p2 hp2 o2
      refine ⟨hlt, trivial, hs, ?_⟩
      have e1 : o1.val = acc.val.set k.val (ofExt3 (toExt3 x * toExt3 r)) := hp1.2 _
      have e2 : o2.val = o1.val.set i.val
          (ofExt3 (toExt3 p2.1 + toExt3 (ofExt3 (toExt3 x * toExt3 r)))) := hp2.2 _
      have hki : k.val ≠ i.val := by scalar_tac
      have hp21 : p2.1 = acc.val[i.val]! := by
        rw [hp2.1, e1, getElem!_set]; simp [hki]
      have hL : acc.val.length = out0.val.length := hlen
      have hai : toExt3 acc.val[i.val]! = toExt3 out0.val[i.val]! := by
        rw [hval _ (by scalar_tac)]; simp only [innerAt]; split_ifs <;> first | omega | rfl
      simp only [innerInv, holds_ok]
      refine ⟨?_, fun j hj => ?_⟩
      · show o2.val.length = _
        rw [e2, List.length_set, e1, List.length_set, hL]
      · have hj' : j < out0.val.length := hj
        rw [e2, getElem!_set, e1, getElem!_set]
        simp only [List.length_set, hL, hj', and_true]
        by_cases hji : i.val = j
        · subst hji
          simp only [ite_true, toExt3_ofExt3, hp21, hx, hval _ hj]
          simp only [innerAt]
          split_ifs <;> first | omega | ring
        · by_cases hjk : k.val = j
          · subst hjk
            have hk' : k.val - half.val = i.val := by scalar_tac
            simp only [hji, ite_false, ite_true, toExt3_ofExt3, hx, hai]
            simp only [innerAt, hk']
            split_ifs <;> first | omega | rfl
          · simp only [hji, hjk, ite_false]
            rw [hval _ hj, hs, innerAt_step _ _ _ _ _ (Ne.symm hji) (by scalar_tac)]
    case vc5.h_fail => scalar_tac
    case vc1.vc6.hQ hge =>
      have : i = half := by scalar_tac
      subst this
      simp only [innerInv, wp_ok_prop]
      exact ⟨hlen, hval⟩

/-- `eq(j, point)` over the first `k` coordinates, LSB-first; `1 + r` is `1 - r` in characteristic 2. -/
def eqw (pt : ℕ → BF64.Ext3) : ℕ → ℕ → BF64.Ext3
  | 0, _ => 1
  | k + 1, j => eqw pt k j * (if j.testBit k then pt k else 1 + pt k)

theorem eqw_congr (pt : ℕ → BF64.Ext3) (k a b : ℕ) (h : ∀ t < k, a.testBit t = b.testBit t) :
    eqw pt k a = eqw pt k b := by
  induction k with
  | zero => rfl
  | succ k ih =>
    simp only [eqw, h k (by omega), ih (fun t ht => h t (by omega))]

theorem outer_step (pt : ℕ → BF64.Ext3) (n k : ℕ) (hk : k < n) (acc out : List verifier.field.E)
    (hval : ∀ j < 2 ^ n, toExt3 acc[j]! = if j < 2 ^ k then eqw pt k j else 0)
    (hout : ∀ j < 2 ^ n, toExt3 out[j]! = innerAt acc (pt k) (2 ^ k) (2 ^ k) j) :
    ∀ j < 2 ^ n, toExt3 out[j]! = if j < 2 ^ (k + 1) then eqw pt (k + 1) j else 0 := by
  intro j hj
  have hp : 2 ^ (k + 1) = 2 ^ k + 2 ^ k := by rw [pow_succ]; omega
  have hkn : 2 ^ (k + 1) ≤ 2 ^ n := Nat.pow_le_pow_right (by omega) hk
  rw [hout j hj]
  unfold innerAt
  by_cases h1 : j < 2 ^ k
  · rw [ite_eq_left h1, hval j hj, ite_eq_left h1, ite_eq_left (by omega), eqw, Nat.testBit_eq_false_of_lt h1]
    rfl
  · rw [ite_eq_right h1, ite_eq_right h1]
    by_cases h2 : j < 2 ^ k + 2 ^ k
    · obtain ⟨m, rfl⟩ : ∃ m, j = 2 ^ k + m := ⟨j - 2 ^ k, by omega⟩
      rw [ite_eq_left h2, Nat.add_sub_cancel_left, hval m (by omega), ite_eq_left (by omega), ite_eq_left (by omega), eqw,
        Nat.testBit_two_pow_add_eq, Nat.testBit_eq_false_of_lt (by omega)]
      simp only [Bool.not_false, ite_true]
      congr 1
      exact eqw_congr _ _ _ _ fun t ht => (Nat.testBit_two_pow_add_gt ht m).symm
    · rw [ite_eq_right h2, hval j hj, ite_eq_right h1, ite_eq_right (by omega)]
/-- The outer loop's invariant after `k` coordinates. -/
def outerInv (point : Slice verifier.field.E) (n : ℕ) (k : Std.Usize) (out : alloc.vec.Vec verifier.field.E) :
    RustM Prop :=
  ok (out.length = 2 ^ n ∧ ∀ j < 2 ^ n,
    toExt3 out.val[j]! = if j < 2 ^ k.val then eqw (fun t => toExt3 point.val[t]!) k.val j else 0)

@[spec]
theorem outer_spec (point : Slice verifier.field.E) (hn : point.length ≤ 31) (out0 : alloc.vec.Vec verifier.field.E)
    (h0 : (outerInv point point.length 0#usize out0).holds) (e : Std.Usize) (he : e = point.len) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.multilinear.eq_kernel_loop0 { start := 0#usize, «end» := e } point out0
    ⦃ ⇓ out => ⌜ (outerInv point point.length e out).holds ⌝ ⦄ := by
  subst he
  unfold verifier.multilinear.eq_kernel_loop0
  apply Hax.loop_range_spec_unsigned (inv := outerInv point point.length)
  · simp
  · exact h0
  · intro acc k hk0 hk hinv
    simp only [outerInv, holds_ok] at hinv
    obtain ⟨hlen, hval⟩ := hinv
    clear h0
    hax_mvcgen [verifier.multilinear.eq_kernel_loop0.body, scaler_new_spec, inner_spec, innerInv, outerInv]
    case vc3.hh =>
      rename_i hlt s hs h hh1 _ _ _ _ _ _
      have hk30 : k.val ≤ 30 := by scalar_tac
      have hh : h.val = 2 ^ k.val := hh1.trans (one_shl k (by omega))
      have : 2 ^ (k.val + 1) ≤ 2 ^ point.length := Nat.pow_le_pow_right (by omega) (by scalar_tac)
      rw [hh, hlen, ← pow_succ']
      exact this
    case vc4 =>
      rename_i hlt s hs h hh1 _ _ x hx _ _ out hol hov
      have hk30 : k.val ≤ 30 := by scalar_tac
      have hh : h.val = 2 ^ k.val := hh1.trans (one_shl k (by omega))
      obtain ⟨hxk, rfl⟩ := hx
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [outerInv, holds_ok, hs]
      refine ⟨hol.trans hlen, ?_⟩
      refine outer_step _ point.length k.val (by scalar_tac) acc.val out.val hval (fun j hj => ?_)
      rw [hov j (by rw [hlen]; exact hj), hh]
      simp [getElem!_pos, hxk]
    case vc5.h_fail => scalar_tac
    case vc6.h_fail =>
      have : k.val ≤ 30 := by scalar_tac
      exfalso; cases System.Platform.numBits_eq <;> omega
    case vc1.hQ =>
      rename_i hge
      have hkl : k.val = point.length := by scalar_tac
      refine ⟨hlen, fun j hj => ?_⟩
      rw [hval j hj, Slice.len_val, ← hkl]

theorem eq_kernel_spec (point : Slice verifier.field.E) (hn : point.length ≤ 31) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.multilinear.eq_kernel point
    ⦃ ⇓ out => ⌜ out.length = 2 ^ point.length ∧
      ∀ j < 2 ^ point.length, toExt3 out.val[j]! = eqw (fun t => toExt3 point.val[t]!) point.length j ⌝ ⦄ := by
  hax_mvcgen [verifier.multilinear.eq_kernel, ZERO_ok, ONE_ok, outerInv]
  case vc1.h =>
    rename_i n hn' h hh1 _ _ v hv
    have hh : h.val = 2 ^ n.val := hh1.trans (one_shl n (by subst hn'; scalar_tac))
    show 0 < v.val.length
    rw [hv, List.length_replicate, hh]
    exact Nat.two_pow_pos _
  case vc3.hQ =>
    rename_i n hn' h hh1 _ _ v hv p hp o
    have hh : h.val = 2 ^ n.val := hh1.trans (one_shl n (by subst hn'; scalar_tac))
    have ho : o.val = (List.replicate (2 ^ point.length) (ofExt3 0)).set 0 (ofExt3 1) := by
      rw [show o.val = _ from hp.2 _, hv, hh, hn', Slice.len_val]; rfl
    refine ⟨by show o.val.length = _; simp [ho], fun j hj => ?_⟩
    rw [ho, getElem!_set]
    by_cases hj0 : j = 0
    · subst hj0; simp [eqw, toExt3_ofExt3]
    · simp [hj0, Ne.symm hj0, toExt3_ofExt3, hj]
  case vc5.hQ.success =>
    rename_i n hn' _ _ _ _ _ _ _ _ _ out hol hov
    refine ⟨hol, fun j hj => ?_⟩
    rw [hov j hj, hn', Slice.len_val, ite_eq_left hj]
  case vc6.h_fail =>
    rename_i n hn' _
    exfalso; subst hn'; cases System.Platform.numBits_eq <;> scalar_tac
theorem eqw_eq_prod (pt : ℕ → BF64.Ext3) (n j : ℕ) :
    eqw pt n j = ∏ t : Fin n, if j.testBit t then pt t else 1 - pt t := by
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [Fin.prod_univ_castSucc, eqw, ih]
    simp [sub_eq_add_neg, CharTwo.neg_eq]

/-- `eq_kernel`'s weight is ArkLib's `multilinearWeight`. -/
theorem eqw_eq_multilinearWeight (pt : ℕ → BF64.Ext3) (n j : ℕ) (hj : j < 2 ^ n) :
    eqw pt n j = multilinearWeight (fun t : Fin n => pt t) ⟨j, hj⟩ := by
  rw [eqw_eq_prod]; rfl

end Verifier
