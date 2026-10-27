-- [fiat_shamir]: the items of other workspace crates the extraction uses.
-- Aeneas leaves an item of another crate undeclared, expecting a library to provide it; until
-- the crates' extractions are linked, this file declares them, by hand. A type mirrors its Rust
-- definition (a one-field struct is its field, as Aeneas renders one), and so do the constructors,
-- constants and derived impls; any other function is an axiom with the signature the generated
-- code expects.
module
public import Aeneas
public import CoreModels
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

/-- [primitives::field::gf2_64::F64]: `struct F64(pub u64)`. -/
@[reducible]
def primitives.field.gf2_64.F64 := Std.U64

/-- [primitives::field::gf2_64x3::F192]: `struct F192 { c0, c1, c2: u64 }`. -/
structure primitives.field.gf2_64x3.F192 where
  c0 : Std.U64
  c1 : Std.U64
  c2 : Std.U64

/-- [primitives::field::gf2_64::F64::ZERO] -/
def primitives.field.gf2_64.F64.ZERO : RustM primitives.field.gf2_64.F64 :=
  ok 0#u64

/-- The derived `Clone` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreCloneClone : core.clone.Clone primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreCloneClone

/-- The derived `PartialEq` of `F64`. -/
@[reducible]
def primitives.field.gf2_64.F64.Insts.CoreCmpPartialEqF64 :
    core.cmp.PartialEq primitives.field.gf2_64.F64 primitives.field.gf2_64.F64 :=
  core.U64.Insts.CoreCmpPartialEqU64

/-- [primitives::field::gf2_64x3::F192::new] -/
def primitives.field.gf2_64x3.F192.new (c0 c1 c2 : Std.U64) :
    RustM primitives.field.gf2_64x3.F192 :=
  ok { c0, c1, c2 }

/-- The derived `Clone` of `F192`, a copy. -/
@[reducible]
def primitives.field.gf2_64x3.F192.Insts.CoreCloneClone :
    core.clone.Clone primitives.field.gf2_64x3.F192 where
  clone := fun x => ok x
  clone_from := fun _ x => ok x

/-- The derived `PartialEq` of `F192`, field by field. -/
@[reducible]
def primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192 :
    core.cmp.PartialEq primitives.field.gf2_64x3.F192 primitives.field.gf2_64x3.F192 where
  eq := fun x y => ok (x.c0 == y.c0 && x.c1 == y.c1 && x.c2 == y.c2)
  ne := fun x y => ok !(x.c0 == y.c0 && x.c1 == y.c1 && x.c2 == y.c2)

/-- [primitives::hash::keccak_f]: Keccak-f[1600], in place. -/
axiom primitives.hash.keccak_f :
  Array Std.U64 25#usize → RustM (Array Std.U64 25#usize)

/-- [primitives::hash::hash]: Keccak-256. -/
axiom primitives.hash.hash : Slice Std.U8 → RustM (Array Std.U8 32#usize)
