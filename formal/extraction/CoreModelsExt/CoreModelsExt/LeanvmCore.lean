-- Models first needed by crates/leanvm_core, of Rust standard library items the pinned
-- hax-lean CoreModels lacks. Each is a candidate for upstreaming there. A `def` mirrors the
-- Rust semantics; an `opaque` is an assumption about an item whose body is not modelled.
module
public import Aeneas
public import CoreModels
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

/-- `String: Clone`, a copy. -/
def alloc.string.String.Insts.CoreCloneClone.clone (self : alloc.string.String) :
    RustM alloc.string.String :=
  ok self

/-- `String: Clone`. -/
def alloc.string.String.Insts.CoreCloneClone : core.clone.Clone alloc.string.String where
  clone := alloc.string.String.Insts.CoreCloneClone.clone
  clone_from := fun _ s => ok s

/-- `fmt::rt::Argument::new_debug`: an argument of a format string. CoreModels' `Arguments` carry
no text, so the argument is the placeholder every other one is. -/
def core.fmt.rt.Argument.new_debug {T : Type} (_ : core.fmt.Debug T) (_ : T) :
    RustM core.fmt.rt.Argument :=
  ok { ty := .Placeholder () }

/-! ## `HashMap`

A hashed map, assumed: the type and the operations the extraction calls are opaque. -/

/-- `std::hash::RandomState`, the default hasher builder. -/
opaque std.hash.random.RandomState : Type

/-- `RandomState: Clone`. -/
def std.hash.random.RandomState.Insts.CoreCloneClone : core.clone.Clone std.hash.random.RandomState where
  clone := fun s => ok s
  clone_from := fun _ s => ok s

/-- `std::collections::HashMap<K, V, S, A>`. -/
opaque std.collections.hash.map.HashMap (K V S A : Type) : Type

/-- `HashMap: Clone`, entry by entry. -/
opaque std.collections.hash.map.HashMap.Insts.CoreCloneClone.clone {K V S A : Type}
    (CloneK : core.clone.Clone K) (CloneV : core.clone.Clone V) (CloneS : core.clone.Clone S)
    (CloneA : core.clone.Clone A) (self : std.collections.hash.map.HashMap K V S A) :
    RustM (std.collections.hash.map.HashMap K V S A)

end CoreModels
