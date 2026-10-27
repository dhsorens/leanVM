-- Models first needed by crates/fiat_shamir and crates/keccak_gkr, of Rust standard library
-- items the pinned hax-lean CoreModels lacks. Each is a candidate for upstreaming there. A `def`
-- mirrors the Rust semantics; an `opaque` is an assumption about an item whose body is not
-- modelled.
module
public import Aeneas
public import CoreModels
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

namespace CoreModels

/-! ## Formatting -/

/-- `Arguments::from_str`, the message of a `panic!` or `assert!` with a literal: CoreModels'
`Arguments` is `Unit`. -/
def core.fmt.Arguments.from_str (_ : Str) : RustM core.fmt.Arguments :=
  ok ()

/-! ## Slices and vectors -/

/-- `<[T]>::sort_unstable`: the slice sorted ascending by `Ord::cmp`. -/
opaque core.slice.Slice.sort_unstable {T : Type} (OrdInst : core.cmp.Ord T) :
    Slice T → RustM (Slice T)

/-- `Vec::dedup`: each run of consecutive equal elements cut down to its first. -/
opaque alloc.vec.Vec.dedup {T : Type} (PartialEqInst : core.cmp.PartialEq T T) :
    alloc.vec.Vec T → RustM (alloc.vec.Vec T)

end CoreModels
