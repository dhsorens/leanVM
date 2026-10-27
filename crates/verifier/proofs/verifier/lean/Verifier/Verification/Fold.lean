import Verifier.Verification.EqKernel

/-! The verifier's fold of a queried row at level 0: `base_fold(row, eq_kernel(r))` is ArkLib's
`multilinearCombine` at `r` of the row's lanes, lane `i` being the row's word `n - 1 - i` embedded in
the extension (`level0_fold`). -/

open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM Std.Do
open Verifier.Field

namespace Verifier

/-- The level-0 fold's sum over its first `i` lanes. -/
def baseSum (row : List verifier.field.K) (w : List verifier.field.E) (n i : ℕ) : BF64.Ext3 :=
  ∑ t ∈ Finset.range i, toBF64 row[n - 1 - t]! • toExt3 w[t]!

/-- The loop's invariant after `i` lanes. -/
def baseInv (row : Slice verifier.field.K) (w : Slice verifier.field.E) (n : ℕ) (i : Std.Usize) (s : verifier.field.E) :
    RustM Prop :=
  ok (toExt3 s = baseSum row.val w.val n i.val)

@[spec]
theorem base_fold_loop_spec (row : Slice verifier.field.K) (w : Slice verifier.field.E) (n : Std.Usize)
    (hn : n.val = row.length) (hw : row.length = w.length) (s0 : verifier.field.E) (h0 : toExt3 s0 = 0) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.whir.base_fold_loop { start := 0#usize, «end» := n } row w n s0
    ⦃ ⇓ s => ⌜ (baseInv row w n.val n s).holds ⌝ ⦄ := by
  unfold verifier.whir.base_fold_loop
  apply Hax.loop_range_spec_unsigned (inv := baseInv row w n.val)
  · simp
  · simp [baseInv, baseSum, h0]
  · intro acc i _ hi hinv
    simp only [baseInv, holds_ok] at hinv
    hax_mvcgen [verifier.whir.base_fold_loop.body, E_mulK_ok, E_add_assign_ok, baseInv]
    case vc1.hQ =>
      rename_i hlt s hs x hx m hm _ k hk _ y hy
      obtain ⟨hxi, rfl⟩ := hx
      obtain ⟨hyk, rfl⟩ := hy
      refine ⟨hlt, trivial, hs, ?_⟩
      simp only [baseInv, holds_ok, toExt3_ofExt3, hinv, hs, baseSum, Finset.sum_range_succ]
      have hk' : k.val = n.val - 1 - i.val := by scalar_tac
      have hyk' : n.val - 1 - i.val < row.val.length := hk' ▸ hyk
      simp [getElem!_pos, hxi, hyk', hk']
    case vc1.hQ =>
      have : i.val = n.val := by scalar_tac
      rw [hinv, this]
    all_goals scalar_tac

theorem base_fold_spec (row : Slice verifier.field.K) (w : Slice verifier.field.E) (hn : row.length = w.length) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.whir.base_fold row w
    ⦃ ⇓ s => ⌜ toExt3 s = baseSum row.val w.val row.length row.length ⌝ ⦄ := by
  hax_mvcgen [verifier.whir.base_fold, ZERO_ok, baseInv, toExt3_ofExt3]
  case vc1.hn => rename_i h _ _ _ _; rw [h, Slice.len_val]
  case vc4.hQ.success => rename_i h _ _ _ _ _ hs; rwa [h, Slice.len_val] at hs
  case vc5.h_fail => rename_i h _ h' hne; exact hne (by rw [h, h']; scalar_tac)

/-- A level-0 row's lanes as ArkLib's interleaved words at one column: lane `i` is the row's word
`2^ϑ - 1 - i`, in the extension. -/
def lanes (row : List verifier.field.K) (ϑ : ℕ) : Fin (2 ^ ϑ) → Unit → BF64.Ext3 :=
  fun i _ => toBF64 row[2 ^ ϑ - 1 - (i : ℕ)]! • 1

theorem level0_fold (point : Slice verifier.field.E) (hn : point.length ≤ 8)
    (lw : alloc.vec.Vec verifier.field.E) (hlw : verifier.multilinear.eq_kernel point = ok lw)
    (row : Slice verifier.field.K) (hrow : row.length = 2 ^ point.length)
    (w : Slice verifier.field.E) (hw : w.val = lw.val) :
    ⦃ ⌜ True ⌝ ⦄
    verifier.whir.base_fold row w
    ⦃ ⇓ s => ⌜ toExt3 s =
      multilinearCombine (lanes row.val point.length) (fun t : Fin point.length => toExt3 point.val[t]!) () ⌝ ⦄ := by
  obtain ⟨hlen, hval⟩ := Hax.triple_noThrow_elim (eq_kernel_spec point hn) hlw
  have hwl : row.length = w.length := by
    show row.val.length = w.val.length
    rw [hw]; exact hrow.trans hlen.symm
  have hb := base_fold_spec row w hwl
  obtain ⟨s, hs⟩ := Hax.triple_noThrow_exists_ok hb
  have hp := Hax.triple_noThrow_elim hb hs
  rw [hs]
  refine Hax.triple_of_ok rfl ?_
  rw [show toExt3 s = _ from hp, baseSum, hrow, Finset.sum_range, multilinearCombine]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [hw, hval i i.isLt, eqw_eq_multilinearWeight _ _ _ i.isLt, lanes, smul_eq_mul, mul_smul_comm, mul_one]
  rfl

end Verifier
