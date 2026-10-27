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

/-! ## Integers -/

/-- `usize::trailing_zeros`: the index of the lowest set bit, the width for zero. -/
def core.num.Usize.trailing_zeros (x : Std.Usize) : RustM Std.U32 :=
  ok ⟨BitVec.ofNat 32
    (((List.range Std.UScalarTy.Usize.numBits).find? fun i => x.val.testBit i).getD
      Std.UScalarTy.Usize.numBits)⟩

/-- `usize::next_power_of_two`: the least power of two at least `x` (one for zero), a panic
where that overflows, as with overflow checks on. -/
def core.num.Usize.next_power_of_two (x : Std.Usize) : RustM Std.Usize :=
  let p := if x.val ≤ 1 then 1 else 2 ^ (Nat.log2 (x.val - 1) + 1)
  if h : p < 2 ^ Std.UScalarTy.Usize.numBits then ok (Std.UScalar.ofNatCore p h)
  else fail .panic

/-- `usize::next_multiple_of`: the least multiple of `rhs` at least `x`, a panic for a zero
`rhs` or where that overflows. -/
def core.num.Usize.next_multiple_of (x rhs : Std.Usize) : RustM Std.Usize :=
  if rhs.val = 0 then fail .panic
  else
    let m := (x.val + rhs.val - 1) / rhs.val * rhs.val
    if h : m < 2 ^ Std.UScalarTy.Usize.numBits then ok (Std.UScalar.ofNatCore m h)
    else fail .panic

/-! ## Arrays -/

/-- `<&[T; N]>::try_from(&[T])`: the slice as an array when it has `N` elements. -/
def core.SharedAArray.Insts.CoreConvertTryFromSharedASliceTryFromSliceError.try_from {T : Type}
    (N : Std.Usize) (s : Slice T) :
    RustM (core.result.Result (Std.Array T N) core.array.TryFromSliceError) :=
  if h : s.val.length = N.val then ok (.Ok (Std.Array.make N s.val h)) else ok (.Err ())

/-! ## Raw pointers -/

/-- `<[T]>::as_mut_ptr`. -/
opaque core.slice.Slice.as_mut_ptr {T : Type} : Slice T → RustM (MutRawPtr T × Slice T)

/-- `<*mut T>::cast`. -/
opaque core.ptr.mut_ptr.RawPtrMutT.cast {T : Type} (U : Type) : MutRawPtr T → RustM (MutRawPtr U)

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
