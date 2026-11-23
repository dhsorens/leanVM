-- [zkdsl_compiler]: external types.
-- Seeded by hax from Extraction/TypesExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import Isa.Extraction
public import Keccak256.Extraction
public import Verifier.Extraction
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

/-- [zkdsl_compiler::ast::Expr]
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 8:0-84:1
    Visibility: public -/
axiom ast.Expr : Type

/-- [zkdsl_compiler::ast::Stmt]
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 91:0-94:1
    Visibility: public -/
axiom ast.Stmt : Type

/-- [zkdsl_compiler::ast::StmtKind]
    Source: 'crates/zkdsl_compiler/src/ast.rs', lines 110:0-196:1
    Visibility: public -/
axiom ast.StmtKind : Type

/-- [zkdsl_compiler::parser::expr::depth0::{closure}]
    Source: 'crates/zkdsl_compiler/src/parser/expr.rs', lines 230:47-253:5 -/
axiom parser.expr.depth0.closure : Type

end zkdsl_compiler
