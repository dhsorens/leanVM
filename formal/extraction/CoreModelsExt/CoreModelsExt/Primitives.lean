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

/-! ## Formatting

A panic message's arguments carry no data in CoreModels (`fmt::Arguments` is `Unit`). -/

/-- `fmt::rt::Argument::new_display`, the argument a `{}` placeholder formats. -/
def core.fmt.rt.Argument.new_display {T : Type} (_ : core.fmt.Display T) (_ : T) :
    RustM core.fmt.rt.Argument :=
  ok ⟨.Placeholder ()⟩

/-! ## Iterators -/

/-- `Rev::fold`: the default fold over the items `Rev::next` yields, back to front. -/
abbrev core.iter.adapters.rev.Rev.Insts.CoreIterTraitsIteratorIterator.fold
    {I Item B F : Type}
    (BackInst : core.iter.traits.double_ended.DoubleEndedIterator I Item)
    (FnInst : core.ops.function.FnMut F (B × Item) B)
    (self : core.iter.adapters.rev.Rev I) (init : B) (f : F) : RustM B :=
  core.iter.traits.iterator.Iterator.fold.default
    (core.iter.adapters.rev.Rev.Insts.CoreIterTraitsIteratorIterator BackInst) FnInst self init f

/-! ## Memory -/

/-- The `ToString` trait: its one method, `to_string`. -/
structure alloc.string.ToString (Self : Type) where
  to_string : Self → RustM alloc.string.String

end CoreModels
