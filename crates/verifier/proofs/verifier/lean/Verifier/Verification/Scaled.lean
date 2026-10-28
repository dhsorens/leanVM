import Verifier.Verification.Std
import Verifier.Verification.Field.Window

/-! `Scaled` (`verifier::field`), the table of one factor's multiples: `Scaled::new(r)` then `mul(a)` is
`a * r` (`scaled_mul`). -/

open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM Std.Do
open Verifier.Field

namespace Verifier

theorem WINDOW_eq : verifier.field.WINDOW = 6#usize := by
  unfold verifier.field.WINDOW; rfl

@[spec]
theorem WINDOWS_PER_LIMB_triple :
    ⦃ ⌜ True ⌝ ⦄ verifier.field.WINDOWS_PER_LIMB ⦃ ⇓ r => ⌜ r.val = 11 ⌝ ⦄ := by
  unfold verifier.field.WINDOWS_PER_LIMB
  hax_mvcgen [core.num.Usize.div_ceil, WINDOW_eq]
  all_goals scalar_tac

theorem times_x_ok (v : Std.U64) :
    verifier.field.Scaled.new.closure.Insts.CoreOpsFunctionFnTupleU64U64.call () v = ok ⟨timesX v.bv⟩ := by
  unfold verifier.field.Scaled.new.closure.Insts.CoreOpsFunctionFnTupleU64U64.call
  simp only [lift, bind_ok, HShiftLeft.hShiftLeft, HShiftRight.hShiftRight, UScalar.shiftLeft_IScalar,
    UScalar.shiftRight_IScalar, UScalar.shiftLeft, UScalar.shiftRight,
    CoreModels.core.num.U64.wrapping_sub, CoreModels.rust_primitives.arithmetic.wrapping_sub_u64]
  simp [timesX]
  rw [UScalar.eq_equiv_bv_eq]
  simp [U64.wrapping_sub, UScalar.wrapping_sub]

/-- `y`, the extension's generator. -/
def Y : BF64.Ext3 := toExt3 ⟨0#u64, 1#u64, 0#u64⟩

theorem c_Y : c Y 0 = 0 ∧ c Y 1 = 1 ∧ c Y 2 = 0 := c_toExt3 _

/-- Each limb by `times_x` is the element by `x`. -/
theorem toExt3_timesX (a : verifier.field.E) :
    toExt3 ⟨⟨timesX a.c0.bv⟩, ⟨timesX a.c1.bv⟩, ⟨timesX a.c2.bv⟩⟩ = X • toExt3 a := by
  obtain ⟨a0, a1, a2⟩ := c_toExt3 a
  obtain ⟨t0, t1, t2⟩ := c_toExt3 (⟨⟨timesX a.c0.bv⟩, ⟨timesX a.c1.bv⟩, ⟨timesX a.c2.bv⟩⟩ : verifier.field.E)
  refine ext3_eq ?_ ?_ ?_
  · rw [t0, c_smul _ _ 0 (by decide), a0]; exact ofBitVec_timesX _
  · rw [t1, c_smul _ _ 1 (by decide), a1]; exact ofBitVec_timesX _
  · rw [t2, c_smul _ _ 2 (by decide), a2]; exact ofBitVec_timesX _

/-- `Scaled::new`'s step to the next limb's monomial is the product by `y`. -/
theorem toExt3_shift (m : verifier.field.E) :
    toExt3 ⟨m.c2, ⟨m.c0.bv ^^^ m.c2.bv⟩, m.c1⟩ = toExt3 m * Y := by
  obtain ⟨m0, m1, m2⟩ := mul_c (toExt3 m) Y
  obtain ⟨a0, a1, a2⟩ := c_toExt3 m
  obtain ⟨t0, t1, t2⟩ := c_toExt3 (⟨m.c2, ⟨m.c0.bv ^^^ m.c2.bv⟩, m.c1⟩ : verifier.field.E)
  obtain ⟨y0, y1, y2⟩ := c_Y
  refine ext3_eq ?_ ?_ ?_
  · rw [t0, m0, a2, y0, y1, y2]; ring
  · rw [t1, m1, a0, a2, y0, y1, y2, ofBitVec_xor]; ring
  · rw [t2, m2, a1, y0, y1, y2]; ring

/-- An element by its limbs: `a = a0 + a1 y + a2 y^2`. -/
theorem toExt3_limbs (a : verifier.field.E) :
    toExt3 a = toBF64 a.c0 • 1 + toBF64 a.c1 • Y + toBF64 a.c2 • (Y * Y) := by
  obtain ⟨a0, a1, a2⟩ := c_toExt3 a
  obtain ⟨y0, y1, y2⟩ := c_Y
  obtain ⟨o0, o1, o2⟩ := one_c
  obtain ⟨s0, s1, s2⟩ := mul_c Y Y
  refine ext3_eq ?_ ?_ ?_ <;>
  simp only [c_add _ _ _ (by decide : (0 : ℕ) < 3), c_add _ _ _ (by decide : (1 : ℕ) < 3),
    c_add _ _ _ (by decide : (2 : ℕ) < 3), c_smul _ _ _ (by decide : (0 : ℕ) < 3),
    c_smul _ _ _ (by decide : (1 : ℕ) < 3), c_smul _ _ _ (by decide : (2 : ℕ) < 3),
    a0, a1, a2, y0, y1, y2, o0, o1, o2, s0, s1, s2, toBF64] <;> ring

theorem pow_or (b l : ℕ) (h : l < 2 ^ b) : 2 ^ b ||| l = 2 ^ b + l := by
  have := Nat.two_pow_add_eq_or_of_lt h 1
  rw [mul_one] at this
  exact this.symm

/-- The innermost loop of `Scaled::new` after `low` steps: the entries `half` past `base` up to `low` are
those `half` below them plus `power`. -/
def lowInv (old : alloc.vec.Vec verifier.field.E) (power : verifier.field.E) (base half : ℕ) (low : Std.Usize)
    (tables : alloc.vec.Vec verifier.field.E) : RustM Prop :=
  ok (tables.length = old.length ∧ ∀ idx < old.length, toExt3 tables.val[idx]! =
    if base + half ≤ idx ∧ idx < base + half + low.val then toExt3 old.val[idx - half]! + toExt3 power
    else toExt3 old.val[idx]!)

theorem low_spec (old : alloc.vec.Vec verifier.field.E) (power : verifier.field.E) (table bit : Std.Usize)
    (hbit : bit.val < 6) (half : Std.Usize) (hhalf : half.val = 2 ^ bit.val)
    (hlen : table.val + 2 * half.val ≤ old.length) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.new_loop0_loop0_loop0_loop0 { start := 0#usize, «end» := half } old power table bit
    ⦃ ⇓ tables => ⌜ (lowInv old power table.val half.val half tables).holds ⌝ ⦄ := by
  unfold verifier.field.Scaled.new_loop0_loop0_loop0_loop0
  apply Hax.loop_range_spec_unsigned (inv := lowInv old power table.val half.val)
  · simp
  · simp only [lowInv, holds_ok]
    refine ⟨trivial, fun idx _ => ?_⟩
    simp
  · intro acc low _ hlow hinv
    simp only [lowInv, holds_ok] at hinv
    obtain ⟨hl, hv⟩ := hinv
    hax_mvcgen [verifier.field.Scaled.new_loop0_loop0_loop0_loop0.body, E_add_ok, lowInv]
    case vc1.h => rename_i _ _ _ i hi; rw [hl]; scalar_tac
    case vc2.h =>
      rename_i _ _ _ _ _ _ _ r hr _ _ i hi
      have hr' : r.val = 2 ^ bit.val := hr.trans (one_shl bit (by omega))
      rw [hi, UScalar.val_or, hr', pow_or _ _ (by omega), hl]
      omega
    case vc3 =>
      rename_i hlt s hs i hi e he r hr _ _ i3 hi3 p t hp
      have hr' : r.val = 2 ^ bit.val := hr.trans (one_shl bit (by omega))
      have hi3' : i3.val = table.val + half.val + low.val := by
        rw [hi3, UScalar.val_or, hr', pow_or _ _ (by omega), hhalf]; omega
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [lowInv, holds_ok, t]
      refine ⟨by simp [hp.2, hl], fun idx hidx => ?_⟩
      rw [hp.2, getElem!_set, hi3']
      have hread : toExt3 e = toExt3 old.val[table.val + low.val]! := by
        rw [he, hi, hv _ (by omega), ite_eq_right (by omega)]
      by_cases hidx3 : table.val + half.val + low.val = idx
      · subst hidx3
        have hal : acc.val.length = old.val.length := hl
        rw [ite_eq_left ⟨rfl, by rw [hal]; exact hidx⟩, toExt3_ofExt3, hread, ite_eq_left (by omega)]
        congr 3; omega
      · rw [ite_eq_right (by tauto), hv idx hidx]
        by_cases hin : table.val + half.val ≤ idx ∧ idx < table.val + half.val + low.val
        · rw [ite_eq_left hin, ite_eq_left (by omega)]
        · rw [ite_eq_right hin, ite_eq_right (by omega)]
    all_goals first
      | scalar_tac
      | (rename_i r hr _ _ hov
         rw [UScalar.val_or, hr.trans (one_shl bit (by omega)), pow_or _ _ (by omega)] at hov
         scalar_tac)
      | (refine ⟨hl, fun idx h => ?_⟩
         rw [hv idx h, show low.val = half.val by scalar_tac])
      | (rename_i hnb; exfalso; cases System.Platform.numBits_eq <;> omega)

/-- Window `j`'s value `n` weighed by its bits below `bit`. -/
def part (j bit n : ℕ) : BF64 := ∑ b ∈ Finset.range bit, if n.testBit b then X ^ (6 * j + b) else 0

theorem part_zero (j n : ℕ) : part j 0 n = 0 := rfl

theorem part_six (j n : ℕ) : part j 6 n = win j n := rfl

theorem part_low (j bit n : ℕ) (h : n < 2 ^ bit) : part j (bit + 1) n = part j bit n := by
  rw [part, Finset.sum_range_succ, Nat.testBit_lt_two_pow h]
  simp [part]

theorem part_high (j bit m : ℕ) (h : m < 2 ^ bit) :
    part j (bit + 1) (2 ^ bit + m) = part j bit m + X ^ (6 * j + bit) := by
  rw [part, Finset.sum_range_succ, Nat.testBit_two_pow_add_eq, Nat.testBit_lt_two_pow h]
  simp only [Bool.not_false, ite_true]
  congr 1
  refine Finset.sum_congr rfl fun b hb => ?_
  rw [Nat.testBit_two_pow_add_gt (Finset.mem_range.mp hb)]

/-- The loop over a window's bits after `bit` of them: its entries below `2^bit` are their bits' multiples of
`M`, the rest of the window still zero. -/
def bitInv (old : alloc.vec.Vec verifier.field.E) (M : BF64.Ext3) (base j : ℕ) (bit : Std.Usize)
    (st : alloc.vec.Vec verifier.field.E × verifier.field.E) : RustM Prop :=
  ok (toExt3 st.2 = X ^ (6 * j + bit.val) • M ∧ st.1.length = old.length ∧ ∀ idx < old.length,
    toExt3 st.1.val[idx]! = if base ≤ idx ∧ idx < base + 64 then
      (if idx - base < 2 ^ bit.val then part j bit.val (idx - base) • M else 0) else toExt3 old.val[idx]!)

theorem bit_spec (old : alloc.vec.Vec verifier.field.E) (power : verifier.field.E) (M : BF64.Ext3) (j : ℕ)
    (table : Std.Usize) (hlen : table.val + 64 ≤ old.length) (hp : toExt3 power = X ^ (6 * j) • M)
    (hz : ∀ idx, table.val ≤ idx → idx < table.val + 64 → toExt3 old.val[idx]! = 0) (w : Std.Usize) (hw : w.val = 6) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.new_loop0_loop0_loop0 { start := 0#usize, «end» := w } old power table
    ⦃ ⇓ st => ⌜ (bitInv old M table.val j w st).holds ⌝ ⦄ := by
  unfold verifier.field.Scaled.new_loop0_loop0_loop0
  apply Hax.loop_range_spec_unsigned (inv := bitInv old M table.val j)
  · simp
  · simp only [bitInv, holds_ok]
    refine ⟨by simpa using hp, trivial, fun idx hidx => ?_⟩
    by_cases hin : table.val ≤ idx ∧ idx < table.val + 64
    · rw [ite_eq_left hin, hz idx hin.1 hin.2]
      split_ifs <;> simp [part]
    · rw [ite_eq_right hin]
  · intro ⟨acc, pw⟩ bit _ hbit hinv
    simp only [bitInv, holds_ok] at hinv
    obtain ⟨hpw, hl, hv⟩ := hinv
    hax_mvcgen -trivial [verifier.field.Scaled.new_loop0_loop0_loop0.body, times_x_ok, verifier.field.E.new, bitInv, low_spec, lowInv]
    case vc1.hbit => scalar_tac
    case vc2.hhalf => rename_i r hr _ _; exact hr.trans (one_shl bit (by scalar_tac))
    case vc3.hlen =>
      rename_i r hr _ _
      have hb6 : bit.val < 6 := by scalar_tac
      have : 2 ^ (bit.val + 1) ≤ 2 ^ 6 := Nat.pow_le_pow_right (by omega) hb6
      rw [hr.trans (one_shl bit (by omega)), hl, ← pow_succ']; omega
    case vc4.hQ =>
      rename_i hlt s hs r hr _ _ t htl htv
      have hb6 : bit.val < 6 := by scalar_tac
      have hr' : r.val = 2 ^ bit.val := hr.trans (one_shl bit (by omega))
      have hpow : 2 ^ (bit.val + 1) ≤ 64 :=
        (Nat.pow_le_pow_right (by omega) hb6 : 2 ^ (bit.val + 1) ≤ 2 ^ 6)
      have h2 : 2 ^ (bit.val + 1) = 2 ^ bit.val + 2 ^ bit.val := by rw [pow_succ]; omega
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [bitInv, holds_ok]
      refine ⟨?_, htl.trans hl, fun idx hidx => ?_⟩
      · rw [toExt3_timesX, hpw, smul_smul, ← pow_succ', hs]; rfl
      · rw [htv idx (by rw [← hl] at hidx; exact hidx), hr', hs, h2]
        by_cases ha : table.val + 2 ^ bit.val ≤ idx ∧ idx < table.val + 2 ^ bit.val + 2 ^ bit.val
        · rw [ite_eq_left ha, ite_eq_left (by omega), ite_eq_left (by omega),
            hv _ (by omega), ite_eq_left (by omega), ite_eq_left (by omega), hpw]
          obtain ⟨m, hm⟩ : ∃ m, idx - table.val = 2 ^ bit.val + m := ⟨idx - table.val - 2 ^ bit.val, by omega⟩
          rw [hm, part_high _ _ _ (by omega), add_smul]
          congr 3; omega
        · rw [ite_eq_right ha, hv idx hidx]
          by_cases hw' : table.val ≤ idx ∧ idx < table.val + 64
          · rw [ite_eq_left hw', ite_eq_left hw']
            by_cases hn : idx - table.val < 2 ^ bit.val
            · rw [ite_eq_left hn, ite_eq_left (by omega), part_low _ _ _ hn]
            · rw [ite_eq_right hn, ite_eq_right (by omega)]
          · rw [ite_eq_right hw', ite_eq_right hw']
    case vc5.h_fail => exfalso; cases System.Platform.numBits_eq <;> scalar_tac
    case vc1.hQ =>
      rename_i hge
      have : bit.val = w.val := by scalar_tac
      rw [← this]
      exact ⟨hpw, hl, hv⟩

theorem shl_six (x : Std.Usize) (h : x.val < 2 ^ 20) : x.val <<< (6#usize).val % Usize.size = x.val * 64 := by
  rw [show (6#usize).val = 6 by simp]
  have hs : 2 ^ 26 ≤ Usize.size := by
    rw [Usize.size_def]
    exact Nat.pow_le_pow_right (by omega) (by cases System.Platform.numBits_eq <;> simp [Usize.numBits, *])
  rw [Nat.shiftLeft_eq, Nat.mod_eq_of_lt (by omega)]

/-- The loop over a limb's windows after `window` of them, the limb's tables from `704 limb` on. -/
def winInv (old : alloc.vec.Vec verifier.field.E) (M : BF64.Ext3) (limb : ℕ) (window : Std.Usize)
    (st : alloc.vec.Vec verifier.field.E × verifier.field.E) : RustM Prop :=
  ok (toExt3 st.2 = X ^ (6 * window.val) • M ∧ st.1.length = old.length ∧ ∀ idx < old.length,
    toExt3 st.1.val[idx]! = if 704 * limb ≤ idx ∧ idx < 704 * limb + 64 * window.val then
      win (idx % 704 / 64) (idx % 64) • M else toExt3 old.val[idx]!)

theorem win_spec (old : alloc.vec.Vec verifier.field.E) (monomial : verifier.field.E) (limb : Std.Usize)
    (hlimb : limb.val < 3) (hlen : 704 * limb.val + 704 ≤ old.length)
    (hz : ∀ idx, 704 * limb.val ≤ idx → idx < 704 * limb.val + 704 → toExt3 old.val[idx]! = 0)
    (i : Std.Usize) (hi : i.val = 11) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.new_loop0_loop0 i { start := 0#usize, «end» := i } old limb monomial
    ⦃ ⇓ tables => ⌜ tables.length = old.length ∧ ∀ idx < old.length,
      toExt3 tables.val[idx]! = if 704 * limb.val ≤ idx ∧ idx < 704 * limb.val + 704 then
        win (idx % 704 / 64) (idx % 64) • toExt3 monomial else toExt3 old.val[idx]! ⌝ ⦄ := by
  unfold verifier.field.Scaled.new_loop0_loop0
  apply loop_range_spec_result (inv := winInv old (toExt3 monomial) limb.val)
  · simp
  · simp only [winInv, holds_ok]
    refine ⟨by simp, trivial, fun idx hidx => ?_⟩
    rw [ite_eq_right (by simp)]
  · intro ⟨acc, pw⟩ window _ hwin hinv
    simp only [winInv, holds_ok] at hinv
    obtain ⟨hpw, hl, hv⟩ := hinv
    hax_mvcgen -trivial [verifier.field.Scaled.new_loop0_loop0.body, winInv, bitInv, WINDOW_eq, bit_spec]
    case vc1.M => exact toExt3 monomial
    case vc2.j => exact window.val
    case vc3.hlen =>
      rename_i _ _ _ m hm a ha b hb _ _
      have hw11 : window.val < 11 := by scalar_tac
      rw [hb, shl_six a (by scalar_tac), ha, hm, hi, hl]; omega
    case vc4.hp => exact hpw
    case vc5.hz =>
      rename_i _ _ _ m hm a ha b hb _ _ idx h1 h2
      have hw11 : window.val < 11 := by scalar_tac
      rw [hb, shl_six a (by scalar_tac), ha, hm, hi] at h1 h2
      rw [hv idx (by omega), ite_eq_right (by omega)]
      exact hz idx (by omega) (by omega)
    case vc6.hw => rfl
    case vc7 =>
      rename_i hlt s hs m hm a ha b hb _ _ st sp sl sv
      have hw11 : window.val < 11 := by scalar_tac
      have hbase : b.val = 704 * limb.val + 64 * window.val := by
        rw [hb, shl_six a (by scalar_tac), ha, hm, hi]; ring
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [winInv, holds_ok]
      refine ⟨?_, sl.trans hl, fun idx hidx => ?_⟩
      · rw [sp, hs]; congr 2
      · rw [sv idx (by rw [hl]; exact hidx), hbase]
        by_cases hin : 704 * limb.val + 64 * window.val ≤ idx ∧ idx < 704 * limb.val + 64 * window.val + 64
        · have h6 : (6#usize : Std.Usize).val = 6 := by simp
          rw [ite_eq_left hin, ite_eq_left (by rw [h6]; omega), ite_eq_left (by rw [hs]; omega), h6, part_six]
          congr 2 <;> omega
        · rw [ite_eq_right hin, hv idx hidx]
          by_cases hd : 704 * limb.val ≤ idx ∧ idx < 704 * limb.val + 64 * window.val
          · rw [ite_eq_left hd, ite_eq_left (by rw [hs]; omega)]
          · rw [ite_eq_right hd, ite_eq_right (by rw [hs]; omega)]
    case vc11.hQ =>
      rename_i hge
      have : window.val = 11 := by scalar_tac
      refine ⟨hl, fun idx hidx => ?_⟩
      rw [hv idx hidx, this]
    all_goals first
      | scalar_tac
      | (exfalso; cases System.Platform.numBits_eq <;> scalar_tac)

/-- Entry `idx` of `Scaled::new(r)`: window `idx % 704 / 64` of limb `idx / 704` at value `idx % 64`. -/
def tab (r : verifier.field.E) (idx : ℕ) : BF64.Ext3 :=
  win (idx % 704 / 64) (idx % 64) • (toExt3 r * Y ^ (idx / 704))

/-- The loop over the limbs after `limb` of them. -/
def limbInv (r : verifier.field.E) (limb : Std.Usize) (st : alloc.vec.Vec verifier.field.E × verifier.field.E) :
    RustM Prop :=
  ok (toExt3 st.2 = toExt3 r * Y ^ limb.val ∧ st.1.length = 2112 ∧ ∀ idx < 2112,
    toExt3 st.1.val[idx]! = if idx < 704 * limb.val then tab r idx else 0)

@[spec]
theorem limb_spec (r : verifier.field.E) (i : Std.Usize) (hi : i.val = 11) (t0 : alloc.vec.Vec verifier.field.E)
    (h0 : t0.val = List.replicate 2112 (ofExt3 0)) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.new_loop0 i { start := 0#usize, «end» := 3#usize } t0 r
    ⦃ ⇓ s => ⌜ s.length = 2112 ∧ ∀ idx < 2112, toExt3 s.val[idx]! = tab r idx ⌝ ⦄ := by
  unfold verifier.field.Scaled.new_loop0
  apply loop_range_spec_result (inv := limbInv r)
  · simp
  · simp only [limbInv, holds_ok]
    have z : (0#usize : Std.Usize).val = 0 := by simp
    refine ⟨by rw [z, pow_zero, mul_one], by show t0.val.length = 2112; rw [h0, List.length_replicate],
      fun idx hidx => ?_⟩
    rw [z, ite_eq_right (by omega), h0, getElem!_pos _ _ (by rw [List.length_replicate]; exact hidx),
      List.getElem_replicate, toExt3_ofExt3]
  · intro ⟨acc, m⟩ limb _ hlimb hinv
    simp only [limbInv, holds_ok] at hinv
    obtain ⟨hm, hl, hv⟩ := hinv
    hax_mvcgen -trivial [verifier.field.Scaled.new_loop0.body, limbInv, win_spec, verifier.field.E.new]
    case vc1.hlimb => scalar_tac
    case vc2.hlen => rw [hl]; scalar_tac
    case vc3.hz =>
      rename_i idx h1 h2
      have : limb.val < 3 := by scalar_tac
      rw [hv idx (by omega), ite_eq_right (by omega)]
    case vc4.hi => exact hi
    case vc5.hQ =>
      rename_i hlt s hs t ht
      obtain ⟨tl, tv⟩ := ht
      have h3 : limb.val < 3 := by scalar_tac
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [limbInv, holds_ok]
      refine ⟨?_, tl.trans hl, fun idx hidx => ?_⟩
      · show toExt3 ⟨m.c2, ⟨m.c0.bv ^^^ m.c2.bv⟩, m.c1⟩ = _
        rw [toExt3_shift, hm, hs, pow_succ, mul_assoc]
      · rw [tv idx (by rw [hl]; exact hidx), hs]
        by_cases hin : 704 * limb.val ≤ idx ∧ idx < 704 * limb.val + 704
        · rw [ite_eq_left hin, ite_eq_left (by omega), tab, hm, show idx / 704 = limb.val by omega]
        · rw [ite_eq_right hin, hv idx hidx]
          by_cases hd : idx < 704 * limb.val
          · rw [ite_eq_left hd, ite_eq_left (by omega)]
          · rw [ite_eq_right hd, ite_eq_right (by omega)]
    case vc6.hQ =>
      have : limb.val = 3 := by scalar_tac
      refine ⟨hl, fun idx hidx => ?_⟩
      rw [hv idx hidx, ite_eq_left (by omega)]

theorem new_spec (r : verifier.field.E) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.new r
    ⦃ ⇓ s => ⌜ s.length = 2112 ∧ ∀ idx < 2112, toExt3 s.val[idx]! = tab r idx ⌝ ⦄ := by
  hax_mvcgen -trivial [verifier.field.Scaled.new, ZERO_ok, WINDOW_eq]
  case vc1.hi => rename_i n hn _ _ _ _ _ _ _ _; exact hn
  case vc2.h0 =>
    rename_i n hn m hm l hl _ _ t ht
    rw [ht, show l.val = 2112 by rw [hl, shl_six m (by scalar_tac), hm, hn]; rfl]
  all_goals first
    | scalar_tac
    | (exfalso; cases System.Platform.numBits_eq <;> scalar_tac)

/-- The window `j` of a limb `c`. -/
def wnd (c : Std.U64) (j : ℕ) : ℕ := c.val >>> (6 * j) % 64

theorem wnd_lt (c : Std.U64) (j : ℕ) : wnd c j < 64 := Nat.mod_lt _ (by omega)

/-- `mul`'s index into the tables: `table << WINDOW | (limb >> (WINDOW * window)) as usize % (1 << WINDOW)`. -/
theorem mul_index (c : Std.U64) (window tb a sh m n : Std.Usize) (q : Std.U64) (htb : tb.val < 2 ^ 20)
    (ha : a.val = tb.val <<< (6#usize).val % Usize.size) (hsh : sh.val = (6#usize).val * window.val)
    (hq : q.val = c.val >>> sh.val) (hm : m.val = (1#usize).val <<< (6#usize).val % Usize.size)
    (hn : n.val = (UScalar.cast UScalarTy.Usize q).val % m.val) :
    (a ||| n).val = 64 * tb.val + wnd c window.val := by
  have h6 : (6#usize : Std.Usize).val = 6 := by simp
  have hm' : m.val = 64 := by rw [hm, h6]; exact one_shl 6#usize (by simp) |>.trans (by rw [h6]; rfl)
  have hnb : 64 ∣ 2 ^ UScalarTy.Usize.numBits := by
    rw [show (64 : ℕ) = 2 ^ 6 by rfl]
    exact Nat.pow_dvd_pow 2 (by cases System.Platform.numBits_eq <;> simp [UScalarTy.numBits, *])
  have hn' : n.val = wnd c window.val := by
    rw [hn, hm', UScalar.cast_val_eq, Nat.mod_mod_of_dvd _ hnb, hq, hsh, h6, wnd]
  rw [UScalar.val_or, ha, shl_six tb htb, hn', show tb.val * 64 = tb.val <<< 6 by rw [Nat.shiftLeft_eq],
    ← Nat.shiftLeft_add_eq_or_of_lt (wnd_lt c _), Nat.shiftLeft_eq]
  ring

/-- `mul`'s loop over a limb's windows after `window` of them. -/
def mulInv (r : verifier.field.E) (s : verifier.field.Scaled) (c : Std.U64) (t : ℕ) (P0 : BF64.Ext3)
    (window : Std.Usize) (st : verifier.field.Scaled × verifier.field.E × Std.Usize) : RustM Prop :=
  ok (st.1 = s ∧ st.2.2.val = 11 * t + window.val ∧
    toExt3 st.2.1 = P0 + ∑ j ∈ Finset.range window.val, tab r (704 * t + 64 * j + wnd c j))

theorem mul_win_spec (r : verifier.field.E) (s : verifier.field.Scaled) (hs : s.length = 2112)
    (hv : ∀ idx < 2112, toExt3 s.val[idx]! = tab r idx) (c : Std.U64) (t : ℕ) (ht : t < 3)
    (p0 : verifier.field.E) (table : Std.Usize) (htab : table.val = 11 * t) (i : Std.Usize) (hi : i.val = 11) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.mul_loop0_loop0 { start := 0#usize, «end» := i } s p0 table c
    ⦃ ⇓ st => ⌜ (mulInv r s c t (toExt3 p0) i st).holds ⌝ ⦄ := by
  unfold verifier.field.Scaled.mul_loop0_loop0
  apply Hax.loop_range_spec_unsigned (inv := mulInv r s c t (toExt3 p0))
  · simp
  · simp [mulInv, htab]
  · intro ⟨s', p, tb⟩ window _ hwin hinv
    simp only [mulInv, holds_ok] at hinv
    obtain ⟨rfl, htb, hp⟩ := hinv
    have hw11 : ∀ w : Std.Usize, w.val < i.val → w.val < 11 := fun w h => hi ▸ h
    have ht' : 11 * t + 11 ≤ 33 := by omega
    hax_mvcgen -trivial [verifier.field.Scaled.mul_loop0_loop0.body, mulInv, WINDOW_eq, E_add_assign_ok,
      vec_index_triple]
    case vc1.h =>
      rename_i hlt _ _ a ha _ _ sh hsh q hq _ _ m hm _ _ n hn
      have := hw11 window hlt
      rw [mul_index c window tb a sh m n q (by omega) ha hsh hq hm hn, hs, htb]
      have := wnd_lt c window.val
      omega
    case vc2.hQ =>
      rename_i hlt s hs' a ha _ _ sh hsh q hq _ _ m hm _ _ n hn e he tb1 htb1
      have := hw11 window hlt
      have hidx := mul_index c window tb a sh m n q (by omega) ha hsh hq hm hn
      refine ⟨hlt, trivial, hs', ?_⟩
      simp only [mulInv, holds_ok]
      refine ⟨trivial, by rw [htb1, htb, hs']; simp; omega, ?_⟩
      rw [toExt3_ofExt3, hp, hs', Finset.sum_range_succ, he, hidx, hv _ (by have := wnd_lt c window.val; omega),
        add_assoc]
      congr 3; omega
    case vc1.hQ =>
      have : window.val = i.val := by scalar_tac
      exact ⟨trivial, this ▸ htb, this ▸ hp⟩
    all_goals first
      | scalar_tac
      | (exfalso; cases System.Platform.numBits_eq <;> scalar_tac)

/-- A limb's eleven lookups: its value times the limb's multiple of `r`. -/
theorem sum_tab (r : verifier.field.E) (c : Std.U64) (t : ℕ) :
    ∑ j ∈ Finset.range 11, tab r (704 * t + 64 * j + wnd c j) = toBF64 c • (toExt3 r * Y ^ t) := by
  rw [toBF64, ← sum_win, Finset.sum_smul]
  refine Finset.sum_congr rfl fun j hj => ?_
  have hj : j < 11 := Finset.mem_range.mp hj
  have hw := wnd_lt c j
  rw [tab, show (704 * t + 64 * j + wnd c j) % 704 / 64 = j by omega,
    show (704 * t + 64 * j + wnd c j) % 64 = wnd c j by omega, show (704 * t + 64 * j + wnd c j) / 704 = t by omega]
  rfl

/-- `mul`'s loop over the limbs after `t` of them. -/
def limbsInv (r : verifier.field.E) (s : verifier.field.Scaled) (limbs : List Std.U64) (t : Std.Usize)
    (st : verifier.field.Scaled × verifier.field.E × Std.Usize) : RustM Prop :=
  ok (st.1 = s ∧ st.2.2.val = 11 * t.val ∧
    toExt3 st.2.1 = ∑ k ∈ Finset.range t.val, toBF64 limbs[k]! • (toExt3 r * Y ^ k))

@[spec]
theorem mul_limbs_spec (r : verifier.field.E) (s : verifier.field.Scaled) (hs : s.length = 2112)
    (hv : ∀ idx < 2112, toExt3 s.val[idx]! = tab r idx) (limbs : Array Std.U64 3#usize)
    (p0 : verifier.field.E) (h0 : toExt3 p0 = 0) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.mul_loop0 { start := 0#usize, «end» := 3#usize } s p0 0#usize limbs
    ⦃ ⇓ p => ⌜ toExt3 p = ∑ k ∈ Finset.range 3, toBF64 limbs.val[k]! • (toExt3 r * Y ^ k) ⌝ ⦄ := by
  unfold verifier.field.Scaled.mul_loop0
  apply loop_range_spec_result (inv := limbsInv r s limbs.val)
  · simp
  · simp [limbsInv, h0]
  · intro ⟨s', p, tb⟩ t _ _ hinv
    simp only [limbsInv, holds_ok] at hinv
    obtain ⟨rfl, htb, hp⟩ := hinv
    hax_mvcgen -trivial [verifier.field.Scaled.mul_loop0.body, limbsInv, mul_win_spec, mulInv]
    case vc1.r => exact r
    case vc2.hs => exact hs
    case vc3.hv => rename_i idx h; exact hv idx h
    case vc4.t => exact t.val
    case vc5.ht => scalar_tac
    case vc6.htab => exact htb
    case vc7.hi => rename_i _ _ _ _ _ _ h; exact h
    case vc8 =>
      rename_i hlt s hs c hc n hn st h1 h2 h3
      obtain ⟨hct, rfl⟩ := hc
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [limbsInv, holds_ok]
      refine ⟨h1, by rw [h2, hn, hs]; ring, ?_⟩
      rw [h3, hn, sum_tab r _ _, hp, hs, Finset.sum_range_succ, getElem!_pos limbs.val t.val hct]
    case vc9.h_fail =>
      rename_i h
      have : limbs.length = 3 := by simp
      exfalso; scalar_tac
    case vc10.hQ =>
      have : t.val = 3 := by scalar_tac
      rw [hp, this]

theorem ofExt3_toExt3 (x : verifier.field.E) : ofExt3 (toExt3 x) = x := by
  obtain ⟨a0, a1, a2⟩ := c_toExt3 x
  rw [ofExt3, a0, a1, a2]
  rfl

theorem mul_spec (r : verifier.field.E) (s : verifier.field.Scaled) (hs : s.length = 2112)
    (hv : ∀ idx < 2112, toExt3 s.val[idx]! = tab r idx) (a : verifier.field.E) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.field.Scaled.mul s a
    ⦃ ⇓ p => ⌜ toExt3 p = toExt3 a * toExt3 r ⌝ ⦄ := by
  unfold verifier.field.Scaled.mul
  rw [ZERO_ok, Aeneas.Std.bind_ok]
  have h := mul_limbs_spec r s hs hv (Array.make 3#usize [a.c0, a.c1, a.c2]) (ofExt3 0) (toExt3_ofExt3 0)
  obtain ⟨p, hp⟩ := Hax.triple_noThrow_exists_ok h
  have hv' := Hax.triple_noThrow_elim h hp
  rw [hp]
  refine Hax.triple_of_ok rfl ?_
  rw [show toExt3 p = _ from hv', toExt3_limbs a]
  have hmk : (Array.make 3#usize [a.c0, a.c1, a.c2] (by simp)).val = [a.c0, a.c1, a.c2] :=
    Data.ListN.ListN.from_to_inverse
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, hmk]
  simp only [List.getElem!_cons_zero, List.getElem!_cons_succ, pow_zero, pow_one, pow_two, mul_one,
    smul_mul_assoc, add_mul, zero_add, one_mul, mul_comm Y, mul_comm (Y * Y)]

/-- `Scaled::new(r)` then `mul(a)` is `a * r`. -/
theorem scaled_mul (r : verifier.field.E) (s : verifier.field.Scaled) (hs : verifier.field.Scaled.new r = ok s)
    (a : verifier.field.E) : verifier.field.Scaled.mul s a = ok (ofExt3 (toExt3 a * toExt3 r)) := by
  obtain ⟨hl, hv⟩ := Hax.triple_noThrow_elim (new_spec r) hs
  have hm := mul_spec r s hl hv a
  obtain ⟨p, hp⟩ := Hax.triple_noThrow_exists_ok hm
  rw [hp, ← Hax.triple_noThrow_elim hm hp, ofExt3_toExt3]

end Verifier
