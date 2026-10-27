-- Models first needed by crates/leanvm_core, of Rust standard library items the pinned
-- hax-lean CoreModels lacks. Each is a candidate for upstreaming there. A `def` mirrors the
-- Rust semantics; an `opaque` is an assumption about an item whose body is not modelled.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt.LeanCompiler
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

namespace CoreModels

/-! ## Iterators -/

/-- `Zip::fold`, the default `fold` over the zipped pairs. -/
abbrev core.iter.adapters.zip.Zip.Insts.CoreIterTraitsIteratorIteratorPair.fold
    {I1 I2 A B Acc G : Type} (Inst1 : core.iter.traits.iterator.Iterator I1 A)
    (Inst2 : core.iter.traits.iterator.Iterator I2 B)
    (FoldFnInst : core.ops.function.FnMut G (Acc × (A × B)) Acc) :=
  core.iter.traits.iterator.Iterator.fold.default
    (core.iter.adapters.zip.Zip.Insts.CoreIterTraitsIteratorIteratorPair Inst1 Inst2) FoldFnInst

/-! ## Strings and formatting -/

/-- `fmt::rt::Argument::new_debug`: an argument of a format string. CoreModels' `Arguments` carry
no text, so the argument is the placeholder every other one is. -/
def core.fmt.rt.Argument.new_debug {T : Type} (_ : core.fmt.Debug T) (_ : T) :
    RustM core.fmt.rt.Argument :=
  ok { ty := .Placeholder () }

end CoreModels
