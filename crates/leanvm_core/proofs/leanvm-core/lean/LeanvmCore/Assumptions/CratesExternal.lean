-- [leanvm_core]: the items of other workspace crates the extraction uses.
-- Aeneas leaves an item of another crate undeclared, expecting a library to provide it; until
-- the crates' extractions are linked, this file declares them, by hand. A type mirrors its Rust
-- definition (a one-field struct is its field, as Aeneas renders one), and so do the constants,
-- the additive structure and the derived impls; any other function is an axiom with the
-- signature the generated code expects, and a type the generated code never looks into is an
-- axiom too.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

/-! ## `primitives::field`: `K = GF(2^64)` and `E = GF(2^192)` -/

/-- [primitives::field::gf2_64::F64]: `struct F64(pub u64)`. -/
@[reducible]
def primitives.field.gf2_64.F64 := Std.U64

/-- [primitives::field::gf2_64x3::F192]: `struct F192 { c0, c1, c2: u64 }`. -/
structure primitives.field.gf2_64x3.F192 where
  c0 : Std.U64
  c1 : Std.U64
  c2 : Std.U64

/-- [primitives::field::gf2_64x3::F192Unreduced]: `struct F192Unreduced { coeffs: [[u64; 2]; 3] }`. -/
structure primitives.field.gf2_64x3.F192Unreduced where
  coeffs : Array (Array Std.U64 2#usize) 3#usize

/-- [primitives::field::gf2_64::F64::ZERO] -/
def primitives.field.gf2_64.F64.ZERO : RustM primitives.field.gf2_64.F64 :=
  ok 0#u64

/-- [primitives::field::gf2_64::F64::ONE] -/
def primitives.field.gf2_64.F64.ONE : RustM primitives.field.gf2_64.F64 :=
  ok 1#u64

/-- The derived `Clone` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreCloneClone : core.clone.Clone primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreCloneClone

/-- The derived `Copy` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreMarkerCopy : core.marker.Copy primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreMarkerCopy

/-- The derived `PartialEq` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreCmpPartialEqF64 :
    core.cmp.PartialEq primitives.field.gf2_64.F64 primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreCmpPartialEqU64

/-- `F64 + F64`: XOR. -/
def primitives.field.gf2_64.F64.Insts.CoreOpsArithAddF64F64.add
    (x y : primitives.field.gf2_64.F64) : RustM primitives.field.gf2_64.F64 :=
  ok (x ^^^ y)

/-- `Add` for `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreOpsArithAddF64F64 :
    core.ops.arith.Add primitives.field.gf2_64.F64 primitives.field.gf2_64.F64
      primitives.field.gf2_64.F64 where
  add := primitives.field.gf2_64.F64.Insts.CoreOpsArithAddF64F64.add

/-- [primitives::field::gf2_64::F64::mul]: the product in `GF(2^64)`. -/
axiom primitives.field.gf2_64.F64.Insts.CoreOpsArithMulF64F64.mul :
  primitives.field.gf2_64.F64 → primitives.field.gf2_64.F64 → RustM primitives.field.gf2_64.F64

/-- `Mul` for `F64`. -/
@[reducible]
noncomputable def primitives.field.gf2_64.F64.Insts.CoreOpsArithMulF64F64 :
    core.ops.arith.Mul primitives.field.gf2_64.F64 primitives.field.gf2_64.F64
      primitives.field.gf2_64.F64 where
  mul := primitives.field.gf2_64.F64.Insts.CoreOpsArithMulF64F64.mul

/-- [primitives::field::mul_by_g]: the product by the generator `g = x`, a shift and a fold of
the carry by `x^64 = x^4 + x^3 + x + 1`. -/
def primitives.field.mul_by_g (a : primitives.field.gf2_64.F64) : RustM primitives.field.gf2_64.F64 :=
  ok ⟨(a.bv <<< 1) ^^^ (if a.bv.msb then 0x1B#64 else 0#64)⟩

/-- [primitives::field::gf2_64x3::F192::ZERO] -/
def primitives.field.gf2_64x3.F192.ZERO : RustM primitives.field.gf2_64x3.F192 :=
  ok { c0 := 0#u64, c1 := 0#u64, c2 := 0#u64 }

/-- [primitives::field::gf2_64x3::F192::ONE] -/
def primitives.field.gf2_64x3.F192.ONE : RustM primitives.field.gf2_64x3.F192 :=
  ok { c0 := 1#u64, c1 := 0#u64, c2 := 0#u64 }

/-- The derived `Clone` of `F192`, a copy. -/
def primitives.field.gf2_64x3.F192.Insts.CoreCloneClone.clone
    (x : primitives.field.gf2_64x3.F192) : RustM primitives.field.gf2_64x3.F192 :=
  ok x

/-- The derived `Clone` of `F192`. -/
@[reducible]
def primitives.field.gf2_64x3.F192.Insts.CoreCloneClone :
    core.clone.Clone primitives.field.gf2_64x3.F192 where
  clone := primitives.field.gf2_64x3.F192.Insts.CoreCloneClone.clone
  clone_from := fun _ x => ok x

/-- The derived `Copy` of `F192`. -/
@[reducible]
def primitives.field.gf2_64x3.F192.Insts.CoreMarkerCopy :
    core.marker.Copy primitives.field.gf2_64x3.F192 where
  cloneCloneInst := primitives.field.gf2_64x3.F192.Insts.CoreCloneClone

/-- `F192 + F192`: XOR, coefficient by coefficient. -/
def primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddF192F192.add
    (x y : primitives.field.gf2_64x3.F192) : RustM primitives.field.gf2_64x3.F192 :=
  ok { c0 := x.c0 ^^^ y.c0, c1 := x.c1 ^^^ y.c1, c2 := x.c2 ^^^ y.c2 }

/-- `Add` for `F192`. -/
@[reducible]
def primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddF192F192 :
    core.ops.arith.Add primitives.field.gf2_64x3.F192 primitives.field.gf2_64x3.F192
      primitives.field.gf2_64x3.F192 where
  add := primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddF192F192.add

/-- [primitives::field::gf2_64x3::F192::mul]: the product in `GF(2^192)`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulF192F192.mul :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 →
    RustM primitives.field.gf2_64x3.F192

/-- `Mul` for `F192`. -/
@[reducible]
noncomputable def primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulF192F192 :
    core.ops.arith.Mul primitives.field.gf2_64x3.F192 primitives.field.gf2_64x3.F192
      primitives.field.gf2_64x3.F192 where
  mul := primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulF192F192.mul

/-- [primitives::field::gf2_64x3::F192::mul_base]: the product by an element of `K`. -/
axiom primitives.field.gf2_64x3.F192.mul_base :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64.F64 →
    RustM primitives.field.gf2_64x3.F192

/-- [primitives::field::gf2_64x3::F192::mul_unreduced] -/
axiom primitives.field.gf2_64x3.F192.mul_unreduced :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 →
    RustM primitives.field.gf2_64x3.F192Unreduced

/-- [primitives::field::gf2_64x3::F192::mul_base_unreduced] -/
axiom primitives.field.gf2_64x3.F192.mul_base_unreduced :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64.F64 →
    RustM primitives.field.gf2_64x3.F192Unreduced

/-- [primitives::field::gf2_64x3::F192Unreduced::ZERO] -/
def primitives.field.gf2_64x3.F192Unreduced.ZERO : RustM primitives.field.gf2_64x3.F192Unreduced :=
  ok { coeffs := Array.repeat 3#usize (Array.repeat 2#usize 0#u64) }

/-- The derived `Clone` of `F192Unreduced`, a copy. -/
@[reducible]
def primitives.field.gf2_64x3.F192Unreduced.Insts.CoreCloneClone :
    core.clone.Clone primitives.field.gf2_64x3.F192Unreduced where
  clone := fun x => ok x
  clone_from := fun _ x => ok x

/-- The derived `Copy` of `F192Unreduced`. -/
@[reducible]
def primitives.field.gf2_64x3.F192Unreduced.Insts.CoreMarkerCopy :
    core.marker.Copy primitives.field.gf2_64x3.F192Unreduced where
  cloneCloneInst := primitives.field.gf2_64x3.F192Unreduced.Insts.CoreCloneClone

/-- `F192Unreduced::from(F192)`: each coefficient as its own 128-bit polynomial. -/
def primitives.field.gf2_64x3.F192Unreduced.Insts.CoreConvertFromF192.from
    (e : primitives.field.gf2_64x3.F192) : RustM primitives.field.gf2_64x3.F192Unreduced :=
  ok { coeffs := Array.make 3#usize [Array.make 2#usize [e.c0, 0#u64], Array.make 2#usize [e.c1, 0#u64],
    Array.make 2#usize [e.c2, 0#u64]] }

/-- `From<F192>` for `F192Unreduced`. -/
@[reducible]
def primitives.field.gf2_64x3.F192Unreduced.Insts.CoreConvertFromF192 :
    core.convert.From primitives.field.gf2_64x3.F192Unreduced primitives.field.gf2_64x3.F192 where
  «from» := primitives.field.gf2_64x3.F192Unreduced.Insts.CoreConvertFromF192.from

/-- `F192Unreduced ^ F192Unreduced`: XOR of the coefficient words. -/
axiom primitives.field.gf2_64x3.F192Unreduced.Insts.CoreOpsBitBitXorF192UnreducedF192Unreduced.bitxor :
  primitives.field.gf2_64x3.F192Unreduced → primitives.field.gf2_64x3.F192Unreduced →
    RustM primitives.field.gf2_64x3.F192Unreduced

/-- `BitXor` for `F192Unreduced`. -/
@[reducible]
noncomputable def primitives.field.gf2_64x3.F192Unreduced.Insts.CoreOpsBitBitXorF192UnreducedF192Unreduced :
    core.ops.bit.BitXor primitives.field.gf2_64x3.F192Unreduced
      primitives.field.gf2_64x3.F192Unreduced primitives.field.gf2_64x3.F192Unreduced where
  bitxor :=
    primitives.field.gf2_64x3.F192Unreduced.Insts.CoreOpsBitBitXorF192UnreducedF192Unreduced.bitxor

/-- `F192Unreduced ^= F192Unreduced`: XOR of the coefficient words. -/
axiom primitives.field.gf2_64x3.F192Unreduced.Insts.CoreOpsBitBitXorAssignF192Unreduced.bitxor_assign :
  primitives.field.gf2_64x3.F192Unreduced → primitives.field.gf2_64x3.F192Unreduced →
    RustM primitives.field.gf2_64x3.F192Unreduced

/-- `BitXorAssign` for `F192Unreduced`. -/
@[reducible]
noncomputable def primitives.field.gf2_64x3.F192Unreduced.Insts.CoreOpsBitBitXorAssignF192Unreduced :
    core.ops.bit.BitXorAssign primitives.field.gf2_64x3.F192Unreduced
      primitives.field.gf2_64x3.F192Unreduced where
  bitxor_assign :=
    primitives.field.gf2_64x3.F192Unreduced.Insts.CoreOpsBitBitXorAssignF192Unreduced.bitxor_assign

/-- [primitives::field::gf2_64x3::F192Unreduced::reduce]: the reduction to `E`. -/
axiom primitives.field.gf2_64x3.F192Unreduced.reduce :
  primitives.field.gf2_64x3.F192Unreduced → RustM primitives.field.gf2_64x3.F192

/-! ## `primitives::hash` -/

/-- [primitives::hash::STATE_LANES]: the 25 lanes of a Keccak-f[1600] state. -/
def primitives.hash.STATE_LANES : RustM Std.Usize :=
  ok 25#usize

/-- [primitives::hash::keccak_f]: Keccak-f[1600], in place. -/
axiom primitives.hash.keccak_f :
  Array Std.U64 25#usize → RustM (Array Std.U64 25#usize)

/-! ## `parallel`: the thread pool -/

/-- [parallel::init]: spawn the worker pool. -/
axiom parallel.init : RustM Unit

/-! ## `fiat_shamir`, `pcs`, `keccak_gkr`: the prover's types, never looked into -/

/-- [fiat_shamir::transcript::ProverState] -/
axiom fiat_shamir.transcript.ProverState : Type

/-- [fiat_shamir::transcript::Proof] -/
axiom fiat_shamir.transcript.Proof : Type

/-- [pcs::stack_open::StackClaim] -/
axiom pcs.stack_open.StackClaim : Type

/-- [keccak_gkr::OutputClaim] -/
axiom keccak_gkr.OutputClaim : Type

/-! ## `verifier`: the native verifier's types -/

/-- [verifier::field::E] -/
axiom verifier.field.E : Type

/-- [verifier::transcript::Proof] -/
axiom verifier.transcript.Proof : Type

/-- [verifier::Summary] -/
axiom verifier.Summary : Type

/-- [verifier::VerifierError] -/
axiom verifier.VerifierError : Type

/-- The derived `Clone` of `VerifierError`. -/
axiom verifier.VerifierError.Insts.CoreCloneClone.clone :
  verifier.VerifierError → RustM verifier.VerifierError

/-- The derived `PartialEq` of `VerifierError`. -/
axiom verifier.VerifierError.Insts.CoreCmpPartialEqVerifierError.eq :
  verifier.VerifierError → verifier.VerifierError → RustM Bool
