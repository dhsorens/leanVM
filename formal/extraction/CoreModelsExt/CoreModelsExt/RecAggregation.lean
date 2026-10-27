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

/-- `usize::trailing_zeros`: the index of the lowest set bit, `usize::BITS` for zero. -/
def core.num.Usize.trailing_zeros (x : Std.Usize) : RustM Std.U32 :=
  let bits := Std.UScalarTy.Usize.numBits
  ok ⟨BitVec.ofNat 32 (((List.range bits).find? fun i => x.val.testBit i).getD bits)⟩

/-- `usize::next_power_of_two`: the least power of two at least `x` (`1` for zero). Its
overflow panics, as overflow does throughout the extraction (Rust's debug semantics). -/
def core.num.Usize.next_power_of_two (x : Std.Usize) : RustM Std.Usize :=
  let p := 2 ^ Nat.log2 (2 * x.val - 1)
  if h : p < 2 ^ Std.UScalarTy.Usize.numBits then ok ⟨BitVec.ofNatLT p h⟩ else fail .panic

end CoreModels
