import Verifier.Verification.Field
import Hax

/-! Specifications of the Rust library functions the verifier's proofs step through, as hax triples
(`@[spec]`, for `hax_mvcgen`) or equations, and the arithmetic facts they need. -/

open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM Std.Do
open Verifier.Field

namespace Verifier

theorem vec_index_spec {T : Type} [Inhabited T] (v : alloc.vec.Vec T) (i : Std.Usize) (h : i.val < v.length) :
    alloc.vec.Vec.Insts.CoreOpsIndexIndex.index (core.Usize.Insts.CoreSliceIndexSliceIndexSliceT T) v i =
      ok v.val[i.val]! := by
  have h' : i.val < v.val.length := h
  simp [alloc.vec.Vec.Insts.CoreOpsIndexIndex.index,
    alloc.vec.Vec.Insts.CoreOpsDerefDerefSlice.deref, alloc.vec.Vec.as_slice,
    rust_primitives.sequence.seq_to_slice, core.Slice.Insts.CoreOpsIndexIndex.index,
    core.Usize.Insts.CoreSliceIndexSliceIndexSliceT.get, rust_primitives.slice.slice_length,
    rust_primitives.slice.slice_index, Slice.index_usize]
  erw [Aeneas.Std.bind_ok]
  simp [h']

@[spec]
theorem vec_index_triple {T : Type} [Inhabited T] (v : alloc.vec.Vec T) (i : Std.Usize) (h : i.val < v.length) :
    ⦃ ⌜ True ⌝ ⦄
    alloc.vec.Vec.Insts.CoreOpsIndexIndex.index (core.Usize.Insts.CoreSliceIndexSliceIndexSliceT T) v i
    ⦃ ⇓ r => ⌜ r = v.val[i.val]! ⌝ ⦄ := by
  rw [vec_index_spec v i h]
  exact Hax.triple_of_ok rfl rfl

@[spec]
theorem vec_index_mut_spec {T : Type} [Inhabited T] (v : alloc.vec.Vec T) (i : Std.Usize) (h : i.val < v.length) :
    ⦃ ⌜ True ⌝ ⦄
    alloc.vec.Vec.Insts.CoreOpsIndexIndexMut.index_mut (core.Usize.Insts.CoreSliceIndexSliceIndexSliceT T) v i
    ⦃ ⇓ r => ⌜ r.1 = v.val[i.val]! ∧ ∀ x, (r.2 x).val = v.val.set i.val x ⌝ ⦄ := by
  hax_mvcgen [alloc.vec.Vec.Insts.CoreOpsIndexIndexMut.index_mut,
    core.Slice.Insts.CoreOpsIndexIndexMut.index_mut,
    core.Usize.Insts.CoreSliceIndexSliceIndexSliceT.get_unchecked_mut]
  case vc1.hQ r1 r2 hr =>
    obtain ⟨hlt, rfl, rfl⟩ := hr
    refine ⟨by simp [getElem!_pos, hlt], fun x => ?_⟩
    show (Slice.set v i x).val = _
    simp [Slice.set, Slice.setAtNat]
  case vc2.h_fail hge => exact absurd h (by omega)

@[spec]
theorem slice_len_triple {T : Type} (s : Slice T) :
    ⦃ ⌜ True ⌝ ⦄ core.slice.Slice.len s ⦃ ⇓ r => ⌜ r = s.len ⌝ ⦄ :=
  Hax.triple_of_ok (by simp [core.slice.Slice.len, rust_primitives.slice.slice_length]) rfl

@[spec]
theorem from_elem_triple (x : verifier.field.E) (n : Std.Usize) :
    ⦃ ⌜ True ⌝ ⦄ alloc.vec.from_elem verifier.field.E.Insts.CoreCloneClone x n
    ⦃ ⇓ v => ⌜ v.val = List.replicate n.val x ⌝ ⦄ := by
  have hm : ∀ m, (List.replicate m x).mapM verifier.field.E.Insts.CoreCloneClone.clone = ok (List.replicate m x) := by
    intro m
    rw [show verifier.field.E.Insts.CoreCloneClone.clone = fun s => pure (id s) from rfl, List.mapM_pure,
      List.map_id]
    rfl
  simp only [alloc.vec.from_elem, rust_primitives.sequence.seq_create]
  split_ifs with h0
  · exact Hax.triple_of_ok (Aeneas.Std.bind_ok _ _) (by simp only [h0, List.replicate_zero]; rfl)
  · have hn : List.replicate (n.val - 1) x ++ [x] = List.replicate n.val x := by
      rw [← List.replicate_succ', Nat.sub_add_cancel (by omega)]
    have hb : (List.replicate (n.val - 1) x ++ [x]).length ≤ Usize.max := by
      rw [hn, List.length_replicate]; scalar_tac
    rw [hm, RustM.match.ok]
    simp only [dite_eq_left hb]
    exact Hax.triple_of_ok (Aeneas.Std.bind_ok _ _) (by rw [← hn]; exact Data.ListN.ListN.from_to_inverse)
@[spec]
theorem vec_new_triple (T : Type) :
    ⦃ ⌜ True ⌝ ⦄ alloc.vec.Vec.new T ⦃ ⇓ v => ⌜ v.val = [] ⌝ ⦄ := by
  simp only [alloc.vec.Vec.new, rust_primitives.sequence.seq_empty]
  exact Hax.triple_of_ok (Aeneas.Std.bind_ok _ _) rfl

@[spec]
theorem vec_push_triple {T : Type} (v : alloc.vec.Vec T) (x : T) (h : v.length < Usize.max) :
    ⦃ ⌜ True ⌝ ⦄ alloc.vec.Vec.push v x ⦃ ⇓ r => ⌜ r.val = v.val ++ [x] ⌝ ⦄ := by
  have h' : (v.val ++ [x]).length ≤ Usize.max := by
    have : v.val.length < Usize.max := h
    simp; omega
  simp only [alloc.vec.Vec.push, rust_primitives.sequence.seq_push, dite_eq_left h']
  exact Hax.triple_of_ok (Aeneas.Std.bind_ok _ _) Data.ListN.ListN.from_to_inverse

theorem getElem!_set {α : Type} [Inhabited α] (l : List α) (a j : ℕ) (x : α) :
    (l.set a x)[j]! = if a = j ∧ j < l.length then x else l[j]! := by
  by_cases h : a = j
  · subst h
    by_cases hj : a < l.length <;> simp [hj]
  · simp [h]

@[simp] theorem holds_ok (P : Prop) : (ok P : RustM Prop).holds ↔ P := by
  simp [RustM.holds, Triple, WP.wp, PredTrans.apply]

@[simp] theorem wp_ok_prop (P : Prop) :
    (wp⟦(ok P : RustM Prop)⟧ (PostCond.noThrow fun p => ⌜p⌝)).down ↔ P := by
  simp [WP.wp, PredTrans.apply]
theorem one_shl (k : Std.Usize) (hk : k.val ≤ 8) : (1#usize).val <<< k.val % Usize.size = 2 ^ k.val := by
  have : 2 ^ k.val ≤ 2 ^ 8 := Nat.pow_le_pow_right (by omega) hk
  have hs : 2 ^ 8 < Usize.size := by
    rw [Usize.size_def]
    exact Nat.pow_lt_pow_right (by omega) (by cases System.Platform.numBits_eq <;> simp [Usize.numBits, *])
  have h1 : (1#usize).val = 1 := by simp
  rw [h1, Nat.one_shiftLeft, Nat.mod_eq_of_lt (by omega)]
end Verifier
