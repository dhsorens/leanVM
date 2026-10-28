import Verifier.Verification.Fold

/-! The verifier's fold of a queried row past level 0: `dot(ext_row(row), eq_kernel(r))` is ArkLib's
`multilinearCombine` at `r` of the row's lanes, lane `i` being the extension element of the row's words
`3i, 3i + 1, 3i + 2` (`deeper_fold`). -/

open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM Std.Do
open Verifier.Field

namespace Verifier

/-- `dot`'s sum over its first `i` terms. -/
def dotSum (l r : List verifier.field.E) (i : ℕ) : BF64.Ext3 :=
  ∑ t ∈ Finset.range i, toExt3 l[t]! * toExt3 r[t]!

/-- `dot`'s loop invariant after `i` terms. -/
def dotInv (l r : Slice verifier.field.E) (i : Std.Usize) (s : verifier.field.E) : RustM Prop :=
  ok (toExt3 s = dotSum l.val r.val i.val)

@[spec]
theorem dot_loop_spec (l r : Slice verifier.field.E) (n : Std.Usize) (hn : n.val = l.length)
    (hr : l.length = r.length) (s0 : verifier.field.E) (h0 : toExt3 s0 = 0) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.multilinear.dot_loop { start := 0#usize, «end» := n } l r s0
    ⦃ ⇓ s => ⌜ (dotInv l r n s).holds ⌝ ⦄ := by
  unfold verifier.multilinear.dot_loop
  apply Hax.loop_range_spec_unsigned (inv := dotInv l r)
  · simp
  · simp [dotInv, dotSum, h0]
  · intro acc i _ hi hinv
    simp only [dotInv, holds_ok] at hinv
    hax_mvcgen [verifier.multilinear.dot_loop.body, E_mul_ok, E_add_assign_ok, dotInv]
    case vc1.hQ =>
      rename_i hlt s hs x hx y hy
      obtain ⟨hxi, rfl⟩ := hx
      obtain ⟨hyi, rfl⟩ := hy
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [dotInv, holds_ok, toExt3_ofExt3, hinv, hs, dotSum, Finset.sum_range_succ]
      simp [getElem!_pos, hxi, hyi]
    case vc1.hQ =>
      have : i.val = n.val := by scalar_tac
      rw [hinv, this]
    all_goals scalar_tac

theorem dot_spec (l r : Slice verifier.field.E) (hr : l.length = r.length) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.multilinear.dot l r
    ⦃ ⇓ s => ⌜ toExt3 s = dotSum l.val r.val l.length ⌝ ⦄ := by
  hax_mvcgen [verifier.multilinear.dot, ZERO_ok, dotInv, toExt3_ofExt3]
  case vc1.hn => rename_i h _ _ _ _; rw [h, Slice.len_val]
  case vc4.hQ.success => rename_i h _ _ _ _ _ hs; rwa [h, Slice.len_val] at hs
  case vc5.h_fail => rename_i h _ h' hne; exact hne (by rw [h, h']; scalar_tac)

/-- Lane `k` of a row past level 0: its words `3k, 3k + 1, 3k + 2` as one extension element. -/
def wordsE (w : List verifier.field.K) (k : ℕ) : verifier.field.E := ⟨w[3 * k]!, w[3 * k + 1]!, w[3 * k + 2]!⟩

/-- `ext_row`'s loop invariant after `i` lanes. -/
def extInv (words : Slice verifier.field.K) (i : Std.Usize) (row : alloc.vec.Vec verifier.field.E) : RustM Prop :=
  ok (row.val = (List.range i.val).map (wordsE words.val))

@[spec]
theorem ext_row_loop_spec (words : Slice verifier.field.K) (n : Std.Usize) (hn : 3 * n.val ≤ words.length)
    (row0 : alloc.vec.Vec verifier.field.E) (h0 : row0.val = []) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.whir.ext_row_loop { start := 0#usize, «end» := n } words row0
    ⦃ ⇓ row => ⌜ (extInv words n row).holds ⌝ ⦄ := by
  unfold verifier.whir.ext_row_loop
  apply Hax.loop_range_spec_unsigned (inv := extInv words)
  · simp
  · simp [extInv, h0]
  · intro acc i _ hi hinv
    simp only [extInv, holds_ok] at hinv
    have hlen : acc.length = i.val := by
      show acc.val.length = _
      rw [hinv, List.length_map, List.length_range]
    hax_mvcgen [verifier.whir.ext_row_loop.body, verifier.field.E.new, extInv]
    case vc1.h => scalar_tac
    case vc2 =>
      rename_i hlt s hs a ha x hx b hb y hy c hc z hz r hr
      obtain ⟨wa, rfl⟩ := hx
      obtain ⟨wb, rfl⟩ := hy
      obtain ⟨wc, rfl⟩ := hz
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [extInv, holds_ok, hr, hinv, hs, List.range_succ, List.map_append, List.map_singleton]
      congr 2
      simp only [wordsE]
      have ha' : a.val = 3 * i.val := by scalar_tac
      have hb' : b.val = a.val + 1 := by scalar_tac
      have hc' : c.val = a.val + 2 := by scalar_tac
      rw [← ha', ← hb', ← hc', getElem!_pos words.val _ wa, getElem!_pos words.val _ wb, getElem!_pos words.val _ wc]
    case vc1.hQ =>
      have : i.val = n.val := by scalar_tac
      rw [hinv, this]
    all_goals scalar_tac

theorem ext_row_spec (words : Slice verifier.field.K) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.whir.ext_row words
    ⦃ ⇓ row => ⌜ row.val = (List.range (words.length / 3)).map (wordsE words.val) ⌝ ⦄ := by
  hax_mvcgen [verifier.whir.ext_row, extInv]
  case vc1.hn => rename_i m h n hn; rw [hn, h]; scalar_tac
  case vc3.h_ok.success => rename_i m h n hn _ hr; rwa [hn, h, Slice.len_val] at hr

/-- A row's lanes past level 0 as ArkLib's interleaved words at one column: lane `i` is the extension
element of the row's words `3i, 3i + 1, 3i + 2`. -/
def extLanes (words : List verifier.field.K) (ϑ : ℕ) : Fin (2 ^ ϑ) → Unit → BF64.Ext3 :=
  fun i _ => toExt3 (wordsE words i)

theorem deeper_fold (point : Slice verifier.field.E) (hn : point.length ≤ 8)
    (lw : alloc.vec.Vec verifier.field.E) (hlw : verifier.multilinear.eq_kernel point = ok lw)
    (words : Slice verifier.field.K) (hwords : words.length = 3 * 2 ^ point.length)
    (row : alloc.vec.Vec verifier.field.E) (hrow : verifier.whir.ext_row words = ok row)
    (l w : Slice verifier.field.E) (hl : l.val = row.val) (hw : w.val = lw.val) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.multilinear.dot l w
    ⦃ ⇓ s => ⌜ toExt3 s =
      multilinearCombine (extLanes words.val point.length) (fun t : Fin point.length => toExt3 point.val[t]!) () ⌝ ⦄ := by
  obtain ⟨hlen, hval⟩ := Hax.triple_noThrow_elim (eq_kernel_spec point hn) hlw
  have hr := Hax.triple_noThrow_elim (ext_row_spec words) hrow
  have h3 : words.length / 3 = 2 ^ point.length := by rw [hwords]; omega
  rw [h3] at hr
  have hll : l.length = w.length := by
    show l.val.length = w.val.length
    rw [hl, hw, hr, List.length_map, List.length_range]
    exact hlen.symm
  have hd := dot_spec l w hll
  obtain ⟨s, hs⟩ := Hax.triple_noThrow_exists_ok hd
  have hp := Hax.triple_noThrow_elim hd hs
  rw [hs]
  refine Hax.triple_of_ok rfl ?_
  have hl2 : l.length = 2 ^ point.length := by
    show l.val.length = _
    rw [hl, hr, List.length_map, List.length_range]
  rw [show toExt3 s = _ from hp, dotSum, hl2, Finset.sum_range, multilinearCombine]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [hw, hval i i.isLt, eqw_eq_multilinearWeight _ _ _ i.isLt, hl, hr, extLanes]
  rw [smul_eq_mul, mul_comm]
  simp [getElem!_pos]
