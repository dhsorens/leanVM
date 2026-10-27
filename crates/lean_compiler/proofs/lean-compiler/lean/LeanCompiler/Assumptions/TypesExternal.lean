-- [lean_compiler]: external types.
-- Seeded by hax from Extraction/TypesExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import LeanvmCore.Extraction
public import Primitives.Extraction
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


namespace lean_compiler

/-- [lean_compiler::ast::Expr]
    Source: 'crates/lean_compiler/src/ast.rs', lines 7:0-83:1
    Visibility: public -/
axiom ast.Expr : Type

/-- [lean_compiler::ast::Stmt]
    Source: 'crates/lean_compiler/src/ast.rs', lines 90:0-93:1
    Visibility: public -/
axiom ast.Stmt : Type

/-- [lean_compiler::ast::StmtKind]
    Source: 'crates/lean_compiler/src/ast.rs', lines 109:0-195:1
    Visibility: public -/
axiom ast.StmtKind : Type

end lean_compiler
