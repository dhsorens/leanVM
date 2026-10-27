-- Models of Rust standard library items the extraction uses and the pinned
-- hax-lean CoreModels lacks. Each is a candidate for upstreaming there. A `def`
-- mirrors the Rust semantics; an `opaque` is an assumption about an item whose
-- body is not modelled.
module
public import Aeneas
public import CoreModels
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

namespace CoreModels

/-! ## Integers -/

/-- `u64::reverse_bits`: bit `i` of the result is bit `63 - i` of the operand. -/
def core.num.U64.reverse_bits (x : Std.U64) : RustM Std.U64 :=
  ok ⟨x.bv.reverse⟩

/-- `u64::trailing_zeros`: the index of the lowest set bit, `64` for zero. -/
def core.num.U64.trailing_zeros (x : Std.U64) : RustM Std.U32 :=
  ok ⟨BitVec.ofNat 32 (((List.range 64).find? fun i => x.val.testBit i).getD 64)⟩

/-- `u64::checked_shl`: `None` when the shift is at least the width. -/
def core.num.U64.checked_shl (x : Std.U64) (rhs : Std.U32) :
    RustM (core.option.Option Std.U64) :=
  if rhs.val < 64 then ok (.Some ⟨x.bv <<< rhs.val⟩) else ok .None

/-! ## `Ord`, `bool`, ranges -/

/-- `Ord::min`, projected from the dictionary: `other` exactly when `other < self`. -/
abbrev core.cmp.Ord.min {Self : Type} (OrdInst : core.cmp.Ord Self) (self other : Self) :
    RustM Self :=
  core.cmp.min OrdInst self other

/-- `Ord::max`, projected from the dictionary: `other` unless `other < self`. -/
abbrev core.cmp.Ord.max {Self : Type} (OrdInst : core.cmp.Ord Self) (self other : Self) :
    RustM Self :=
  core.cmp.max OrdInst self other

/-- `bool::then`: `if self { Some(f()) } else { None }`. -/
def core.bool.Bool.then {T F : Type} (FnOnceInst : core.ops.function.FnOnce F Unit T)
    (self : Bool) (f : F) : RustM (core.option.Option T) :=
  if self then do
    let x ← FnOnceInst.call_once f ()
    ok (.Some x)
  else ok .None

/-- `Range::contains`, the inherent method: `RangeBounds::contains`. The first dictionary is
the impl block's `Idx: PartialOrd<Idx>` bound, which the body does not use. -/
def core.ops.range.Range.contains {Idx U : Type} (_ : core.cmp.PartialOrd Idx Idx)
    (IdxU : core.cmp.PartialOrd Idx U) (UIdx : core.cmp.PartialOrd U Idx)
    (self : core.ops.range.Range Idx) (item : U) : RustM Bool :=
  core.ops.range.RangeBounds.contains.default
    (core.ops.range.Range.Insts.CoreOpsRangeRangeBounds Idx) IdxU UIdx self item

/-- The derived `Clone` of `Range`: both bounds cloned. -/
def core.ops.range.Range.Insts.CoreCloneClone.clone {Idx : Type}
    (CloneInst : core.clone.Clone Idx) (self : core.ops.range.Range Idx) :
    RustM (core.ops.range.Range Idx) := do
  let start ← CloneInst.clone self.start
  let «end» ← CloneInst.clone self.end
  ok { start, «end» }

/-- The derived `PartialEq` of `Range`: both bounds equal. -/
def core.ops.range.Range.Insts.CoreCmpPartialEqRange.eq {Idx : Type}
    (EqInst : core.cmp.PartialEq Idx Idx) (self other : core.ops.range.Range Idx) :
    RustM Bool := do
  let start ← EqInst.eq self.start other.start
  if start then EqInst.eq self.end other.end else ok false

/-! ## Iterators -/

/-- `Iterator::fold`, projected from the dictionary; CoreModels' `Iterator` carries only `next`. -/
abbrev core.iter.traits.iterator.Iterator.fold {Self Item : Type}
    (IteratorInst : core.iter.traits.iterator.Iterator Self Item) {B F : Type}
    (FnInst : core.ops.function.FnMut F (B × Item) B) (self : Self) (init : B) (f : F) :
    RustM B :=
  core.iter.traits.iterator.Iterator.fold.default IteratorInst FnInst self init f

/-! ## Strings -/

/-- `String::as_bytes`, its UTF-8 encoding. -/
opaque alloc.string.String.as_bytes : alloc.string.String → RustM (Slice Std.U8)

/-! ## `BTreeMap`

An ordered map, assumed: the type and the operations the extraction calls are opaque. -/

/-- `Clone` for the global allocator, the `A: Allocator + Clone` bound of `BTreeMap`'s methods. -/
def alloc.alloc.Global.Insts.CoreAllocAllocatorClone : core.clone.Clone alloc.alloc.Global where
  clone := fun g => ok g
  clone_from := fun _ g => ok g

/-- Some `Ord` dictionary exists at every type: the witness `opaque` needs, nothing more. -/
local instance {X : Type} : Inhabited (core.cmp.Ord X) :=
  let eq : core.cmp.PartialEq X X := { eq := fun _ _ => ok true, ne := fun _ _ => ok false }
  ⟨{ EqInst := { PartialEqInst := eq }
     PartialOrdInst :=
       { PartialEqInst := eq, partial_cmp := fun _ _ => ok .None, lt := fun _ _ => ok false,
         le := fun _ _ => ok true, gt := fun _ _ => ok false, ge := fun _ _ => ok true }
     cmp := fun _ _ => ok .Equal }⟩

/-- `Ord` for `Vec<T, A>`, lexicographic: the order of `BTreeMap`'s keys. -/
opaque alloc.vec.Vec.Insts.CoreCmpOrd (A : Type) {T : Type} (OrdInst : core.cmp.Ord T) :
    core.cmp.Ord (alloc.vec.Vec T)

opaque alloc.collections.btree.map.BTreeMap (K V A : Type) : Type

opaque alloc.collections.btree.map.Iter (K V : Type) : Type

opaque alloc.collections.btree.map.entry.Entry (K V A : Type) : Type

opaque alloc.collections.btree.map.BTreeMapKVGlobal.Insts.CoreDefaultDefault.default
    (K V : Type) : RustM (alloc.collections.btree.map.BTreeMap K V alloc.alloc.Global)

opaque alloc.collections.btree.map.BTreeMapKVGlobal.Insts.CoreConvertFromArrayPairN.from
    {K V : Type} {N : Std.Usize} (OrdInst : core.cmp.Ord K) (entries : Aeneas.Std.Array (K × V) N) :
    RustM (alloc.collections.btree.map.BTreeMap K V alloc.alloc.Global)

opaque alloc.collections.btree.map.BTreeMap.Insts.CoreCloneClone.clone {K V A : Type}
    (CloneK : core.clone.Clone K) (CloneV : core.clone.Clone V) (CloneA : core.clone.Clone A)
    (self : alloc.collections.btree.map.BTreeMap K V A) :
    RustM (alloc.collections.btree.map.BTreeMap K V A)

opaque alloc.collections.btree.map.BTreeMap.iter {K V A : Type} (CloneA : core.clone.Clone A)
    (self : alloc.collections.btree.map.BTreeMap K V A) :
    RustM (alloc.collections.btree.map.Iter K V)

opaque alloc.SharedABTreeMap.Insts.CoreIterTraitsCollectIntoIteratorPairSharedAKSharedAVIter.into_iter
    {K V A : Type} (CloneA : core.clone.Clone A) (self : alloc.collections.btree.map.BTreeMap K V A) :
    RustM (alloc.collections.btree.map.Iter K V)

opaque alloc.collections.btree.map.Iter.Insts.CoreIterTraitsIteratorIteratorPairSharedAKSharedAV.next
    {K V : Type} (self : alloc.collections.btree.map.Iter K V) :
    RustM (core.option.Option (K × V) × alloc.collections.btree.map.Iter K V)

/-- The `Iterator` of `btree_map::Iter`, over its entries in key order. -/
@[reducible]
def alloc.collections.btree.map.Iter.Insts.CoreIterTraitsIteratorIteratorPairSharedAKSharedAV
    (K V : Type) :
    core.iter.traits.iterator.Iterator (alloc.collections.btree.map.Iter K V) (K × V) where
  next := alloc.collections.btree.map.Iter.Insts.CoreIterTraitsIteratorIteratorPairSharedAKSharedAV.next

opaque alloc.collections.btree.map.BTreeMap.entry {K V A : Type} (CloneA : core.clone.Clone A)
    (OrdInst : core.cmp.Ord K) (self : alloc.collections.btree.map.BTreeMap K V A) (key : K) :
    RustM (alloc.collections.btree.map.entry.Entry K V A ×
      (alloc.collections.btree.map.entry.Entry K V A → alloc.collections.btree.map.BTreeMap K V A))

opaque alloc.collections.btree.map.entry.Entry.or_default {K V A : Type} (OrdInst : core.cmp.Ord K)
    (DefaultInst : core.default.Default V) (CloneA : core.clone.Clone A)
    (self : alloc.collections.btree.map.entry.Entry K V A) :
    RustM (V × (V → alloc.collections.btree.map.entry.Entry K V A))

end CoreModels
