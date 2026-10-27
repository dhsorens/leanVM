-- Models first needed by crates/primitives, of Rust standard library items the pinned
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

/-- `usize::trailing_zeros`: the index of the lowest set bit, the width for zero. -/
def core.num.Usize.trailing_zeros (x : Std.Usize) : RustM Std.U32 :=
  let w := System.Platform.numBits
  ok ⟨BitVec.ofNat 32 (((List.range w).find? fun i => x.val.testBit i).getD w)⟩

/-! ## Formatting

A panic message's arguments carry no data in CoreModels (`fmt::Arguments` is `Unit`). -/

/-- `fmt::rt::Argument::new_display`, the argument a `{}` placeholder formats. -/
def core.fmt.rt.Argument.new_display {T : Type} (_ : core.fmt.Display T) (_ : T) :
    RustM core.fmt.rt.Argument :=
  ok ⟨.Placeholder ()⟩

/-! ## Iterators -/

/-- `Zip::fold`: the default fold over the pairs `Zip::next` yields. -/
abbrev core.iter.adapters.zip.Zip.Insts.CoreIterTraitsIteratorIteratorPair.fold
    {I1 I2 Item1 Item2 B F : Type}
    (It1 : core.iter.traits.iterator.Iterator I1 Item1)
    (It2 : core.iter.traits.iterator.Iterator I2 Item2)
    (FnInst : core.ops.function.FnMut F (B × (Item1 × Item2)) B)
    (self : core.iter.adapters.zip.Zip I1 I2) (init : B) (f : F) : RustM B :=
  core.iter.traits.iterator.Iterator.fold.default
    (core.iter.adapters.zip.Zip.Insts.CoreIterTraitsIteratorIteratorPair It1 It2) FnInst self init f

/-- `Rev::fold`: the default fold over the items `Rev::next` yields, back to front. -/
abbrev core.iter.adapters.rev.Rev.Insts.CoreIterTraitsIteratorIterator.fold
    {I Item B F : Type}
    (BackInst : core.iter.traits.double_ended.DoubleEndedIterator I Item)
    (FnInst : core.ops.function.FnMut F (B × Item) B)
    (self : core.iter.adapters.rev.Rev I) (init : B) (f : F) : RustM B :=
  core.iter.traits.iterator.Iterator.fold.default
    (core.iter.adapters.rev.Rev.Insts.CoreIterTraitsIteratorIterator BackInst) FnInst self init f

/-! ## Memory -/

/-- `MaybeUninit<T>`: a slot that may not hold a `T` yet. Its contents are not modelled. -/
opaque core.mem.maybe_uninit.MaybeUninit (T : Type) : Type

/-- The `ToString` trait: its one method, `to_string`. -/
structure alloc.string.ToString (Self : Type) where
  to_string : Self → RustM alloc.string.String

end CoreModels
