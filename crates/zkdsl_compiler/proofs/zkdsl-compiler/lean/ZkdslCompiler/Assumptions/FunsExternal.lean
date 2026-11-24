-- [zkdsl_compiler]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import ZkdslCompiler.Extraction.Types
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error
open Std.Do
set_option linter.dupNamespace false
set_option linter.hashCommand false
set_option linter.unusedVariables false
set_option linter.style.whitespace false
set_option linter.style.setOption false
set_option linter.style.longLine false
set_option linter.internalConstructors false

/- You can set the `maxHeartbeats` value with the `-max-heartbeats` CLI option -/
set_option maxHeartbeats 1000000

/- You can set the `maxRecDepth` value with the `-max-recdepth` CLI option -/
set_option maxRecDepth 2048

namespace zkdsl_compiler

/-- [zkdsl_compiler::ast::{impl core::clone::Clone for zkdsl_compiler::ast::Expr}::clone]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 7:9-7:14
    Visibility: public -/
axiom ast.Expr.Insts.CoreCloneClone.clone : ast.Expr → RustM ast.Expr

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::Expr}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 7:16-7:21
    Visibility: public -/
axiom ast.Expr.Insts.CoreFmtDebug.fmt
  :
  ast.Expr → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{impl core::cmp::PartialEq<zkdsl_compiler::ast::Expr> for zkdsl_compiler::ast::Expr}::eq]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 7:23-7:32
    Visibility: public -/
axiom ast.Expr.Insts.CoreCmpPartialEqExpr.eq
  : ast.Expr → ast.Expr → RustM Bool

/-- [zkdsl_compiler::ast::{impl core::clone::Clone for zkdsl_compiler::ast::Stmt}::clone]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 90:9-90:14
    Visibility: public -/
axiom ast.Stmt.Insts.CoreCloneClone.clone : ast.Stmt → RustM ast.Stmt

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::Stmt}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 90:16-90:21
    Visibility: public -/
axiom ast.Stmt.Insts.CoreFmtDebug.fmt
  :
  ast.Stmt → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{zkdsl_compiler::ast::Stmt}::new]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 97:4-99:5
    Visibility: public -/
axiom ast.Stmt.new : Std.U32 → ast.StmtKind → RustM ast.Stmt

/-- [zkdsl_compiler::ast::{zkdsl_compiler::ast::Stmt}::at]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 103:4-105:5
    Visibility: public -/
axiom ast.Stmt.at : ast.Stmt → ast.StmtKind → RustM ast.Stmt

/-- [zkdsl_compiler::ast::{impl core::clone::Clone for zkdsl_compiler::ast::StmtKind}::clone]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 109:9-109:14
    Visibility: public -/
axiom ast.StmtKind.Insts.CoreCloneClone.clone
  : ast.StmtKind → RustM ast.StmtKind

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::StmtKind}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 109:16-109:21
    Visibility: public -/
axiom ast.StmtKind.Insts.CoreFmtDebug.fmt
  :
  ast.StmtKind → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::ForBound}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 201:16-201:21
    Visibility: public -/
axiom ast.ForBound.Insts.CoreFmtDebug.fmt
  :
  ast.ForBound → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::LtBound}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 214:16-214:21
    Visibility: public -/
axiom ast.LtBound.Insts.CoreFmtDebug.fmt
  :
  ast.LtBound → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::Shape}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 221:22-221:27
    Visibility: public -/
axiom ast.Shape.Insts.CoreFmtDebug.fmt
  :
  ast.Shape → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::Param}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 241:16-241:21
    Visibility: public -/
axiom ast.Param.Insts.CoreFmtDebug.fmt
  :
  ast.Param → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::ParamKind}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 247:22-247:27
    Visibility: public -/
axiom ast.ParamKind.Insts.CoreFmtDebug.fmt
  :
  ast.ParamKind → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{zkdsl_compiler::ast::Param}::shape]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 255:4-260:5 -/
axiom ast.Param.shape : ast.Param → RustM ast.Shape

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::Func}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 264:16-264:21
    Visibility: public -/
axiom ast.Func.Insts.CoreFmtDebug.fmt
  :
  ast.Func → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::{zkdsl_compiler::ast::Func}::has_const_params]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 281:4-283:5 -/
axiom ast.Func.has_const_params : ast.Func → RustM Bool

/-- [zkdsl_compiler::ast::{impl core::clone::Clone for zkdsl_compiler::ast::Ast}::clone]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 291:9-291:14
    Visibility: public -/
axiom ast.Ast.Insts.CoreCloneClone.clone : ast.Ast → RustM ast.Ast

/-- [zkdsl_compiler::ast::{impl core::fmt::Debug for zkdsl_compiler::ast::Ast}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 291:16-291:21
    Visibility: public -/
axiom ast.Ast.Insts.CoreFmtDebug.fmt
  :
  ast.Ast → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ast::free_vars_expr]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 308:0-338:1 -/
axiom ast.free_vars_expr
  : ast.Expr → alloc.vec.Vec Str → RustM (alloc.vec.Vec Str)

/-- [zkdsl_compiler::ast::taken_arm]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 341:0-346:1 -/
axiom ast.taken_arm
  : Bool → ast.Expr → ast.Expr → Bool → RustM (core.option.Option Bool)

/-- [zkdsl_compiler::parser::consts::const_int_expr]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 37:0-63:1 -/
axiom parser.consts.const_int_expr
  : ast.Expr → RustM (core.option.Option Std.U128)

/-- [zkdsl_compiler::ast::binds_anywhere]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 357:0-399:1 -/
axiom ast.binds_anywhere
  :
  Slice ast.Stmt → Bool → std.collections.hash.set.HashSet Str
    std.hash.random.RandomState alloc.alloc.Global → RustM
    (std.collections.hash.set.HashSet Str std.hash.random.RandomState
    alloc.alloc.Global)

/-- [zkdsl_compiler::ast::scoped_vars]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 402:0-407:1 -/
axiom ast.scoped_vars
  : Slice ast.Stmt → Bool → alloc.vec.Vec Str → RustM (alloc.vec.Vec Str)

/-- [zkdsl_compiler::ast::free_vars_stmt]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 411:0-526:1 -/
axiom ast.free_vars_stmt
  :
  ast.Stmt → Bool → alloc.vec.Vec Str → std.collections.hash.set.HashSet
    Str std.hash.random.RandomState alloc.alloc.Global → RustM
    ((alloc.vec.Vec Str) × (std.collections.hash.set.HashSet Str
    std.hash.random.RandomState alloc.alloc.Global))

/-- [zkdsl_compiler::ast::binds]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 529:0-536:1 -/
axiom ast.binds : ast.StmtKind → Str → RustM Bool

/-- [zkdsl_compiler::ast::binds_through]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 542:0-548:1 -/
axiom ast.binds_through : Slice ast.Stmt → Str → RustM Bool

/-- [zkdsl_compiler::ast::rebinds_in_block]:
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 557:0-567:1 -/
axiom ast.rebinds_in_block : Slice ast.Stmt → Str → RustM Bool

/-- [zkdsl_compiler::field::{impl zkdsl_compiler::field::Consts for verifier::field::K}::ONE]
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 14:4-14:29
    Visibility: public -/
axiom verifier.field.K.Insts.Zkdsl_compilerFieldConsts.ONE
  : RustM verifier.field.K

/-- [zkdsl_compiler::field::{impl zkdsl_compiler::field::Consts for verifier::field::K}::ZERO]
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 13:4-13:30
    Visibility: public -/
axiom verifier.field.K.Insts.Zkdsl_compilerFieldConsts.ZERO
  : RustM verifier.field.K

/-- [zkdsl_compiler::field::{impl zkdsl_compiler::field::Consts for verifier::field::E}::ONE]
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 19:4-19:38
    Visibility: public -/
axiom verifier.field.E.Insts.Zkdsl_compilerFieldConsts.ONE
  : RustM verifier.field.E

/-- [zkdsl_compiler::field::{impl zkdsl_compiler::field::Consts for verifier::field::E}::ZERO]
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 18:4-18:39
    Visibility: public -/
axiom verifier.field.E.Insts.Zkdsl_compilerFieldConsts.ZERO
  : RustM verifier.field.E

/-- [zkdsl_compiler::field::{impl zkdsl_compiler::field::Base for verifier::field::K}::pow]:
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 31:4-41:5
    Visibility: public -/
axiom verifier.field.K.Insts.Zkdsl_compilerFieldBase.pow
  : verifier.field.K → Std.U128 → RustM verifier.field.K

/-- [zkdsl_compiler::field::{impl zkdsl_compiler::field::Base for verifier::field::K}::G]
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 29:4-29:27
    Visibility: public -/
axiom verifier.field.K.Insts.Zkdsl_compilerFieldBase.G : RustM verifier.field.K

/-- [zkdsl_compiler::field::g_pow]:
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 45:0-47:1
    Visibility: public -/
axiom field.g_pow : Std.Usize → RustM verifier.field.K

/-- [zkdsl_compiler::field::as_base]:
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 50:0-52:1
    Visibility: public -/
axiom field.as_base
  : verifier.field.E → RustM (core.option.Option verifier.field.K)

/-- [zkdsl_compiler::field::word]:
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 55:0-57:1
    Visibility: public -/
axiom field.word : Std.U128 → RustM verifier.field.E

/-- [zkdsl_compiler::field::int]:
    Source: 'crates/zkdsl_compiler/src/field.rs', lines 60:0-62:1
    Visibility: public -/
axiom field.int : verifier.field.E → RustM Std.U128

/-- [zkdsl_compiler::ir::{impl core::fmt::Debug for zkdsl_compiler::ir::KVal}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ir.rs', lines 9:16-9:21
    Visibility: public -/
axiom ir.KVal.Insts.CoreFmtDebug.fmt
  :
  ir.KVal → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ir::{impl core::fmt::Debug for zkdsl_compiler::ir::LInstr}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ir.rs', lines 31:16-31:21
    Visibility: public -/
axiom ir.LInstr.Insts.CoreFmtDebug.fmt
  :
  ir.LInstr → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ir::{impl core::fmt::Debug for zkdsl_compiler::ir::LOp}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ir.rs', lines 42:16-42:21
    Visibility: public -/
axiom ir.LOp.Insts.CoreFmtDebug.fmt
  :
  ir.LOp → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ir::{impl core::fmt::Debug for zkdsl_compiler::ir::Hint}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ir.rs', lines 106:16-106:21
    Visibility: public -/
axiom ir.Hint.Insts.CoreFmtDebug.fmt
  :
  ir.Hint → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::ir::{impl core::fmt::Debug for zkdsl_compiler::ir::LoopCount}::fmt]:
    Source: 'crates/zkdsl_compiler/src/ir.rs', lines 179:16-179:21
    Visibility: public -/
axiom ir.LoopCount.Insts.CoreFmtDebug.fmt
  :
  ir.LoopCount → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::compile]:
    Source: 'crates/zkdsl_compiler/src/lib.rs', lines 50:0-54:1
    Visibility: public -/
axiom compile : ast.Ast → RustM isa.CompiledProgram

/-- [zkdsl_compiler::lower_all]:
    Source: 'crates/zkdsl_compiler/src/lib.rs', lines 57:0-106:1 -/
axiom lower_all
  : ast.Ast → RustM ((alloc.vec.Vec ir.Lowered) × ir.JumpTables)

/-- [zkdsl_compiler::assemble]:
    Source: 'crates/zkdsl_compiler/src/lib.rs', lines 109:0-236:1 -/
axiom assemble
  : alloc.vec.Vec ir.Lowered → ir.JumpTables → RustM isa.CompiledProgram

/-- [zkdsl_compiler::disassemble]:
    Source: 'crates/zkdsl_compiler/src/lib.rs', lines 241:0-302:1
    Visibility: public -/
axiom disassemble : Slice isa.Op → RustM alloc.string.String

/-- [zkdsl_compiler::resolve]:
    Source: 'crates/zkdsl_compiler/src/lib.rs', lines 304:0-363:1 -/
axiom resolve
  :
  ir.LOp → std.collections.hash.map.HashMap alloc.string.String Std.U32
    std.hash.random.RandomState alloc.alloc.Global → Std.U32 → Std.U32 →
    Std.U32 → Std.U32 → RustM isa.Op

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::lower_keccak]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 36:4-76:5 -/
axiom lower.builtins.FnLower.lower_keccak
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::pad_tail_in_place]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 82:4-107:5 -/
axiom lower.builtins.FnLower.pad_tail_in_place
  :
  lower.FnLower → std.collections.hash.map.HashMap Str ast.Expr
    std.hash.random.RandomState alloc.alloc.Global → Slice
    lower.builtins.SpongeCell → Std.U32 → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::lower_keccak_cells]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 119:4-170:5 -/
axiom lower.builtins.FnLower.lower_keccak_cells
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::keccak_len]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 173:4-185:5 -/
axiom lower.builtins.FnLower.keccak_len
  :
  lower.FnLower → std.collections.hash.map.HashMap Str ast.Expr
    std.hash.random.RandomState alloc.alloc.Global → Std.U32 → RustM
    Std.U32

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::keccak_kwargs]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 188:4-229:5 -/
axiom lower.builtins.FnLower.keccak_kwargs
  :
  lower.FnLower → Slice ast.Expr → Str → Slice Str → Slice Str →
    RustM (std.collections.hash.map.HashMap Str ast.Expr
    std.hash.random.RandomState alloc.alloc.Global)

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::keccak_out]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 233:4-261:5 -/
axiom lower.builtins.FnLower.keccak_out
  :
  lower.FnLower → ast.Expr → RustM (lower.builtins.KeccakOut ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::keccak_finish]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 264:4-268:5 -/
axiom lower.builtins.FnLower.keccak_finish
  :
  lower.FnLower → lower.builtins.KeccakOut → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::emit_keccak_message]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 275:4-335:5 -/
axiom lower.builtins.FnLower.emit_keccak_message
  :
  lower.FnLower → alloc.vec.Vec lower.builtins.SpongeCell →
    core.option.Option Std.U32 → core.option.Option Std.U32 →
    lower.builtins.KeccakOut → Bool → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::xor_byte]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 338:4-351:5 -/
axiom lower.builtins.FnLower.xor_byte
  :
  lower.FnLower → Slice lower.builtins.SpongeCell → Std.Usize → Std.U8
    → RustM (lower.FnLower × (lower.FnLower → lower.FnLower) × (Slice
    lower.builtins.SpongeCell))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::keccak_rate]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 355:4-371:5 -/
axiom lower.builtins.FnLower.keccak_rate
  :
  lower.FnLower → Slice lower.builtins.SpongeCell → core.option.Option
    Std.U32 → RustM (((Array Std.U32 4#usize) × Std.U32) × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::sponge_xor]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 375:4-395:5 -/
axiom lower.builtins.FnLower.sponge_xor
  :
  lower.FnLower → Std.U32 → lower.builtins.SpongeCell →
    core.option.Option Std.U32 → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::sponge_run]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 399:4-426:5 -/
axiom lower.builtins.FnLower.sponge_run
  :
  lower.FnLower → Slice lower.builtins.SpongeCell → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::lower_builtin]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 434:4-565:5 -/
axiom lower.builtins.FnLower.lower_builtin
  :
  lower.FnLower → Str → Slice ast.Expr → RustM (Bool × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::sponge_cells]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 570:4-585:5 -/
axiom lower.builtins.FnLower.sponge_cells
  :
  lower.FnLower → ast.Expr → RustM ((alloc.vec.Vec
    lower.builtins.SpongeCell) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::keccak_operand]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 588:4-602:5 -/
axiom lower.builtins.FnLower.keccak_operand
  :
  lower.FnLower → ast.Expr → Std.Usize → RustM ((alloc.vec.Vec
    lower.builtins.SpongeCell) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::prev_state]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 606:4-615:5 -/
axiom lower.builtins.FnLower.prev_state
  :
  lower.FnLower → ast.Expr → Std.U32 → RustM ((core.option.Option
    Std.U32) × lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::try_cell_run]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 618:4-623:5 -/
axiom lower.builtins.FnLower.try_cell_run
  :
  lower.FnLower → ast.Expr → RustM ((core.result.Result ir.CellRun Unit) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::sponge_cell]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 626:4-633:5 -/
axiom lower.builtins.FnLower.sponge_cell
  :
  lower.FnLower → lower.builtins.SpongeCell → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::keccak_pad_run]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 638:4-650:5 -/
axiom lower.builtins.FnLower.keccak_pad_run
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::bits_dest]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 655:4-676:5 -/
axiom lower.builtins.FnLower.bits_dest
  :
  lower.FnLower → ast.Expr → Std.U32 → Str → RustM (isa.BitsDest ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::{zkdsl_compiler::lower::FnLower<'_0>}::lower_hint_witness]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 681:4-688:5 -/
axiom lower.builtins.FnLower.lower_hint_witness
  :
  lower.FnLower → ast.Expr → Str → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [zkdsl_compiler::lower::builtins::STATE_CELLS]
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 692:0-692:49 -/
axiom lower.builtins.STATE_CELLS : RustM Std.U32

/-- [zkdsl_compiler::lower::builtins::BLOCK_CELLS]
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 694:0-694:48 -/
axiom lower.builtins.BLOCK_CELLS : RustM Std.U32

/-- [zkdsl_compiler::lower::builtins::RATE]
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 696:0-696:36 -/
axiom lower.builtins.RATE : RustM Std.Usize

/-- [zkdsl_compiler::lower::builtins::MAX_EXPONENT_BITS]
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 699:0-699:34 -/
axiom lower.builtins.MAX_EXPONENT_BITS : RustM Std.U32

/-- [zkdsl_compiler::lower::builtins::two_to_one_close]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 702:0-704:1 -/
axiom lower.builtins.two_to_one_close : RustM verifier.field.E

/-- [zkdsl_compiler::lower::builtins::keccak_pad_value]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 707:0-709:1 -/
axiom lower.builtins.keccak_pad_value : RustM verifier.field.E

/-- [zkdsl_compiler::lower::builtins::{impl core::fmt::Debug for zkdsl_compiler::lower::builtins::SpongeCell}::fmt]:
    Source: 'crates/zkdsl_compiler/src/lower/builtins.rs', lines 721:22-721:27
    Visibility: public -/
axiom lower.builtins.SpongeCell.Insts.CoreFmtDebug.fmt
  :
  lower.builtins.SpongeCell → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [zkdsl_compiler::lower::call::substitute_body]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 19:0-25:1 -/
-- hand-maintained: Aeneas gives `Cow` two type arguments, the hax Lean library's takes one.
axiom lower.call.substitute_body
  :
  Slice ast.Stmt → Slice (Str × ast.Expr) → RustM (alloc.borrow.Cow (Slice
    ast.Stmt))

/-- [zkdsl_compiler::lower::call::split_tail_return]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 29:0-35:1 -/
axiom lower.call.split_tail_return
  :
  Slice ast.Stmt → RustM (core.option.Option ((Slice ast.Stmt) × Std.U32 ×
    (Slice ast.Expr)))

/-- [zkdsl_compiler::lower::call::stmt_inline_safe]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 37:0-56:1 -/
axiom lower.call.stmt_inline_safe : ast.Stmt → RustM Bool

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::lower_call]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 61:4-187:5 -/
axiom lower.call.FnLower.lower_call
  :
  lower.FnLower → Str → Slice ast.Expr → core.option.Option Std.U32 →
    Slice Std.U32 → Bool → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::lower_dispatched_call]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 195:4-300:5 -/
axiom lower.call.FnLower.lower_dispatched_call
  :
  lower.FnLower → Slice ast.Expr → ast.Expr → Slice alloc.string.String
    → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::try_inline]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 309:4-390:5 -/
axiom lower.call.FnLower.try_inline
  :
  lower.FnLower → Str → Slice ast.Expr → core.option.Option (Slice
    Std.U32) → RustM ((core.option.Option (alloc.vec.Vec lower.Binding)) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::return_into]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 394:4-408:5 -/
axiom lower.call.FnLower.return_into
  :
  lower.FnLower → Slice ast.Expr → Slice Std.U32 → RustM (lower.FnLower
    × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::lower_return]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 410:4-446:5 -/
axiom lower.call.FnLower.lower_return
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::specialize]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 452:4-488:5 -/
axiom lower.call.FnLower.specialize
  :
  lower.FnLower → Str → Slice ast.Expr → RustM ((alloc.string.String ×
    (alloc.vec.Vec ast.Expr)) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::call]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 494:4-527:5 -/
axiom lower.call.FnLower.call
  :
  lower.FnLower → Str → Slice ast.Expr → Std.Usize → RustM
    ((alloc.vec.Vec lower.Binding) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::call_into]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 531:4-544:5 -/
axiom lower.call.FnLower.call_into
  :
  lower.FnLower → Str → Slice ast.Expr → Slice Std.U32 → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::check_returns]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 547:4-556:5 -/
axiom lower.call.FnLower.check_returns
  : lower.FnLower → Str → Std.Usize → RustM Unit

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::const_substs]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 558:4-576:5 -/
axiom lower.call.FnLower.const_substs
  :
  lower.FnLower → ast.Func → Slice ast.Expr → RustM (core.result.Result
    (alloc.vec.Vec (Str × ast.Expr)) alloc.string.String)

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::callee_def]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 579:4-584:5 -/
axiom lower.call.FnLower.callee_def
  : lower.FnLower → Str → RustM (core.option.Option ast.Func)

/-- [zkdsl_compiler::lower::call::{zkdsl_compiler::lower::FnLower<'_0>}::const_arg]:
    Source: 'crates/zkdsl_compiler/src/lower/call.rs', lines 591:4-598:5 -/
axiom lower.call.FnLower.const_arg
  : lower.FnLower → ast.Expr → RustM (core.option.Option ast.Expr)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::eval::Known}::diverging_readings]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 27:4-30:5 -/
axiom lower.eval.Known.diverging_readings
  :
  lower.eval.Known → RustM (core.option.Option (Std.U128 ×
    verifier.field.E))

/-- [zkdsl_compiler::lower::eval::gmul]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 35:0-47:1 -/
axiom lower.eval.gmul
  : lower.GAddr → lower.GAddr → RustM (core.option.Option lower.GAddr)

/-- [zkdsl_compiler::lower::eval::field_pow]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 50:0-62:1 -/
axiom lower.eval.field_pow
  : verifier.field.E → Std.U32 → RustM verifier.field.E

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::eval]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 75:4-220:5 -/
axiom lower.eval.FnLower.eval
  : lower.FnLower → ast.Expr → RustM lower.eval.Known

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::try_const_int]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 224:4-226:5 -/
axiom lower.eval.FnLower.try_const_int
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.U128)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::gaddr_of]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 229:4-231:5 -/
axiom lower.eval.FnLower.gaddr_of
  : lower.FnLower → ast.Expr → RustM (core.option.Option lower.GAddr)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::try_field_const]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 236:4-238:5 -/
axiom lower.eval.FnLower.try_field_const
  : lower.FnLower → ast.Expr → RustM (core.option.Option verifier.field.E)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::try_const_index]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 242:4-244:5 -/
axiom lower.eval.FnLower.try_const_index
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.U32)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::const_index]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 248:4-255:5 -/
axiom lower.eval.FnLower.const_index
  : lower.FnLower → ast.Expr → RustM Std.U32

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::gpow_exp]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 258:4-262:5 -/
axiom lower.eval.FnLower.gpow_exp
  : lower.FnLower → ast.Expr → RustM Std.U128

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::const_array_elem]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 266:4-279:5 -/
axiom lower.eval.FnLower.const_array_elem
  : lower.FnLower → ast.Expr → RustM (core.option.Option verifier.field.E)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::const_len]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 282:4-291:5 -/
axiom lower.eval.FnLower.const_len
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.Usize)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::add_identity]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 297:4-302:5 -/
axiom lower.eval.FnLower.add_identity
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (core.option.Option
    ast.Expr)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::mul_identity]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 307:4-312:5 -/
axiom lower.eval.FnLower.mul_identity
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (core.option.Option
    ast.Expr)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::try_lit]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 317:4-324:5 -/
axiom lower.eval.FnLower.try_lit
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.U64)

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::check_const_leaves]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 337:4-360:5 -/
axiom lower.eval.FnLower.check_const_leaves
  : lower.FnLower → ast.Expr → RustM Unit

/-- [zkdsl_compiler::lower::eval::{zkdsl_compiler::lower::FnLower<'_0>}::const_gpow]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 368:4-384:5 -/
axiom lower.eval.FnLower.const_gpow
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.U32)

/-- [zkdsl_compiler::lower::eval::small_gpow]:
    Source: 'crates/zkdsl_compiler/src/lower/eval.rs', lines 388:0-394:1 -/
axiom lower.eval.small_gpow
  : verifier.field.E → RustM (core.option.Option Std.U128)

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::reserve]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 31:4-40:5 -/
axiom lower.hoist.FnLower.reserve
  :
  lower.FnLower → ir.Hint → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::hoist_heap_bufs]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 45:4-115:5 -/
axiom lower.hoist.FnLower.hoist_heap_bufs
  :
  lower.FnLower → RustM ((core.result.Result Unit alloc.string.String) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::hoist_past_first_branch]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 121:4-141:5 -/
axiom lower.hoist.FnLower.hoist_past_first_branch
  :
  lower.FnLower → RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::sized_by]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 153:4-160:5 -/
axiom lower.hoist.FnLower.sized_by
  :
  lower.FnLower → Std.Usize → Std.Usize →
    std.collections.hash.set.HashSet Std.U32 std.hash.random.RandomState
    alloc.alloc.Global → RustM (core.option.Option ir.Hint)

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::move_hints]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 163:4-170:5 -/
axiom lower.hoist.FnLower.move_hints
  :
  lower.FnLower → alloc.vec.Vec (Std.Usize × Std.Usize × ir.Hint) →
    (Std.Usize × Std.Usize) → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::runs_on_to]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 175:4-179:5 -/
axiom lower.hoist.FnLower.runs_on_to
  : lower.FnLower → Std.Usize → Std.Usize → RustM Bool

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::written_in]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 185:4-212:5 -/
axiom lower.hoist.FnLower.written_in
  :
  lower.FnLower → core.ops.range.Range Std.Usize → Std.Usize → RustM
    (std.collections.hash.set.HashSet Std.U32 std.hash.random.RandomState
    alloc.alloc.Global)

/-- [zkdsl_compiler::lower::hoist::{zkdsl_compiler::lower::FnLower<'_0>}::constant_exponent]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 215:4-221:5 -/
axiom lower.hoist.FnLower.constant_exponent
  :
  lower.FnLower → Std.U32 → Std.Usize → RustM (core.option.Option
    Std.U32)

/-- [zkdsl_compiler::lower::hoist::reservation]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 225:0-233:1 -/
axiom lower.hoist.reservation
  : ir.Hint → RustM (core.option.Option (Std.U32 × Bool))

/-- [zkdsl_compiler::lower::hoist::hint_writes]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 236:0-265:1 -/
axiom lower.hoist.hint_writes : ir.Hint → RustM (alloc.vec.Vec Std.U32)

/-- [zkdsl_compiler::lower::hoist::touched]:
    Source: 'crates/zkdsl_compiler/src/lower/hoist.rs', lines 274:0-286:1 -/
axiom lower.hoist.touched : ir.LOp → RustM (alloc.vec.Vec Std.U32)

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::cell_run]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 22:4-83:5 -/
axiom lower.mem.FnLower.cell_run
  :
  lower.FnLower → ast.Expr → RustM (ir.CellRun × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::heap_addr]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 87:4-89:5 -/
axiom lower.mem.FnLower.heap_addr
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM ((Std.U32 × Std.U32) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::heap_addr_span]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 93:4-160:5 -/
axiom lower.mem.FnLower.heap_addr_span
  :
  lower.FnLower → ast.Expr → ast.Expr → Std.U128 → RustM ((Std.U32 ×
    Std.U32) × lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::check_heap_bound]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 166:4-215:5 -/
axiom lower.mem.FnLower.check_heap_bound
  : lower.FnLower → ast.Expr → Std.U128 → Std.U128 → RustM Unit

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::check_bound]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 218:4-225:5 -/
axiom lower.mem.FnLower.check_bound : lower.FnLower → ast.Expr → RustM Unit

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::stack_addr]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 232:4-249:5 -/
axiom lower.mem.FnLower.stack_addr
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.GAddr × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::heap_base]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 255:4-269:5 -/
axiom lower.mem.FnLower.heap_base
  :
  lower.FnLower → ast.Expr → Std.U128 → Std.U128 → RustM ((Std.U32 ×
    Std.U32) × lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::array_ptr]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 278:4-291:5 -/
axiom lower.mem.FnLower.array_ptr
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM ((Std.U32 × Std.U32) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::materialize]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 296:4-331:5 -/
axiom lower.mem.FnLower.materialize
  :
  lower.FnLower → lower.GAddr → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::stack_of]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 334:4-339:5 -/
axiom lower.mem.FnLower.stack_of
  :
  lower.FnLower → ast.Expr → RustM (core.option.Option (Std.U32 ×
    Std.U32))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::alloc_stack]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 343:4-349:5 -/
axiom lower.mem.FnLower.alloc_stack
  :
  lower.FnLower → Std.U32 → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::heap_to_stack]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 352:4-356:5 -/
axiom lower.mem.FnLower.heap_to_stack
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.U32 → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::mem::{zkdsl_compiler::lower::FnLower<'_0>}::deref_run]:
    Source: 'crates/zkdsl_compiler/src/lower/mem.rs', lines 360:4-364:5 -/
axiom lower.mem.FnLower.deref_run
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.U32 → Std.U32 → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::RET_PC]
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 59:4-59:26 -/
axiom lower.Abi.RET_PC : RustM Std.U32

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::RET_FP]
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 60:4-60:26 -/
axiom lower.Abi.RET_FP : RustM Std.U32

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::arg]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 62:4-64:5 -/
axiom lower.Abi.arg
  {T0 : Type _} (coreitertraitsiteratorIteratorT0ShapeInst :
  core.iter.traits.iterator.Iterator T0 ast.Shape) :
  T0 → Std.Usize → RustM Std.U32

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::arg_cells]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 66:4-68:5 -/
axiom lower.Abi.arg_cells
  {T0 : Type _} (coreitertraitsiteratorIteratorT0ShapeInst :
  core.iter.traits.iterator.Iterator T0 ast.Shape) :
  T0 → RustM Std.U32

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::ret]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 70:4-72:5 -/
axiom lower.Abi.ret : Std.U32 → Std.U32 → RustM Std.U32

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::width]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 74:4-76:5 -/
axiom lower.Abi.width
  {T0 : Type _} (coreitertraitsiteratorIteratorT0ShapeInst :
  core.iter.traits.iterator.Iterator T0 ast.Shape) :
  T0 → RustM Std.U64

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::fit]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 79:4-84:5 -/
axiom lower.Abi.fit : Std.U64 → RustM Std.U32

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Abi}::end]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 86:4-88:5 -/
axiom lower.Abi.end : Std.U32 → Std.U32 → RustM Std.U32

/-- [zkdsl_compiler::lower::FOLD_MAX]
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 95:0-95:31 -/
axiom lower.FOLD_MAX : RustM Std.U128

/-- [zkdsl_compiler::lower::{impl core::clone::Clone for zkdsl_compiler::lower::Scope}::clone]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 130:9-130:14
    Visibility: public -/
axiom lower.Scope.Insts.CoreCloneClone.clone
  : lower.Scope → RustM lower.Scope

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Scope}::bound]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 169:4-171:5 -/
axiom lower.Scope.bound
  : lower.Scope → Str → RustM (core.option.Option lower.Bound)

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Scope}::stack]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 172:4-177:5 -/
axiom lower.Scope.stack
  : lower.Scope → Str → RustM (core.option.Option (Std.U32 × Std.U32))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Scope}::int]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 179:4-181:5 -/
axiom lower.Scope.int
  : lower.Scope → Str → RustM (core.option.Option Std.U128)

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::Scope}::set_int]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 183:4-187:5 -/
axiom lower.Scope.set_int
  : lower.Scope → Str → Std.U128 → RustM lower.Scope

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::fail]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 287:4-304:5 -/
axiom lower.FnLower.fail
  {T1 : Type _} (corefmtDisplayInst : core.fmt.Display T1) :
  lower.FnLower → T1 → RustM Never

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::fresh]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 306:4-308:5 -/
axiom lower.FnLower.fresh
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::emit]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 310:4-318:5 -/
axiom lower.FnLower.emit
  :
  lower.FnLower → ir.LOp → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::set]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 320:4-322:5 -/
axiom lower.FnLower.set
  :
  lower.FnLower → Std.U32 → ir.KVal → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::set_const]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 324:4-326:5 -/
axiom lower.FnLower.set_const
  :
  lower.FnLower → Std.U32 → verifier.field.E → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::deref]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 328:4-333:5 -/
axiom lower.FnLower.deref
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.U32 → isa.DerefMode → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::anchor]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 338:4-341:5 -/
axiom lower.FnLower.anchor
  :
  lower.FnLower → RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::check_not_reserved]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 351:4-358:5 -/
axiom lower.FnLower.check_not_reserved : lower.FnLower → Str → RustM Unit

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::rebind]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 361:4-364:5 -/
axiom lower.FnLower.rebind
  :
  lower.FnLower → Str → lower.Binding → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::bind_targets]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 368:4-372:5 -/
axiom lower.FnLower.bind_targets
  :
  lower.FnLower → Slice (Str × Std.U32) → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::pure]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 389:4-408:5 -/
axiom lower.FnLower.pure
  :
  lower.FnLower → lower.PureOp → Std.U32 → Std.U32 → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::frame_cell]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 416:4-423:5 -/
axiom lower.FnLower.frame_cell
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (core.option.Option
    Std.U32)

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::one]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 426:4-428:5 -/
axiom lower.FnLower.one
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::const_cell]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 441:4-449:5 -/
axiom lower.FnLower.const_cell
  :
  lower.FnLower → verifier.field.E → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::zero]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 453:4-455:5 -/
axiom lower.FnLower.zero
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::halt]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 461:4-470:5 -/
axiom lower.FnLower.halt
  :
  lower.FnLower → RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::copy_next_frame]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 473:4-476:5 -/
axiom lower.FnLower.copy_next_frame
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.U32 → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::copy]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 479:4-482:5 -/
axiom lower.FnLower.copy
  :
  lower.FnLower → Std.U32 → Std.U32 → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::self_fp]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 491:4-507:5 -/
axiom lower.FnLower.self_fp
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::patch_local]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 511:4-516:5 -/
axiom lower.FnLower.patch_local
  :
  lower.FnLower → Std.Usize → Std.Usize → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::new_branch]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 537:4-540:5 -/
axiom lower.FnLower.new_branch
  :
  lower.FnLower → Std.Usize → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::branch]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 543:4-549:5 -/
axiom lower.FnLower.branch
  :
  lower.FnLower → (Std.U32 × Std.U32) → Slice ast.Stmt → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::ret_targets]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 555:4-586:5 -/
axiom lower.FnLower.ret_targets
  :
  lower.FnLower → Slice ast.Expr → RustM (((alloc.vec.Vec Std.U32) ×
    (alloc.vec.Vec (Str × Std.U32))) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::lower_match]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 593:4-666:5 -/
axiom lower.FnLower.lower_match
  :
  lower.FnLower → Slice ast.Expr → ast.Expr → Slice ast.Expr → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::free_cell]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 671:4-694:5 -/
axiom lower.FnLower.free_cell
  :
  lower.FnLower → ast.Expr → Slice ast.Expr → RustM (core.option.Option
    Std.U32)

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::all_inline]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 698:4-701:5 -/
axiom lower.FnLower.all_inline
  : lower.FnLower → Slice ast.Expr → RustM Bool

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::table_jump]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 705:4-708:5 -/
axiom lower.FnLower.table_jump
  :
  lower.FnLower → Std.U32 → Std.Usize → Std.U32 → Std.U32 → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::table_jump_via]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 711:4-718:5 -/
axiom lower.FnLower.table_jump_via
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.Usize → Std.U32 → Std.U32
    → RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::lower_if]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 794:4-880:5 -/
axiom lower.FnLower.lower_if
  :
  lower.FnLower → Bool → ast.Expr → ast.Expr → Slice ast.Stmt → Slice
    ast.Stmt → Bool → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::lower_assert_ne]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 887:4-906:5 -/
axiom lower.FnLower.lower_assert_ne
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::bound_cell]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 916:4-918:5 -/
axiom lower.FnLower.bound_cell
  :
  lower.FnLower → Std.U64 → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::lower_assert_lt]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 940:4-985:5 -/
axiom lower.FnLower.lower_assert_lt
  :
  lower.FnLower → ast.Expr → ast.LtBound → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::range_check]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 988:4-996:5 -/
axiom lower.FnLower.range_check
  :
  lower.FnLower → ast.Expr → Std.U32 → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::unbound]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1005:4-1015:5 -/
axiom lower.FnLower.unbound : lower.FnLower → Str → RustM Never

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::expr]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1017:4-1155:5 -/
axiom lower.FnLower.expr
  :
  lower.FnLower → ast.Expr → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::pow_expr]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1159:4-1184:5 -/
axiom lower.FnLower.pow_expr
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (Std.U32 × lower.FnLower
    × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::expr_into]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1188:4-1239:5 -/
axiom lower.FnLower.expr_into
  :
  lower.FnLower → ast.Expr → Std.U32 → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::let_binding]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1244:4-1260:5 -/
axiom lower.FnLower.let_binding
  :
  lower.FnLower → ast.Expr → lower.eval.Known → RustM (lower.Binding ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::alias_of]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1264:4-1269:5 -/
axiom lower.FnLower.alias_of
  : lower.FnLower → ast.Expr → RustM (core.option.Option lower.Binding)

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::binding_cell]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1272:4-1282:5 -/
axiom lower.FnLower.binding_cell
  :
  lower.FnLower → lower.Binding → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::stmt]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1284:4-1458:5 -/
axiom lower.FnLower.stmt
  :
  lower.FnLower → ast.Stmt → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::settle_loop_captures]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1470:4-1494:5 -/
axiom lower.FnLower.settle_loop_captures
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [zkdsl_compiler::lower::{zkdsl_compiler::lower::FnLower<'_0>}::lower_for]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1510:4-1691:5 -/
axiom lower.FnLower.lower_for
  :
  lower.FnLower → Str → Std.U64 → ast.ForBound → Slice ast.Stmt →
    RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [zkdsl_compiler::lower::contains_return]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1694:0-1701:1 -/
axiom lower.contains_return : Slice ast.Stmt → RustM Bool

/-- [zkdsl_compiler::lower::calls_or_allocates]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1705:0-1725:1 -/
axiom lower.calls_or_allocates : ast.Expr → RustM Bool

/-- [zkdsl_compiler::lower::plus_k]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1730:0-1738:1 -/
axiom lower.plus_k
  : ast.Expr → ast.Expr → RustM (core.option.Option Std.U128)

/-- [zkdsl_compiler::lower::has_return]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1743:0-1750:1 -/
axiom lower.has_return : Slice ast.Stmt → RustM Bool

/-- [zkdsl_compiler::lower::param_binding]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1754:0-1760:1 -/
axiom lower.param_binding
  : Slice ast.Param → Std.Usize → RustM lower.Binding

/-- [zkdsl_compiler::lower::lower_func]:
    Source: 'crates/zkdsl_compiler/src/lower.rs', lines 1762:0-1905:1 -/
axiom lower.lower_func
  :
  ast.Func → alloc.vec.Vec ast.Func → std.collections.hash.map.HashMap Str
    ast.Func std.hash.random.RandomState alloc.alloc.Global →
    std.collections.hash.map.HashMap Str (Slice verifier.field.E)
    std.hash.random.RandomState alloc.alloc.Global →
    std.collections.hash.map.HashMap alloc.string.String (Std.U64 ×
    (core.option.Option Std.U64)) std.hash.random.RandomState
    alloc.alloc.Global → ir.JumpTables → RustM (ir.Lowered ×
    (alloc.vec.Vec ast.Func) × (std.collections.hash.map.HashMap
    alloc.string.String (Std.U64 × (core.option.Option Std.U64))
    std.hash.random.RandomState alloc.alloc.Global) × ir.JumpTables)

/-- [zkdsl_compiler::opt::rename]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 172:0-180:1 -/
axiom opt.rename
  {T0 : Type _} {Clause0_IntoIter : Type _}
  (coreitertraitscollectIntoIteratorT0UsizeClause0_IntoIterInst :
  core.iter.traits.collect.IntoIterator T0 Std.Usize Clause0_IntoIter) :
  Slice ir.LInstr → T0 → Std.U32 → Std.U32 → RustM (Slice ir.LInstr)

/-- [zkdsl_compiler::opt::copy_of]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 183:0-188:1 -/
axiom opt.copy_of
  :
  Slice ir.LInstr → Slice Bool → Std.Usize → RustM (core.option.Option
    (Std.U32 × Std.U32))

/-- [zkdsl_compiler::opt::block_end]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 192:0-194:1 -/
axiom opt.block_end
  : Slice Std.Usize → Std.Usize → Std.Usize → RustM Std.Usize

/-- [zkdsl_compiler::opt::{zkdsl_compiler::opt::Refs}::new]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 214:4-237:5 -/
axiom opt.Refs.new
  : Slice ir.LInstr → Slice Bool → RustM (opt.Refs × (Slice ir.LInstr))

/-- [zkdsl_compiler::opt::{zkdsl_compiler::opt::Refs}::of]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 239:4-241:5 -/
axiom opt.Refs.of
  : opt.Refs → Std.U32 → RustM (Slice (Std.Usize × opt.Role))

/-- [zkdsl_compiler::opt::{zkdsl_compiler::opt::Refs}::hinted]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 243:4-245:5 -/
axiom opt.Refs.impl.hinted : opt.Refs → Std.U32 → RustM Bool

/-- [zkdsl_compiler::opt::{zkdsl_compiler::opt::Refs}::in_run]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 247:4-249:5 -/
axiom opt.Refs.in_run : opt.Refs → Std.U32 → RustM Bool

/-- [zkdsl_compiler::opt::optimize]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 261:0-282:1 -/
axiom opt.optimize
  :
  Slice ir.Lowered → ir.JumpTables → RustM ((Slice ir.Lowered) ×
    ir.JumpTables)

/-- [zkdsl_compiler::opt::compact]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 409:0-431:1 -/
axiom opt.compact : ir.Lowered → RustM ir.Lowered

/-- [zkdsl_compiler::opt::block_starts]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 393:0-406:1 -/
axiom opt.block_starts
  : Slice ir.LInstr → Slice Std.U32 → RustM (alloc.vec.Vec Std.Usize)

/-- [zkdsl_compiler::opt::drop_dead]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 368:0-390:1 -/
axiom opt.drop_dead
  :
  ir.Lowered → Slice Bool → RustM ((core.option.Option (alloc.vec.Vec
    Std.U32)) × ir.Lowered)

/-- [zkdsl_compiler::opt::store_next_frame_copies]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 343:0-365:1 -/
axiom opt.store_next_frame_copies
  : ir.Lowered → Slice Bool → RustM ir.Lowered

/-- [zkdsl_compiler::opt::remove_copies]:
    Source: 'crates/zkdsl_compiler/src/opt.rs', lines 297:0-339:1 -/
axiom opt.remove_copies
  :
  ir.Lowered → Slice Bool → Slice Std.Usize → RustM (Bool × ir.Lowered
    × (Slice Bool))

/-- [zkdsl_compiler::parser::consts::eval_const_int]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 26:0-31:1 -/
axiom parser.consts.eval_const_int
  : Str → RustM (core.result.Result Std.U128 alloc.string.String)

/-- [zkdsl_compiler::parser::consts::is_int_arith]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 67:0-80:1 -/
axiom parser.consts.is_int_arith : ast.Expr → RustM Bool

/-- [zkdsl_compiler::parser::consts::parse_const]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 86:0-99:1
    Visibility: public -/
axiom parser.consts.parse_const
  : Str → RustM (core.result.Result verifier.field.E alloc.string.String)

/-- [zkdsl_compiler::parser::consts::f128_literal]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 102:0-104:1
    Visibility: public -/
axiom parser.consts.f128_literal
  : verifier.field.E → RustM alloc.string.String

/-- [zkdsl_compiler::parser::consts::gpow_bound]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 111:0-125:1 -/
axiom parser.consts.gpow_bound
  : ast.Expr → RustM (core.result.Result Std.U64 alloc.string.String)

/-- [zkdsl_compiler::parser::consts::parse_gpow_bound]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 127:0-129:1 -/
axiom parser.consts.parse_gpow_bound
  : Str → RustM (core.result.Result Std.U64 alloc.string.String)

/-- [zkdsl_compiler::parser::consts::apply_replacements]:
    Source: 'crates/zkdsl_compiler/src/parser/consts.rs', lines 137:0-167:1 -/
axiom parser.consts.apply_replacements
  :
  Str → alloc.collections.btree.map.BTreeMap alloc.string.String
    alloc.string.String alloc.alloc.Global → RustM alloc.string.String

/-- [zkdsl_compiler::parser::expr::parse_expr]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 21:0-189:1 -/
axiom parser.expr.parse_expr
  : Str → RustM (core.result.Result ast.Expr alloc.string.String)

/-- [zkdsl_compiler::parser::expr::fold_ops]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 193:0-222:1 -/
axiom parser.expr.fold_ops
  {T0 : Type _} (coreopsfunctionFnT0TupleU8ArcExprArcExprExprInst :
  core.ops.function.Fn T0 (Std.U8 × (alloc.sync.Arc ast.Expr) ×
  (alloc.sync.Arc ast.Expr)) ast.Expr) :
  Slice Str → Slice Std.U8 → T0 → RustM (core.result.Result ast.Expr
    alloc.string.String)

/-- [zkdsl_compiler::parser::expr::depth0]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 227:0-254:1 -/
axiom parser.expr.depth0
  :
  Str → RustM (core.iter.adapters.filter_map.FilterMap
    (core.iter.adapters.enumerate.Enumerate (core.slice.iter.Iter Std.U8))
    parser.expr.depth0.closure)

/-- [zkdsl_compiler::parser::expr::depth0::{impl core::ops::function::FnMut<((usize, &'_0 u8),), core::option::Option<(usize, u8)>> for zkdsl_compiler::parser::expr::depth0::{closure}}::call_mut]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 230:47-253:5 -/
axiom
  parser.expr.depth0.closure.Insts.CoreOpsFunctionFnMutTuplePairUsizeShared0U8OptionPairUsizeU8.call_mut
  :
  parser.expr.depth0.closure → (Std.Usize × Std.U8) → RustM
    ((core.option.Option (Std.Usize × Std.U8)) × parser.expr.depth0.closure)

/-- [zkdsl_compiler::parser::expr::split_add]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 259:0-271:1 -/
axiom parser.expr.split_add
  : Str → RustM ((alloc.vec.Vec Str) × (alloc.vec.Vec Std.U8))

/-- [zkdsl_compiler::parser::expr::split_mul]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 277:0-300:1 -/
axiom parser.expr.split_mul
  : Str → RustM ((alloc.vec.Vec Str) × (alloc.vec.Vec Std.U8))

/-- [zkdsl_compiler::parser::expr::split_once_top]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 303:0-311:1 -/
axiom parser.expr.split_once_top
  : Str → Str → RustM (core.option.Option (Str × Str))

/-- [zkdsl_compiler::parser::expr::split_top]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 314:0-326:1 -/
axiom parser.expr.split_top : Str → Char → RustM (alloc.vec.Vec Str)

/-- [zkdsl_compiler::parser::expr::split_assign]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 333:0-345:1 -/
axiom parser.expr.split_assign
  : Str → RustM (core.option.Option (Str × Str))

/-- [zkdsl_compiler::parser::expr::split_aug]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 356:0-393:1 -/
axiom parser.expr.split_aug
  :
  Str → RustM (core.result.Result (core.option.Option (Str × Str × Str))
    alloc.string.String)

/-- [zkdsl_compiler::parser::expr::call_args]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 398:0-401:1 -/
axiom parser.expr.call_args
  : Str → Str → RustM (core.option.Option (alloc.vec.Vec Str))

/-- [zkdsl_compiler::parser::expr::string_lit]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 404:0-406:1 -/
axiom parser.expr.string_lit : Str → RustM (core.option.Option Str)

/-- [zkdsl_compiler::parser::expr::strip_comment]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 411:0-421:1 -/
axiom parser.expr.strip_comment : Str → RustM Str

/-- [zkdsl_compiler::parser::expr::top_level_cmp]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 426:0-439:1 -/
axiom parser.expr.top_level_cmp : Str → RustM (core.option.Option Str)

/-- [zkdsl_compiler::parser::expr::is_ident]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 443:0-446:1 -/
axiom parser.expr.is_ident : Str → RustM Bool

/-- [zkdsl_compiler::parser::expr::not_reserved]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 450:0-457:1 -/
axiom parser.expr.not_reserved
  : Str → RustM (core.result.Result Unit alloc.string.String)

/-- [zkdsl_compiler::parser::expr::binding_name]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 464:0-474:1 -/
axiom parser.expr.binding_name
  :
  Str → Str → RustM (core.result.Result alloc.string.String
    alloc.string.String)

/-- [zkdsl_compiler::parser::expr::strip_const_wrapper]:
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 480:0-496:1 -/
axiom parser.expr.strip_const_wrapper : Str → RustM (core.option.Option Str)

/-- [zkdsl_compiler::parser::subst::subst_stmts]:
    Source: 'crates/zkdsl_compiler/src/parser/subst.rs', lines 23:0-25:1 -/
axiom parser.subst.subst_stmts
  : Slice ast.Stmt → Str → ast.Expr → RustM (alloc.vec.Vec ast.Stmt)

/-- [zkdsl_compiler::parser::subst::subst_all]:
    Source: 'crates/zkdsl_compiler/src/parser/subst.rs', lines 31:0-46:1 -/
axiom parser.subst.subst_all
  :
  Slice ast.Stmt → Slice (Str × ast.Expr) → RustM (alloc.vec.Vec ast.Stmt)

/-- [zkdsl_compiler::parser::subst::subst_kind]:
    Source: 'crates/zkdsl_compiler/src/parser/subst.rs', lines 48:0-130:1 -/
axiom parser.subst.subst_kind
  : ast.StmtKind → Slice (Str × ast.Expr) → RustM ast.StmtKind

/-- [zkdsl_compiler::parser::subst::subst_var]:
    Source: 'crates/zkdsl_compiler/src/parser/subst.rs', lines 134:0-136:1 -/
axiom parser.subst.subst_var : ast.Expr → Str → ast.Expr → RustM ast.Expr

/-- [zkdsl_compiler::parser::subst::subst_vars]:
    Source: 'crates/zkdsl_compiler/src/parser/subst.rs', lines 138:0-140:1 -/
axiom parser.subst.subst_vars
  : ast.Expr → Slice (Str × ast.Expr) → RustM ast.Expr

/-- [zkdsl_compiler::parser::subst::subst_shared]:
    Source: 'crates/zkdsl_compiler/src/parser/subst.rs', lines 145:0-184:1 -/
axiom parser.subst.subst_shared
  :
  ast.Expr → Slice (Str × ast.Expr) → RustM (core.option.Option ast.Expr)

/-- [zkdsl_compiler::parser::subst::subst_list]:
    Source: 'crates/zkdsl_compiler/src/parser/subst.rs', lines 187:0-203:1 -/
axiom parser.subst.subst_list
  :
  Slice ast.Expr → Slice (Str × ast.Expr) → RustM (core.option.Option
    (alloc.vec.Vec ast.Expr))

/-- [zkdsl_compiler::parser::parse]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 32:0-34:1
    Visibility: public -/
axiom parser.parse
  : Str → RustM (core.result.Result ast.Ast alloc.string.String)

/-- [zkdsl_compiler::parser::parse_with_replacements]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 43:0-45:1
    Visibility: public -/
axiom parser.parse_with_replacements
  :
  Str → alloc.collections.btree.map.BTreeMap alloc.string.String
    alloc.string.String alloc.alloc.Global → RustM (core.result.Result
    ast.Ast alloc.string.String)

/-- [zkdsl_compiler::parser::parse_with_constants]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 49:0-245:1
    Visibility: public -/
axiom parser.parse_with_constants
  :
  Str → alloc.collections.btree.map.BTreeMap alloc.string.String
    alloc.string.String alloc.alloc.Global → RustM (core.result.Result
    (ast.Ast × (alloc.vec.Vec (alloc.string.String × alloc.string.String)))
    alloc.string.String)

/-- [zkdsl_compiler::parser::BUILTINS]
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 250:0-274:2 -/
axiom parser.BUILTINS : RustM (Slice Str)

/-- [zkdsl_compiler::parser::infer_return_shapes]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 280:0-361:1 -/
axiom parser.infer_return_shapes : Slice ast.Func → RustM (Slice ast.Func)

/-- [zkdsl_compiler::parser::whole_call]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 373:0-398:1 -/
axiom parser.whole_call : Str → RustM Bool

/-- [zkdsl_compiler::parser::locate]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 400:0-406:1 -/
axiom parser.locate
  : Std.Usize → alloc.string.String → RustM alloc.string.String

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::here]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 423:4-428:5 -/
axiom parser.Parser.here : parser.Parser → RustM Std.Usize

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::func]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 430:4-433:5 -/
axiom parser.Parser.func
  :
  parser.Parser → RustM ((core.result.Result ast.Func alloc.string.String) ×
    parser.Parser)

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::func_inner]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 435:4-453:5 -/
axiom parser.Parser.func_inner
  :
  parser.Parser → RustM ((core.result.Result ast.Func alloc.string.String) ×
    parser.Parser)

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::func_header]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 455:4-535:5 -/
axiom parser.Parser.func_header
  :
  parser.Parser → Bool → Std.Usize → Str → RustM ((core.result.Result
    ast.Func alloc.string.String) × parser.Parser)

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::block]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 538:4-554:5 -/
axiom parser.Parser.block
  :
  parser.Parser → Std.Usize → RustM ((core.result.Result (alloc.vec.Vec
    ast.Stmt) alloc.string.String) × parser.Parser)

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::stmt]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 556:4-561:5 -/
axiom parser.Parser.stmt
  :
  parser.Parser → Std.Usize → RustM ((core.result.Result ast.Stmt
    alloc.string.String) × parser.Parser)

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::stmt_inner]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 563:4-796:5 -/
axiom parser.Parser.stmt_inner
  :
  parser.Parser → Std.Usize → RustM ((core.result.Result ast.StmtKind
    alloc.string.String) × parser.Parser)

/-- [zkdsl_compiler::parser::{zkdsl_compiler::parser::Parser<'_0>}::if_stmt]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 802:4-865:5 -/
axiom parser.Parser.if_stmt
  :
  parser.Parser → Str → Std.Usize → RustM ((core.result.Result
    ast.StmtKind alloc.string.String) × parser.Parser)

/-- [zkdsl_compiler::parser::stream_name]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 872:0-880:1 -/
axiom parser.stream_name
  : Str → RustM (core.result.Result alloc.string.String alloc.string.String)

/-- [zkdsl_compiler::parser::strip_log]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 887:0-896:1 -/
axiom parser.strip_log
  :
  Str → RustM (core.result.Result (core.option.Option Str)
    alloc.string.String)

/-- [zkdsl_compiler::parser::parse_match]:
    Source: 'crates/zkdsl_compiler/src/parser.rs', lines 904:0-951:1 -/
axiom parser.parse_match
  : Str → Str → RustM (core.result.Result ast.StmtKind alloc.string.String)

end zkdsl_compiler
