-- [keccak_gkr]: the items of other workspace crates the extraction uses.
-- Aeneas leaves an item of another crate undeclared, expecting a library to provide it; until
-- the crates' extractions are linked, this file declares them, by hand. A type mirrors its Rust
-- definition (a one-field struct is its field, as Aeneas renders one) unless its fields are
-- private, and so do the constructors, constants and derived or one-line impls; any other item
-- is an axiom with the signature the generated code expects.
module
public import Aeneas
public import CoreModels
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

/-! ## `primitives` -/

/-- [primitives::field::gf2_64::F64]: `struct F64(pub u64)`. -/
@[reducible]
def primitives.field.gf2_64.F64 := Std.U64

/-- The derived `Clone` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreCloneClone : core.clone.Clone primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreCloneClone

/-- [primitives::field::gf2_64x3::F192]: `struct F192 { c0, c1, c2: u64 }`. -/
structure primitives.field.gf2_64x3.F192 where
  c0 : Std.U64
  c1 : Std.U64
  c2 : Std.U64

/-- [primitives::field::gf2_64x3::F192::new] -/
def primitives.field.gf2_64x3.F192.new (c0 c1 c2 : Std.U64) :
    RustM primitives.field.gf2_64x3.F192 :=
  ok { c0, c1, c2 }

/-- [primitives::field::gf2_64x3::F192::ZERO] -/
def primitives.field.gf2_64x3.F192.ZERO : RustM primitives.field.gf2_64x3.F192 :=
  ok { c0 := 0#u64, c1 := 0#u64, c2 := 0#u64 }

/-- [primitives::field::gf2_64x3::F192::ONE] -/
def primitives.field.gf2_64x3.F192.ONE : RustM primitives.field.gf2_64x3.F192 :=
  ok { c0 := 1#u64, c1 := 0#u64, c2 := 0#u64 }

/-- The derived `Clone` of `F192`, a copy. -/
def primitives.field.gf2_64x3.F192.Insts.CoreCloneClone.clone (x : primitives.field.gf2_64x3.F192) :
    RustM primitives.field.gf2_64x3.F192 :=
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

/-- The derived `PartialEq` of `F192`, field by field. -/
def primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192.eq (x y : primitives.field.gf2_64x3.F192) :
    RustM Bool :=
  ok (x.c0 == y.c0 && x.c1 == y.c1 && x.c2 == y.c2)

/-- The derived `PartialEq` of `F192`. -/
@[reducible]
def primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192 :
    core.cmp.PartialEq primitives.field.gf2_64x3.F192 primitives.field.gf2_64x3.F192 where
  eq := primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192.eq
  ne := fun x y => do
    let e ← primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192.eq x y
    ok !e

/-- The derived `Debug` of `F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreFmtDebug : core.fmt.Debug primitives.field.gf2_64x3.F192

/-- [primitives::field::gf2_64x3::{impl Add for F192}::add]: coefficient by coefficient. -/
def primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddF192F192.add
    (x y : primitives.field.gf2_64x3.F192) : RustM primitives.field.gf2_64x3.F192 :=
  ok { c0 := x.c0 ^^^ y.c0, c1 := x.c1 ^^^ y.c1, c2 := x.c2 ^^^ y.c2 }

/-- [primitives::field::gf2_64x3::{impl AddAssign for F192}::add_assign]: the sum. -/
def primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddAssignF192.add_assign
    (x y : primitives.field.gf2_64x3.F192) : RustM primitives.field.gf2_64x3.F192 :=
  primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddF192F192.add x y

/-- [primitives::field::gf2_64x3::{impl Mul for F192}::mul]: the product in GF(2^192). -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulF192F192.mul :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 → RustM primitives.field.gf2_64x3.F192

/-- [primitives::field::gf2_64x3::{impl MulAssign for F192}::mul_assign]: `*self = *self * rhs`. -/
noncomputable def primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulAssignF192.mul_assign
    (x y : primitives.field.gf2_64x3.F192) : RustM primitives.field.gf2_64x3.F192 :=
  primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulF192F192.mul x y

/-- [primitives::field::gf2_64x3::F192::square] -/
axiom primitives.field.gf2_64x3.F192.square :
  primitives.field.gf2_64x3.F192 → RustM primitives.field.gf2_64x3.F192

/-- [primitives::field::gf2_64x3::F192::inv] -/
axiom primitives.field.gf2_64x3.F192.inv :
  primitives.field.gf2_64x3.F192 → RustM primitives.field.gf2_64x3.F192

/-- [primitives::field::gf2_64::mul_wide]: the carry-less product of two words. -/
axiom primitives.field.gf2_64.mul_wide : Std.U64 → Std.U64 → RustM Std.U128

/-- [primitives::field::powers]: `1, x, .., x^(n - 1)`. -/
axiom primitives.field.powers :
  primitives.field.gf2_64x3.F192 → Std.Usize → RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192)

/-- [primitives::multilinear::eq_table]: the `eq(r, .)` table. -/
axiom primitives.multilinear.eq_table :
  Slice primitives.field.gf2_64x3.F192 → RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192)

/-- [primitives::multilinear::poly_eval]: a polynomial, constant first, at a point. -/
axiom primitives.multilinear.poly_eval :
  Slice primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 →
    RustM primitives.field.gf2_64x3.F192

/-- [primitives::uninit_vec]: `len` elements the caller writes before reading. -/
axiom primitives.uninit_vec {T : Type} (CopyInst : core.marker.Copy T) :
  Std.Usize → RustM (alloc.vec.Vec T)

/-- [primitives::hash::STATE_LANES] -/
def primitives.hash.STATE_LANES : RustM Std.Usize := ok 25#usize

/-- [primitives::hash::ROUNDS] -/
def primitives.hash.ROUNDS : RustM Std.Usize := ok 24#usize

/-- [primitives::hash::RC]: the round constants. -/
axiom primitives.hash.RC : RustM (Array Std.U64 24#usize)

/-- [primitives::hash::RHO]: the rotation of each lane. -/
axiom primitives.hash.RHO : RustM (Array Std.U32 25#usize)

/-- [primitives::hash::PI]: where `pi` moves each lane. -/
axiom primitives.hash.PI : RustM (Array Std.Usize 25#usize)

/-- [primitives::stream::Stream] -/
axiom primitives.stream.Stream : Type

/-! ## `parallel` -/

/-- [parallel::SendPtr]: `struct SendPtr<T>(pub *mut T)`, a raw pointer workers write through. -/
@[reducible]
def parallel.SendPtr (T : Type) := MutRawPtr T

/-! ## `fiat_shamir` -/

/-- [fiat_shamir::transcript::ProverState]: its fields are private. -/
axiom fiat_shamir.transcript.ProverState : Type

/-- [fiat_shamir::transcript::ProverState::sample] -/
axiom fiat_shamir.transcript.ProverState.sample :
  fiat_shamir.transcript.ProverState →
    RustM (primitives.field.gf2_64x3.F192 × fiat_shamir.transcript.ProverState)

/-- [fiat_shamir::transcript::ProverState::sample_vec] -/
axiom fiat_shamir.transcript.ProverState.sample_vec :
  fiat_shamir.transcript.ProverState → Std.Usize →
    RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192 × fiat_shamir.transcript.ProverState)

/-- [fiat_shamir::transcript::ProverState::add_scalar] -/
axiom fiat_shamir.transcript.ProverState.add_scalar :
  fiat_shamir.transcript.ProverState → primitives.field.gf2_64x3.F192 →
    RustM fiat_shamir.transcript.ProverState

/-- [fiat_shamir::transcript::ProverState::add_scalars] -/
axiom fiat_shamir.transcript.ProverState.add_scalars :
  fiat_shamir.transcript.ProverState → Slice primitives.field.gf2_64x3.F192 →
    RustM fiat_shamir.transcript.ProverState

/-- [fiat_shamir::transcript::ProverState::add_round_poly] -/
axiom fiat_shamir.transcript.ProverState.add_round_poly :
  fiat_shamir.transcript.ProverState → Slice primitives.field.gf2_64x3.F192 → Bool →
    RustM fiat_shamir.transcript.ProverState

/-! ## `pcs` -/

/-- [pcs::stack_open::StackClaim] -/
inductive pcs.stack_open.StackClaim where
  | Point (offset : Std.Usize) (low_point : alloc.vec.Vec primitives.field.gf2_64x3.F192)
      (value : primitives.field.gf2_64x3.F192)

/-- [pcs::stack_open::RingSwitchClaim] -/
structure pcs.stack_open.RingSwitchClaim where
  suffix_point : alloc.vec.Vec primitives.field.gf2_64x3.F192
  s_hat_v : core.option.Option (alloc.vec.Vec primitives.field.gf2_64x3.F192)

/-- [pcs::stack_open::RingSwitchOpen] -/
structure pcs.stack_open.RingSwitchOpen where
  offset : Std.Usize
  claims : alloc.vec.Vec pcs.stack_open.RingSwitchClaim
