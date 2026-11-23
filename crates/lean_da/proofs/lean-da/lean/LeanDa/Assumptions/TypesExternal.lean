-- [lean_da]: external types.
-- Seeded by hax from Extraction/TypesExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import Keccak256.Extraction
public import Pcs.Extraction
public import Primitives.Extraction
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

namespace lean_da

/-- [lean_da::commit::{lean_da::commit::BlobMatrix}::column::{closure}::{closure}]
    Source: 'crates/lean_da/src/commit.rs', lines 63:73-63:117 -/
axiom commit.BlobMatrix.column.closure.closure : Type

end lean_da
