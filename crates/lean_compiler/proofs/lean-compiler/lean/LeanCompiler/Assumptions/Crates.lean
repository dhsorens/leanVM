-- The items of other workspace crates (`primitives`, `leanvm_core`) the extraction uses, which
-- Aeneas leaves undeclared. Hand-maintained, imported by TypesExternal.lean. They are assumed:
-- the types and functions are axioms, and only the two instruction enums are written out, as
-- their constructors are built here.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

/-! ## `primitives` -/

/-- `primitives::field::gf2_64::F64`, GF(2^64). -/
axiom primitives.field.gf2_64.F64 : Type

/-- `F64::ONE`. -/
axiom primitives.field.gf2_64.F64.ONE : RustM primitives.field.gf2_64.F64

/-- `F64 * F64`. -/
axiom primitives.field.gf2_64.F64.Insts.CoreOpsArithMulF64F64.mul :
  primitives.field.gf2_64.F64 → primitives.field.gf2_64.F64 → RustM primitives.field.gf2_64.F64

/-- `F64 *= F64`. -/
axiom primitives.field.gf2_64.F64.Insts.CoreOpsArithMulAssignF64.mul_assign :
  primitives.field.gf2_64.F64 → primitives.field.gf2_64.F64 → RustM primitives.field.gf2_64.F64

/-- `primitives::field::G`, the generator. -/
axiom primitives.field.G : RustM primitives.field.gf2_64.F64

/-- `primitives::field::g_pow`. -/
axiom primitives.field.g_pow : Std.Usize → RustM primitives.field.gf2_64.F64

/-- `primitives::field::gf2_64x3::F192`, the cubic extension, the machine word. -/
axiom primitives.field.gf2_64x3.F192 : Type

/-- `F192::ONE`. -/
axiom primitives.field.gf2_64x3.F192.ONE : RustM primitives.field.gf2_64x3.F192

/-- `F192::new(c0, c1, c2)`. -/
axiom primitives.field.gf2_64x3.F192.new :
  Std.U64 → Std.U64 → Std.U64 → RustM primitives.field.gf2_64x3.F192

/-- The derived `Clone` of `F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreCloneClone.clone :
  primitives.field.gf2_64x3.F192 → RustM primitives.field.gf2_64x3.F192

/-- The derived `PartialEq` of `F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192 :
  core.cmp.PartialEq primitives.field.gf2_64x3.F192 primitives.field.gf2_64x3.F192

/-- `F192: From<F64>`, the base field's embedding. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreConvertFromF64 :
  core.convert.From primitives.field.gf2_64x3.F192 primitives.field.gf2_64.F64

/-- `F192 *= F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulAssignF192.mul_assign :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 →
    RustM primitives.field.gf2_64x3.F192

/-- `primitives::hash::RATE`, Keccak-256's rate in bytes. -/
axiom primitives.hash.RATE : RustM Std.Usize

/-- `primitives::hash::PAD_FIRST`, the padding's first byte. -/
axiom primitives.hash.PAD_FIRST : RustM Std.U8

/-! ## `leanvm_core` -/

/-- `leanvm_core::cpu::isa::DerefMode`: what a `DEREF` stores. -/
inductive leanvm_core.cpu.isa.DerefMode where
  | Cell : leanvm_core.cpu.isa.DerefMode
  | Pc : leanvm_core.cpu.isa.DerefMode
  | Fp : leanvm_core.cpu.isa.DerefMode

/-- The derived `Clone` of `DerefMode`. -/
axiom leanvm_core.cpu.isa.DerefMode.Insts.CoreCloneClone.clone :
  leanvm_core.cpu.isa.DerefMode → RustM leanvm_core.cpu.isa.DerefMode

/-- `leanvm_core::cpu::isa::Op`, an instruction of the ISA. -/
inductive leanvm_core.cpu.isa.Op where
  | Xor : Std.U32 → Std.U32 → Std.U32 → leanvm_core.cpu.isa.Op
  | Mul : Std.U32 → Std.U32 → Std.U32 → leanvm_core.cpu.isa.Op
  | Set : Std.U32 → primitives.field.gf2_64x3.F192 → leanvm_core.cpu.isa.Op
  | Deref : Std.U32 → Std.U32 → Std.U32 → leanvm_core.cpu.isa.DerefMode → leanvm_core.cpu.isa.Op
  | Jump : Std.U32 → Std.U32 → Std.U32 → leanvm_core.cpu.isa.Op
  | Keccak : Std.Array Std.U32 4#usize → Std.U32 → Std.U32 → Std.U32 → Std.U32 → Bool → Bool →
      leanvm_core.cpu.isa.Op

/-- `leanvm_core::cpu::hints::RHint`, a resolved prover hint. -/
axiom leanvm_core.cpu.hints.RHint : Type

/-- The derived `Clone` of `RHint`. -/
axiom leanvm_core.cpu.hints.RHint.Insts.CoreCloneClone.clone :
  leanvm_core.cpu.hints.RHint → RustM leanvm_core.cpu.hints.RHint

/-- `leanvm_core::cpu::hints::BitsDest`, where a bit-decomposition hint writes. -/
axiom leanvm_core.cpu.hints.BitsDest : Type

/-- `leanvm_core::cpu::Program`, a compiled program. -/
axiom leanvm_core.cpu.Program : Type

/-- `leanvm_core::cpu::MIN_LOG_MEM`. -/
axiom leanvm_core.cpu.MIN_LOG_MEM : RustM Std.Usize

/-- `leanvm_core::keccak::STATE_CELLS`, the cells of a Keccak state. -/
axiom leanvm_core.keccak.STATE_CELLS : RustM Std.Usize

/-- `leanvm_core::keccak::RATE_CELLS`, the cells of a block. -/
axiom leanvm_core.keccak.RATE_CELLS : RustM Std.Usize
