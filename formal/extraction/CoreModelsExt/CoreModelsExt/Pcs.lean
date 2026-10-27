-- Models first needed by crates/pcs, of Rust standard library items the pinned hax-lean
-- CoreModels lacks. Each is a candidate for upstreaming there. A `def` mirrors the Rust
-- semantics; an `opaque` is an assumption about an item whose body is not modelled.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt.LeanCompiler
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

namespace CoreModels

/-! ## Floating point -/

/-- `f64`, the name Aeneas gives it: an IEEE 754 binary64, as Lean's `Float` is. -/
abbrev F64 := Float

/-- The derived-like `Clone` of `f64`: a copy. -/
def core.F64.Insts.CoreCloneClone.clone (x : F64) : RustM F64 :=
  ok x

/-! ## Integers and `Ord` -/

/-- `Ord::clamp`, projected from the dictionary: `max(min, min(self, max))`, a panic unless
`min <= max`. -/
abbrev core.cmp.Ord.clamp {Self : Type} (OrdInst : core.cmp.Ord Self) (self min max : Self) :
    RustM Self :=
  core.cmp.clamp OrdInst self min max

/-! ## Strings and formatting -/

/-- `Arguments::from_str`, the message of a `panic!` or `assert!` with a literal: CoreModels'
`Arguments` is `Unit`. -/
def core.fmt.Arguments.from_str (_ : Str) : RustM core.fmt.Arguments :=
  ok ()

/-- `Argument::new_display`: a value to format with `Display`. -/
opaque core.fmt.rt.Argument.new_display {T : Type} (DisplayInst : core.fmt.Display T) :
    T → RustM core.fmt.rt.Argument

/-- `alloc::fmt::format`, `format!`'s string. -/
opaque alloc.fmt.format : core.fmt.Arguments → RustM alloc.string.String

/-! ## Uninitialized memory -/

/-- `MaybeUninit<T>`: a `T` that may not be initialized yet, which has no model. -/
opaque core.mem.maybe_uninit.MaybeUninit (T : Type) : Type

end CoreModels
