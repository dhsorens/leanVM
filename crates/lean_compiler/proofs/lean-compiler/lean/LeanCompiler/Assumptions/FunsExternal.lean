-- [lean_compiler]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import LeanCompiler.Extraction.Types
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
open lean_compiler

/-- [lean_compiler::ast::{impl core::clone::Clone for lean_compiler::ast::Expr}::clone]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 6:9-6:14
    Visibility: public -/
axiom ast.Expr.Insts.CoreCloneClone.clone : ast.Expr → RustM ast.Expr

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::Expr}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 6:16-6:21
    Visibility: public -/
axiom ast.Expr.Insts.CoreFmtDebug.fmt
  :
  ast.Expr → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{impl core::cmp::PartialEq<lean_compiler::ast::Expr> for lean_compiler::ast::Expr}::eq]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 6:23-6:32
    Visibility: public -/
axiom ast.Expr.Insts.CoreCmpPartialEqExpr.eq
  : ast.Expr → ast.Expr → RustM Bool

/-- [lean_compiler::ast::{impl core::clone::Clone for lean_compiler::ast::Stmt}::clone]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 89:9-89:14
    Visibility: public -/
axiom ast.Stmt.Insts.CoreCloneClone.clone : ast.Stmt → RustM ast.Stmt

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::Stmt}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 89:16-89:21
    Visibility: public -/
axiom ast.Stmt.Insts.CoreFmtDebug.fmt
  :
  ast.Stmt → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{lean_compiler::ast::Stmt}::new]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 96:4-98:5
    Visibility: public -/
axiom ast.Stmt.new : Std.U32 → ast.StmtKind → RustM ast.Stmt

/-- [lean_compiler::ast::{lean_compiler::ast::Stmt}::at]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 102:4-104:5
    Visibility: public -/
axiom ast.Stmt.at : ast.Stmt → ast.StmtKind → RustM ast.Stmt

/-- [lean_compiler::ast::{impl core::clone::Clone for lean_compiler::ast::StmtKind}::clone]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 108:9-108:14
    Visibility: public -/
axiom ast.StmtKind.Insts.CoreCloneClone.clone
  : ast.StmtKind → RustM ast.StmtKind

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::StmtKind}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 108:16-108:21
    Visibility: public -/
axiom ast.StmtKind.Insts.CoreFmtDebug.fmt
  :
  ast.StmtKind → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::ForBound}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 200:16-200:21
    Visibility: public -/
axiom ast.ForBound.Insts.CoreFmtDebug.fmt
  :
  ast.ForBound → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::LtBound}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 213:16-213:21
    Visibility: public -/
axiom ast.LtBound.Insts.CoreFmtDebug.fmt
  :
  ast.LtBound → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::Shape}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 220:22-220:27
    Visibility: public -/
axiom ast.Shape.Insts.CoreFmtDebug.fmt
  :
  ast.Shape → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::Param}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 240:16-240:21
    Visibility: public -/
axiom ast.Param.Insts.CoreFmtDebug.fmt
  :
  ast.Param → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::ParamKind}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 246:22-246:27
    Visibility: public -/
axiom ast.ParamKind.Insts.CoreFmtDebug.fmt
  :
  ast.ParamKind → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::Func}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 263:16-263:21
    Visibility: public -/
axiom ast.Func.Insts.CoreFmtDebug.fmt
  :
  ast.Func → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::{lean_compiler::ast::Func}::has_const_params]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 280:4-282:5 -/
axiom ast.Func.has_const_params : ast.Func → RustM Bool

/-- [lean_compiler::ast::{impl core::clone::Clone for lean_compiler::ast::Ast}::clone]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 290:9-290:14
    Visibility: public -/
axiom ast.Ast.Insts.CoreCloneClone.clone : ast.Ast → RustM ast.Ast

/-- [lean_compiler::ast::{impl core::fmt::Debug for lean_compiler::ast::Ast}::fmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 290:16-290:21
    Visibility: public -/
axiom ast.Ast.Insts.CoreFmtDebug.fmt
  :
  ast.Ast → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ast::free_vars_expr]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 306:0-336:1 -/
axiom ast.free_vars_expr
  : ast.Expr → alloc.vec.Vec Str → RustM (alloc.vec.Vec Str)

/-- [lean_compiler::ast::binds_anywhere]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 342:0-367:1 -/
axiom ast.binds_anywhere
  :
  Slice ast.Stmt → std.collections.hash.set.HashSet Str
    std.hash.random.RandomState alloc.alloc.Global → RustM
    (std.collections.hash.set.HashSet Str std.hash.random.RandomState
    alloc.alloc.Global)

/-- [lean_compiler::ast::scoped_vars]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 370:0-375:1 -/
axiom ast.scoped_vars
  : Slice ast.Stmt → alloc.vec.Vec Str → RustM (alloc.vec.Vec Str)

/-- [lean_compiler::ast::free_vars_stmt]:
    Source: 'crates/lean_compiler/src/ast.rs', lines 377:0-475:1 -/
axiom ast.free_vars_stmt
  :
  ast.Stmt → alloc.vec.Vec Str → std.collections.hash.set.HashSet Str
    std.hash.random.RandomState alloc.alloc.Global → RustM ((alloc.vec.Vec
    Str) × (std.collections.hash.set.HashSet Str std.hash.random.RandomState
    alloc.alloc.Global))

/-- [lean_compiler::ir::{impl core::fmt::Debug for lean_compiler::ir::KVal}::fmt]:
    Source: 'crates/lean_compiler/src/ir.rs', lines 9:16-9:21
    Visibility: public -/
axiom ir.KVal.Insts.CoreFmtDebug.fmt
  :
  ir.KVal → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ir::{impl core::fmt::Debug for lean_compiler::ir::LInstr}::fmt]:
    Source: 'crates/lean_compiler/src/ir.rs', lines 32:16-32:21
    Visibility: public -/
axiom ir.LInstr.Insts.CoreFmtDebug.fmt
  :
  ir.LInstr → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ir::{impl core::fmt::Debug for lean_compiler::ir::LOp}::fmt]:
    Source: 'crates/lean_compiler/src/ir.rs', lines 43:16-43:21
    Visibility: public -/
axiom ir.LOp.Insts.CoreFmtDebug.fmt
  :
  ir.LOp → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ir::{impl core::fmt::Debug for lean_compiler::ir::Hint}::fmt]:
    Source: 'crates/lean_compiler/src/ir.rs', lines 100:16-100:21
    Visibility: public -/
axiom ir.Hint.Insts.CoreFmtDebug.fmt
  :
  ir.Hint → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::ir::{impl core::fmt::Debug for lean_compiler::ir::LoopCount}::fmt]:
    Source: 'crates/lean_compiler/src/ir.rs', lines 152:16-152:21
    Visibility: public -/
axiom ir.LoopCount.Insts.CoreFmtDebug.fmt
  :
  ir.LoopCount → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::compile]:
    Source: 'crates/lean_compiler/src/lib.rs', lines 50:0-212:1
    Visibility: public -/
axiom compile : ast.Ast → RustM leanvm_core.cpu.Program

/-- [lean_compiler::disassemble]:
    Source: 'crates/lean_compiler/src/lib.rs', lines 217:0-274:1
    Visibility: public -/
axiom disassemble : Slice leanvm_core.cpu.isa.Op → RustM alloc.string.String

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::lower_keccak]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 32:4-67:5 -/
axiom lower.builtins.FnLower.lower_keccak
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::lower_keccak_cells]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 79:4-130:5 -/
axiom lower.builtins.FnLower.lower_keccak_cells
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::keccak_len]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 133:4-145:5 -/
axiom lower.builtins.FnLower.keccak_len
  :
  lower.FnLower → std.collections.hash.map.HashMap Str ast.Expr
    std.hash.random.RandomState alloc.alloc.Global → Std.U32 → RustM
    Std.U32

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::keccak_kwargs]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 148:4-189:5 -/
axiom lower.builtins.FnLower.keccak_kwargs
  :
  lower.FnLower → Slice ast.Expr → Str → Slice Str → Slice Str →
    RustM (std.collections.hash.map.HashMap Str ast.Expr
    std.hash.random.RandomState alloc.alloc.Global)

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::keccak_out]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 193:4-209:5 -/
axiom lower.builtins.FnLower.keccak_out
  :
  lower.FnLower → ast.Expr → RustM (lower.builtins.KeccakOut ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::keccak_finish]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 212:4-222:5 -/
axiom lower.builtins.FnLower.keccak_finish
  :
  lower.FnLower → lower.builtins.KeccakOut → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::emit_keccak_message]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 227:4-279:5 -/
axiom lower.builtins.FnLower.emit_keccak_message
  :
  lower.FnLower → alloc.vec.Vec lower.builtins.SpongeCell →
    core.option.Option Std.U32 → core.option.Option Std.U32 → Std.U32 →
    RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::xor_byte]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 282:4-299:5 -/
axiom lower.builtins.FnLower.xor_byte
  :
  lower.FnLower → Slice lower.builtins.SpongeCell → Std.Usize → Std.U8
    → RustM (lower.FnLower × (lower.FnLower → lower.FnLower) × (Slice
    lower.builtins.SpongeCell))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::keccak_rate]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 303:4-319:5 -/
axiom lower.builtins.FnLower.keccak_rate
  :
  lower.FnLower → Slice lower.builtins.SpongeCell → core.option.Option
    Std.U32 → RustM (((Array Std.U32 4#usize) × Std.U32) × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::sponge_xor]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 323:4-343:5 -/
axiom lower.builtins.FnLower.sponge_xor
  :
  lower.FnLower → Std.U32 → lower.builtins.SpongeCell →
    core.option.Option Std.U32 → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::sponge_run]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 347:4-374:5 -/
axiom lower.builtins.FnLower.sponge_run
  :
  lower.FnLower → Slice lower.builtins.SpongeCell → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::lower_builtin]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 382:4-450:5 -/
axiom lower.builtins.FnLower.lower_builtin
  :
  lower.FnLower → Str → Slice ast.Expr → RustM (Bool × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::sponge_cells]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 455:4-470:5 -/
axiom lower.builtins.FnLower.sponge_cells
  :
  lower.FnLower → ast.Expr → RustM ((alloc.vec.Vec
    lower.builtins.SpongeCell) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::keccak_operand]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 473:4-487:5 -/
axiom lower.builtins.FnLower.keccak_operand
  :
  lower.FnLower → ast.Expr → Std.Usize → RustM ((alloc.vec.Vec
    lower.builtins.SpongeCell) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::prev_state]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 491:4-500:5 -/
axiom lower.builtins.FnLower.prev_state
  :
  lower.FnLower → ast.Expr → Std.U32 → RustM ((core.option.Option
    Std.U32) × lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::try_cell_run]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 503:4-508:5 -/
axiom lower.builtins.FnLower.try_cell_run
  :
  lower.FnLower → ast.Expr → RustM ((core.result.Result ir.CellRun Unit) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::sponge_cell]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 511:4-518:5 -/
axiom lower.builtins.FnLower.sponge_cell
  :
  lower.FnLower → lower.builtins.SpongeCell → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::keccak_pad_run]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 523:4-538:5 -/
axiom lower.builtins.FnLower.keccak_pad_run
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::bits_dest]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 543:4-564:5 -/
axiom lower.builtins.FnLower.bits_dest
  :
  lower.FnLower → ast.Expr → Std.U32 → Str → RustM
    (leanvm_core.cpu.hints.BitsDest × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::builtins::{lean_compiler::lower::FnLower<'_0>}::lower_hint_witness]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 569:4-576:5 -/
axiom lower.builtins.FnLower.lower_hint_witness
  :
  lower.FnLower → ast.Expr → Str → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [lean_compiler::lower::builtins::{impl core::fmt::Debug for lean_compiler::lower::builtins::SpongeCell}::fmt]:
    Source: 'crates/lean_compiler/src/lower/builtins.rs', lines 599:22-599:27
    Visibility: public -/
axiom lower.builtins.SpongeCell.Insts.CoreFmtDebug.fmt
  :
  lower.builtins.SpongeCell → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_compiler::lower::call::substitute_body]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 30:0-34:1 -/
-- hand-maintained: Aeneas gives `Cow` two type arguments, the hax Lean library's takes one.
axiom lower.call.substitute_body
  :
  Slice ast.Stmt → Slice (Str × ast.Expr) → RustM (alloc.borrow.Cow (Slice
    ast.Stmt))

/-- [lean_compiler::lower::call::body_inlinable]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 37:0-40:1 -/
axiom lower.call.body_inlinable : Slice ast.Stmt → RustM Bool

/-- [lean_compiler::lower::call::stmt_inline_safe]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 42:0-58:1 -/
axiom lower.call.stmt_inline_safe : ast.Stmt → RustM Bool

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::lower_call]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 63:4-203:5 -/
axiom lower.call.FnLower.lower_call
  :
  lower.FnLower → Str → Slice ast.Expr → core.option.Option Std.U32 →
    Slice Std.U32 → Bool → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::lower_dispatched_call]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 211:4-316:5 -/
axiom lower.call.FnLower.lower_dispatched_call
  :
  lower.FnLower → Slice ast.Expr → ast.Expr → Slice alloc.string.String
    → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::try_inline]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 323:4-391:5 -/
axiom lower.call.FnLower.try_inline
  :
  lower.FnLower → Str → Slice ast.Expr → Slice Std.U32 → RustM (Bool ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::lower_return]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 393:4-454:5 -/
axiom lower.call.FnLower.lower_return
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::specialize]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 460:4-491:5 -/
axiom lower.call.FnLower.specialize
  :
  lower.FnLower → Str → Slice ast.Expr → RustM ((alloc.string.String ×
    (alloc.vec.Vec ast.Expr)) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::call]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 497:4-544:5 -/
axiom lower.call.FnLower.call
  :
  lower.FnLower → Str → Slice ast.Expr → Std.Usize → RustM
    ((alloc.vec.Vec Std.U32) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::call_into]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 548:4-567:5 -/
axiom lower.call.FnLower.call_into
  :
  lower.FnLower → Str → Slice ast.Expr → Slice Std.U32 → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::const_substs]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 569:4-587:5 -/
axiom lower.call.FnLower.const_substs
  :
  lower.FnLower → ast.Func → Slice ast.Expr → RustM (core.result.Result
    (alloc.vec.Vec (Str × ast.Expr)) alloc.string.String)

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::callee_def]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 590:4-595:5 -/
axiom lower.call.FnLower.callee_def
  : lower.FnLower → Str → RustM (core.option.Option ast.Func)

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::take_inline_ret_cell]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 604:4-618:5 -/
axiom lower.call.FnLower.take_inline_ret_cell
  :
  lower.FnLower → Std.U32 → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::call::{lean_compiler::lower::FnLower<'_0>}::const_arg]:
    Source: 'crates/lean_compiler/src/lower/call.rs', lines 624:4-631:5 -/
axiom lower.call.FnLower.const_arg
  : lower.FnLower → ast.Expr → RustM (core.option.Option ast.Expr)

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::eval]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 75:4-230:5 -/
axiom lower.eval.FnLower.eval
  : lower.FnLower → ast.Expr → RustM lower.eval.Known

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::try_const_index]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 252:4-254:5 -/
axiom lower.eval.FnLower.try_const_index
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.U32)

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::const_index]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 258:4-265:5 -/
axiom lower.eval.FnLower.const_index
  : lower.FnLower → ast.Expr → RustM Std.U32

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::gpow_exp]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 268:4-272:5 -/
axiom lower.eval.FnLower.gpow_exp
  : lower.FnLower → ast.Expr → RustM Std.U128

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::const_array_elem]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 276:4-289:5 -/
axiom lower.eval.FnLower.const_array_elem
  :
  lower.FnLower → ast.Expr → RustM (core.option.Option
    primitives.field.gf2_64x3.F192)

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::const_len]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 292:4-301:5 -/
axiom lower.eval.FnLower.const_len
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.Usize)

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::add_identity]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 307:4-312:5 -/
axiom lower.eval.FnLower.add_identity
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (core.option.Option
    ast.Expr)

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::mul_identity]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 317:4-322:5 -/
axiom lower.eval.FnLower.mul_identity
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (core.option.Option
    ast.Expr)

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::try_lit]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 327:4-334:5 -/
axiom lower.eval.FnLower.try_lit
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.U64)

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::check_const_leaves]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 347:4-370:5 -/
axiom lower.eval.FnLower.check_const_leaves
  : lower.FnLower → ast.Expr → RustM Unit

/-- [lean_compiler::lower::eval::{lean_compiler::lower::FnLower<'_0>}::const_gpow]:
    Source: 'crates/lean_compiler/src/lower/eval.rs', lines 378:4-394:5 -/
axiom lower.eval.FnLower.const_gpow
  : lower.FnLower → ast.Expr → RustM (core.option.Option Std.U32)

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::cell_run]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 22:4-87:5 -/
axiom lower.mem.FnLower.cell_run
  :
  lower.FnLower → ast.Expr → RustM (ir.CellRun × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::heap_addr]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 91:4-144:5 -/
axiom lower.mem.FnLower.heap_addr
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM ((Std.U32 × Std.U32) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::check_heap_bound]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 150:4-198:5 -/
axiom lower.mem.FnLower.check_heap_bound
  : lower.FnLower → ast.Expr → Std.U128 → Std.U128 → RustM Unit

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::stack_addr]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 205:4-220:5 -/
axiom lower.mem.FnLower.stack_addr
  :
  lower.FnLower → Slice ast.Expr → RustM (lower.GAddr × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::heap_base]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 225:4-239:5 -/
axiom lower.mem.FnLower.heap_base
  :
  lower.FnLower → ast.Expr → Std.U128 → RustM ((Std.U32 × Std.U32) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::array_ptr]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 248:4-261:5 -/
axiom lower.mem.FnLower.array_ptr
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM ((Std.U32 × Std.U32) ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::materialize]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 266:4-277:5 -/
axiom lower.mem.FnLower.materialize
  :
  lower.FnLower → lower.GAddr → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::stack_of]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 280:4-285:5 -/
axiom lower.mem.FnLower.stack_of
  :
  lower.FnLower → ast.Expr → RustM (core.option.Option (Std.U32 ×
    Std.U32))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::alloc_stack]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 289:4-293:5 -/
axiom lower.mem.FnLower.alloc_stack
  :
  lower.FnLower → Std.U32 → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::heap_to_stack]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 296:4-300:5 -/
axiom lower.mem.FnLower.heap_to_stack
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.U32 → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::mem::{lean_compiler::lower::FnLower<'_0>}::deref_run]:
    Source: 'crates/lean_compiler/src/lower/mem.rs', lines 304:4-308:5 -/
axiom lower.mem.FnLower.deref_run
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.U32 → Std.U32 → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::Abi}::arg]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 62:4-64:5 -/
axiom lower.Abi.arg
  {T0 : Type _} (coreitertraitsiteratorIteratorT0ShapeInst :
  core.iter.traits.iterator.Iterator T0 ast.Shape) :
  T0 → Std.Usize → RustM Std.U32

/-- [lean_compiler::lower::{lean_compiler::lower::Abi}::arg_cells]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 66:4-68:5 -/
axiom lower.Abi.arg_cells
  {T0 : Type _} (coreitertraitsiteratorIteratorT0ShapeInst :
  core.iter.traits.iterator.Iterator T0 ast.Shape) :
  T0 → RustM Std.U32

/-- [lean_compiler::lower::{impl core::clone::Clone for lean_compiler::lower::Scope}::clone]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 130:9-130:14
    Visibility: public -/
axiom lower.Scope.Insts.CoreCloneClone.clone
  : lower.Scope → RustM lower.Scope

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::fail]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 244:4-261:5 -/
axiom lower.FnLower.fail
  {T1 : Type _} (corefmtDisplayInst : core.fmt.Display T1) :
  lower.FnLower → T1 → RustM Never

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::fresh]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 263:4-267:5 -/
axiom lower.FnLower.fresh
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::emit]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 269:4-276:5 -/
axiom lower.FnLower.emit
  :
  lower.FnLower → ir.LOp → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::set]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 278:4-280:5 -/
axiom lower.FnLower.set
  :
  lower.FnLower → Std.U32 → ir.KVal → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::set_const]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 282:4-284:5 -/
axiom lower.FnLower.set_const
  :
  lower.FnLower → Std.U32 → primitives.field.gf2_64x3.F192 → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::deref]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 286:4-291:5 -/
axiom lower.FnLower.deref
  :
  lower.FnLower → Std.U32 → Std.U32 → Std.U32 →
    leanvm_core.cpu.isa.DerefMode → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::anchor]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 296:4-299:5 -/
axiom lower.FnLower.anchor
  :
  lower.FnLower → RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::check_not_reserved]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 309:4-316:5 -/
axiom lower.FnLower.check_not_reserved : lower.FnLower → Str → RustM Unit

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::rebind]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 319:4-322:5 -/
axiom lower.FnLower.rebind
  :
  lower.FnLower → Str → lower.Binding → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::bind_targets]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 326:4-330:5 -/
axiom lower.FnLower.bind_targets
  :
  lower.FnLower → Slice (Str × Std.U32) → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::pure]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 345:4-357:5 -/
axiom lower.FnLower.pure
  :
  lower.FnLower → lower.PureOp → Std.U32 → Std.U32 → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::frame_cell]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 365:4-372:5 -/
axiom lower.FnLower.frame_cell
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM ((core.option.Option
    Std.U32) × lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::one]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 375:4-377:5 -/
axiom lower.FnLower.one
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::const_cell]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 390:4-399:5 -/
axiom lower.FnLower.const_cell
  :
  lower.FnLower → primitives.field.gf2_64x3.F192 → RustM (Std.U32 ×
    lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::zero]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 404:4-406:5 -/
axiom lower.FnLower.zero
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::halt]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 412:4-421:5 -/
axiom lower.FnLower.halt
  :
  lower.FnLower → RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::copy]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 424:4-427:5 -/
axiom lower.FnLower.copy
  :
  lower.FnLower → Std.U32 → Std.U32 → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::self_fp]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 435:4-449:5 -/
axiom lower.FnLower.self_fp
  :
  lower.FnLower → RustM (Std.U32 × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::patch_local]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 453:4-458:5 -/
axiom lower.FnLower.patch_local
  :
  lower.FnLower → Std.Usize → Std.Usize → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::branch]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 477:4-483:5 -/
axiom lower.FnLower.branch
  :
  lower.FnLower → Slice ast.Stmt → RustM (lower.FnLower × (lower.FnLower
    → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::ret_targets]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 489:4-516:5 -/
axiom lower.FnLower.ret_targets
  :
  lower.FnLower → Slice ast.Expr → RustM (((alloc.vec.Vec Std.U32) ×
    (alloc.vec.Vec (Str × Std.U32))) × lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::lower_match]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 523:4-598:5 -/
axiom lower.FnLower.lower_match
  :
  lower.FnLower → Slice ast.Expr → ast.Expr → Slice ast.Expr → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::table_jump]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 602:4-610:5 -/
axiom lower.FnLower.table_jump
  :
  lower.FnLower → Std.U32 → Std.Usize → Std.U32 → Std.U32 → RustM
    (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::lower_if]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 651:4-740:5 -/
axiom lower.FnLower.lower_if
  :
  lower.FnLower → Bool → ast.Expr → ast.Expr → Slice ast.Stmt → Slice
    ast.Stmt → Bool → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::lower_assert_ne]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 747:4-766:5 -/
axiom lower.FnLower.lower_assert_ne
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::bound_cell]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 776:4-778:5 -/
axiom lower.FnLower.bound_cell
  :
  lower.FnLower → Std.U64 → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::lower_assert_lt]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 799:4-839:5 -/
axiom lower.FnLower.lower_assert_lt
  :
  lower.FnLower → ast.Expr → ast.LtBound → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::expr]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 841:4-993:5 -/
axiom lower.FnLower.expr
  :
  lower.FnLower → ast.Expr → RustM (Std.U32 × lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::pow_expr]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 997:4-1021:5 -/
axiom lower.FnLower.pow_expr
  :
  lower.FnLower → ast.Expr → ast.Expr → RustM (Std.U32 × lower.FnLower
    × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::expr_into]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 1025:4-1083:5 -/
axiom lower.FnLower.expr_into
  :
  lower.FnLower → ast.Expr → Std.U32 → RustM (lower.FnLower ×
    (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::stmt]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 1085:4-1278:5 -/
axiom lower.FnLower.stmt
  :
  lower.FnLower → ast.Stmt → RustM (lower.FnLower × (lower.FnLower →
    lower.FnLower))

/-- [lean_compiler::lower::{lean_compiler::lower::FnLower<'_0>}::lower_for]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 1294:4-1452:5 -/
axiom lower.FnLower.lower_for
  :
  lower.FnLower → Str → Std.U64 → ast.ForBound → Slice ast.Stmt →
    RustM (lower.FnLower × (lower.FnLower → lower.FnLower))

/-- [lean_compiler::lower::contains_return]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 1455:0-1462:1 -/
axiom lower.contains_return : Slice ast.Stmt → RustM Bool

/-- [lean_compiler::lower::plus_k]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 1467:0-1475:1 -/
axiom lower.plus_k
  : ast.Expr → ast.Expr → RustM (core.option.Option Std.U128)

/-- [lean_compiler::lower::lower_func]:
    Source: 'crates/lean_compiler/src/lower.rs', lines 1478:0-1564:1 -/
axiom lower.lower_func
  :
  ast.Func → alloc.vec.Vec ast.Func → Std.Usize →
    std.collections.hash.map.HashMap Str ast.Func std.hash.random.RandomState
    alloc.alloc.Global → std.collections.hash.map.HashMap Str (Slice
    primitives.field.gf2_64x3.F192) std.hash.random.RandomState
    alloc.alloc.Global → std.collections.hash.map.HashMap alloc.string.String
    (Std.U64 × (core.option.Option Std.U64)) std.hash.random.RandomState
    alloc.alloc.Global → ir.JumpTables → RustM (ir.Lowered ×
    (alloc.vec.Vec ast.Func) × Std.Usize × (std.collections.hash.map.HashMap
    alloc.string.String (Std.U64 × (core.option.Option Std.U64))
    std.hash.random.RandomState alloc.alloc.Global) × ir.JumpTables)

/-- [lean_compiler::parser::consts::eval_const_int]:
    Source: 'crates/lean_compiler/src/parser/consts.rs', lines 26:0-31:1 -/
axiom parser.consts.eval_const_int
  : Str → RustM (core.result.Result Std.U128 alloc.string.String)

/-- [lean_compiler::parser::consts::const_int_expr]:
    Source: 'crates/lean_compiler/src/parser/consts.rs', lines 37:0-63:1 -/
axiom parser.consts.const_int_expr
  : ast.Expr → RustM (core.option.Option Std.U128)

/-- [lean_compiler::parser::consts::parse_const]:
    Source: 'crates/lean_compiler/src/parser/consts.rs', lines 69:0-82:1
    Visibility: public -/
axiom parser.consts.parse_const
  :
  Str → RustM (core.result.Result primitives.field.gf2_64x3.F192
    alloc.string.String)

/-- [lean_compiler::parser::consts::parse_f192_const]:
    Source: 'crates/lean_compiler/src/parser/consts.rs', lines 84:0-98:1 -/
axiom parser.consts.parse_f192_const
  :
  Str → RustM (core.option.Option (core.result.Result
    primitives.field.gf2_64x3.F192 alloc.string.String))

/-- [lean_compiler::parser::consts::gpow_bound]:
    Source: 'crates/lean_compiler/src/parser/consts.rs', lines 105:0-119:1 -/
axiom parser.consts.gpow_bound
  : ast.Expr → RustM (core.result.Result Std.U64 alloc.string.String)

/-- [lean_compiler::parser::expr::parse_expr]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 21:0-173:1 -/
axiom parser.expr.parse_expr
  : Str → RustM (core.result.Result ast.Expr alloc.string.String)

/-- [lean_compiler::parser::consts::apply_replacements]:
    Source: 'crates/lean_compiler/src/parser/consts.rs', lines 130:0-148:1 -/
axiom parser.consts.apply_replacements
  :
  Str → alloc.collections.btree.map.BTreeMap alloc.string.String
    alloc.string.String alloc.alloc.Global → RustM alloc.string.String

/-- [lean_compiler::parser::expr::fold_ops]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 177:0-206:1 -/
axiom parser.expr.fold_ops
  {T0 : Type _} (coreopsfunctionFnT0TupleU8BoxExprBoxExprExprInst :
  core.ops.function.Fn T0 (Std.U8 × ast.Expr × ast.Expr) ast.Expr) :
  Slice Str → Slice Std.U8 → T0 → RustM (core.result.Result ast.Expr
    alloc.string.String)

/-- [lean_compiler::parser::expr::split_add]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 243:0-255:1 -/
axiom parser.expr.split_add
  : Str → RustM ((alloc.vec.Vec Str) × (alloc.vec.Vec Std.U8))

/-- [lean_compiler::parser::expr::split_mul]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 261:0-284:1 -/
axiom parser.expr.split_mul
  : Str → RustM ((alloc.vec.Vec Str) × (alloc.vec.Vec Std.U8))

/-- [lean_compiler::parser::expr::split_once_top]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 287:0-295:1 -/
axiom parser.expr.split_once_top
  : Str → Str → RustM (core.option.Option (Str × Str))

/-- [lean_compiler::parser::expr::split_top]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 298:0-310:1 -/
axiom parser.expr.split_top : Str → Char → RustM (alloc.vec.Vec Str)

/-- [lean_compiler::parser::expr::split_assign]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 317:0-329:1 -/
axiom parser.expr.split_assign
  : Str → RustM (core.option.Option (Str × Str))

/-- [lean_compiler::parser::expr::split_aug]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 340:0-377:1 -/
axiom parser.expr.split_aug
  :
  Str → RustM (core.result.Result (core.option.Option (Str × Str × Str))
    alloc.string.String)

/-- [lean_compiler::parser::expr::call_args]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 382:0-385:1 -/
axiom parser.expr.call_args
  : Str → Str → RustM (core.option.Option (alloc.vec.Vec Str))

/-- [lean_compiler::parser::expr::string_lit]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 388:0-390:1 -/
axiom parser.expr.string_lit : Str → RustM (core.option.Option Str)

/-- [lean_compiler::parser::expr::strip_comment]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 395:0-405:1 -/
axiom parser.expr.strip_comment : Str → RustM Str

/-- [lean_compiler::parser::expr::top_level_cmp]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 410:0-423:1 -/
axiom parser.expr.top_level_cmp : Str → RustM (core.option.Option Str)

/-- [lean_compiler::parser::expr::is_ident]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 427:0-430:1 -/
axiom parser.expr.is_ident : Str → RustM Bool

/-- [lean_compiler::parser::expr::binding_name]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 437:0-446:1 -/
axiom parser.expr.binding_name
  :
  Str → Str → RustM (core.result.Result alloc.string.String
    alloc.string.String)

/-- [lean_compiler::parser::expr::strip_const_wrapper]:
    Source: 'crates/lean_compiler/src/parser/expr.rs', lines 452:0-468:1 -/
axiom parser.expr.strip_const_wrapper : Str → RustM (core.option.Option Str)

/-- [lean_compiler::parser::subst::subst_stmts]:
    Source: 'crates/lean_compiler/src/parser/subst.rs', lines 20:0-33:1 -/
axiom parser.subst.subst_stmts
  : Slice ast.Stmt → Str → ast.Expr → RustM (alloc.vec.Vec ast.Stmt)

/-- [lean_compiler::parser::subst::subst_kind]:
    Source: 'crates/lean_compiler/src/parser/subst.rs', lines 36:0-158:1 -/
axiom parser.subst.subst_kind
  : ast.StmtKind → Str → ast.Expr → RustM (ast.StmtKind × Bool)

/-- [lean_compiler::parser::subst::subst_var]:
    Source: 'crates/lean_compiler/src/parser/subst.rs', lines 162:0-187:1 -/
axiom parser.subst.subst_var : ast.Expr → Str → ast.Expr → RustM ast.Expr

/-- [lean_compiler::parser::parse_with_replacements]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 42:0-231:1
    Visibility: public -/
axiom parser.parse_with_replacements
  :
  Str → alloc.collections.btree.map.BTreeMap alloc.string.String
    alloc.string.String alloc.alloc.Global → RustM (core.result.Result
    ast.Ast alloc.string.String)

/-- [lean_compiler::parser::infer_return_shapes]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 258:0-353:1 -/
axiom parser.infer_return_shapes
  :
  Slice ast.Func → RustM ((core.result.Result Unit alloc.string.String) ×
    (Slice ast.Func))

/-- [lean_compiler::parser::whole_call]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 365:0-390:1 -/
axiom parser.whole_call : Str → RustM Bool

/-- [lean_compiler::parser::locate]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 392:0-398:1 -/
axiom parser.locate
  : Std.Usize → alloc.string.String → RustM alloc.string.String

/-- [lean_compiler::parser::{lean_compiler::parser::Parser<'_0>}::here]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 415:4-420:5 -/
axiom parser.Parser.here : parser.Parser → RustM Std.Usize

/-- [lean_compiler::parser::{lean_compiler::parser::Parser<'_0>}::func_inner]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 427:4-445:5 -/
axiom parser.Parser.func_inner
  :
  parser.Parser → RustM ((core.result.Result ast.Func alloc.string.String) ×
    parser.Parser)

/-- [lean_compiler::parser::{lean_compiler::parser::Parser<'_0>}::func_header]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 447:4-513:5 -/
axiom parser.Parser.func_header
  :
  parser.Parser → Bool → Std.Usize → Str → RustM ((core.result.Result
    ast.Func alloc.string.String) × parser.Parser)

/-- [lean_compiler::parser::{lean_compiler::parser::Parser<'_0>}::stmt_inner]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 541:4-774:5 -/
axiom parser.Parser.stmt_inner
  :
  parser.Parser → Std.Usize → RustM ((core.result.Result ast.StmtKind
    alloc.string.String) × parser.Parser)

/-- [lean_compiler::parser::{lean_compiler::parser::Parser<'_0>}::if_stmt]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 780:4-843:5 -/
axiom parser.Parser.if_stmt
  :
  parser.Parser → Str → Std.Usize → RustM ((core.result.Result
    ast.StmtKind alloc.string.String) × parser.Parser)

/-- [lean_compiler::parser::strip_log]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 850:0-853:1 -/
axiom parser.strip_log : Str → RustM (core.option.Option Str)

/-- [lean_compiler::parser::parse_match]:
    Source: 'crates/lean_compiler/src/parser.rs', lines 861:0-907:1 -/
axiom parser.parse_match
  : Str → Str → RustM (core.result.Result ast.StmtKind alloc.string.String)

