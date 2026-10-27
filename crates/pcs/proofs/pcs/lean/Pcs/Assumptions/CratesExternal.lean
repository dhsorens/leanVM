-- [pcs]: the items of other workspace crates the extraction uses.
-- Aeneas leaves an item of another crate undeclared, expecting a library to provide it; until
-- the crates' extractions are linked, this file declares them, by hand. A type mirrors its Rust
-- definition (a one-field struct is its field, as Aeneas renders one), and so do the constants,
-- the additive structure and the derived impls; any other function is an axiom with the
-- signature the generated code expects.
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

/-- [primitives::field::gf2_64::F64::is_zero] -/
def primitives.field.gf2_64.F64.is_zero (x : primitives.field.gf2_64.F64) : RustM Bool :=
  ok (x == 0#u64)

/-- The derived `Clone` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreCloneClone : core.clone.Clone primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreCloneClone

/-- The derived `Copy` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreMarkerCopy : core.marker.Copy primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreMarkerCopy

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

/-- `F64 += F64`: XOR. -/
def primitives.field.gf2_64.F64.Insts.CoreOpsArithAddAssignF64.add_assign
    (x y : primitives.field.gf2_64.F64) : RustM primitives.field.gf2_64.F64 :=
  ok (x ^^^ y)

/-- [primitives::field::gf2_64::F64::mul]: the product in `GF(2^64)`. -/
axiom primitives.field.gf2_64.F64.Insts.CoreOpsArithMulF64F64.mul :
  primitives.field.gf2_64.F64 → primitives.field.gf2_64.F64 → RustM primitives.field.gf2_64.F64

/-- `F64 *= F64`: the product in `GF(2^64)`. -/
noncomputable def primitives.field.gf2_64.F64.Insts.CoreOpsArithMulAssignF64.mul_assign
    (x y : primitives.field.gf2_64.F64) : RustM primitives.field.gf2_64.F64 :=
  primitives.field.gf2_64.F64.Insts.CoreOpsArithMulF64F64.mul x y

/-- [primitives::field::gf2_64::F64::inv]: the inverse in `GF(2^64)`. -/
axiom primitives.field.gf2_64.F64.inv :
  primitives.field.gf2_64.F64 → RustM primitives.field.gf2_64.F64

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

/-- The derived `PartialEq` of `F192`: field by field. -/
def primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192.eq
    (x y : primitives.field.gf2_64x3.F192) : RustM Bool :=
  ok (x.c0 == y.c0 && x.c1 == y.c1 && x.c2 == y.c2)

/-- The derived `PartialEq` of `F192`. -/
@[reducible]
def primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192 :
    core.cmp.PartialEq primitives.field.gf2_64x3.F192 primitives.field.gf2_64x3.F192 where
  eq := primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192.eq
  ne := fun x y => do
    let b ← primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192.eq x y
    ok !b

/-- `F192::from(F64)`: the base field's embedding, `(k, 0, 0)`. -/
def primitives.field.gf2_64x3.F192.Insts.CoreConvertFromF64.from
    (k : primitives.field.gf2_64.F64) : RustM primitives.field.gf2_64x3.F192 :=
  ok { c0 := k, c1 := 0#u64, c2 := 0#u64 }

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

/-- `F192 += F192`: XOR, coefficient by coefficient. -/
def primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddAssignF192.add_assign
    (x y : primitives.field.gf2_64x3.F192) : RustM primitives.field.gf2_64x3.F192 :=
  primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddF192F192.add x y

/-- [primitives::field::gf2_64x3::F192::mul]: the product in `GF(2^192)`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulF192F192.mul :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 →
    RustM primitives.field.gf2_64x3.F192

/-- [primitives::field::gf2_64x3::F192::square] -/
axiom primitives.field.gf2_64x3.F192.square :
  primitives.field.gf2_64x3.F192 → RustM primitives.field.gf2_64x3.F192

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

/-! ## `primitives`: helpers -/

/-- [primitives::log2_strict_usize]: `log2` of a power of two, a panic otherwise. -/
def primitives.log2_strict_usize (n : Std.Usize) : RustM Std.Usize := do
  massert (n.val != 0 && n.val &&& (n.val - 1) == 0)
  ok ⟨BitVec.ofNat _ n.val.log2⟩

/-- [primitives::multilinear::eq_table]: the table of `eq(r, .)` over `r.len()` variables. -/
axiom primitives.multilinear.eq_table :
  Slice primitives.field.gf2_64x3.F192 → RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192)

/-- [primitives::stream::Stream]: a zero-sized region of streaming stores. -/
@[reducible]
def primitives.stream.Stream := Unit

/-- [primitives::stream::Stream::new] -/
def primitives.stream.Stream.new : RustM primitives.stream.Stream :=
  ok ()

/-- [primitives::stream::Stream::copy]: `src` over `dst`, which must be as long. -/
def primitives.stream.Stream.copy {T : Type} (_ : core.marker.Copy T)
    (_ : primitives.stream.Stream) (dst src : Slice T) : RustM (Slice T) := do
  massert (dst.length == src.length)
  ok src

/-! ## `fiat_shamir`: the prover's transcript -/

/-- [fiat_shamir::transcript::ProverState] -/
axiom fiat_shamir.transcript.ProverState : Type

/-- [fiat_shamir::transcript::ProverState::sample]: the next challenge. -/
axiom fiat_shamir.transcript.ProverState.sample :
  fiat_shamir.transcript.ProverState →
    RustM (primitives.field.gf2_64x3.F192 × fiat_shamir.transcript.ProverState)

/-- [fiat_shamir::transcript::ProverState::sample_vec]: the next `n` challenges. -/
axiom fiat_shamir.transcript.ProverState.sample_vec :
  fiat_shamir.transcript.ProverState → Std.Usize →
    RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192 × fiat_shamir.transcript.ProverState)

/-- [fiat_shamir::transcript::ProverState::add_scalar]: a scalar sent and absorbed. -/
axiom fiat_shamir.transcript.ProverState.add_scalar :
  fiat_shamir.transcript.ProverState → primitives.field.gf2_64x3.F192 →
    RustM fiat_shamir.transcript.ProverState

/-- [fiat_shamir::transcript::ProverState::add_round_poly]: a sumcheck round's polynomial. -/
axiom fiat_shamir.transcript.ProverState.add_round_poly :
  fiat_shamir.transcript.ProverState → Slice primitives.field.gf2_64x3.F192 → Bool →
    RustM fiat_shamir.transcript.ProverState

/-! ## `parallel`: the thread pool -/

/-- [parallel::map_reduce]: `reduce` over `map(0..n)`, seeded by `identity`. -/
axiom parallel.map_reduce {T ID M R : Type}
  (IDInst : core.ops.function.Fn ID Unit T)
  (MInst : core.ops.function.Fn M Std.Usize T)
  (RInst : core.ops.function.Fn R (T × T) T) :
  Std.Usize → ID → M → R → RustM T

/-- [parallel::map_collect]: `[f(0), .., f(n - 1)]`. -/
axiom parallel.map_collect {T F : Type} (FInst : core.ops.function.Fn F Std.Usize T) :
  Std.Usize → F → RustM (alloc.vec.Vec T)

/-- [parallel::chunks_mut]: `f(i, chunk)` on each `chunk`-long piece of `data`. -/
axiom parallel.chunks_mut {T F : Type}
  (FInst : core.ops.function.Fn F (Std.Usize × Slice T) (Unit × Slice T)) :
  Slice T → Std.Usize → F → RustM (Slice T)

/-- [parallel::SendPtr]: `struct SendPtr<T>(pub *mut T)`, a raw pointer, which has no model. -/
axiom parallel.SendPtr (T : Type) : Type
