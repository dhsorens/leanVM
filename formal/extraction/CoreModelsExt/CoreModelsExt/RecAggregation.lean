-- Models first needed by crates/rec_aggregation, of Rust standard library items the pinned
-- hax-lean CoreModels lacks. Each is a candidate for upstreaming there.
module
public import Aeneas
public import CoreModels
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

namespace CoreModels

/-- `f64`, which Aeneas names `F64`: an IEEE 754 binary64 value, as Lean's `Float` is. Only the
type; Aeneas translates no float arithmetic. -/
abbrev F64 : Type := Float

/-- `usize::trailing_zeros`: the index of the lowest set bit, `usize::BITS` for zero. -/
def core.num.Usize.trailing_zeros (x : Std.Usize) : RustM Std.U32 :=
  let bits := Std.UScalarTy.Usize.numBits
  ok ⟨BitVec.ofNat 32 (((List.range bits).find? fun i => x.val.testBit i).getD bits)⟩

/-- `usize::next_power_of_two`: the least power of two at least `x` (`1` for zero). Its
overflow panics, as overflow does throughout the extraction (Rust's debug semantics). -/
def core.num.Usize.next_power_of_two (x : Std.Usize) : RustM Std.Usize :=
  let p := 2 ^ Nat.log2 (2 * x.val - 1)
  if h : p < 2 ^ Std.UScalarTy.Usize.numBits then ok ⟨BitVec.ofNatLT p h⟩ else fail .panic

/-- `fmt::Arguments::from_str`, a message without arguments. `fmt.Arguments` is `Unit` in
CoreModels, as its `Arguments::new` is. -/
def core.fmt.Arguments.from_str (_s : Str) : RustM core.fmt.Arguments :=
  ok ()

end CoreModels
