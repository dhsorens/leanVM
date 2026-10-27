-- [lean_da]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import LeanDa.Extraction.Types
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

/-- [lean_da::commit::{impl core::fmt::Debug for lean_da::commit::DaCommitment}::fmt]:
    Source: 'crates/lean_da/src/commit.rs', lines 15:22-15:27
    Visibility: public -/
axiom commit.DaCommitment.Insts.CoreFmtDebug.fmt
  :
  commit.DaCommitment → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_da::encode::encode_rows]:
    Source: 'crates/lean_da/src/encode.rs', lines 18:0-35:1
    Visibility: public -/
axiom encode.encode_rows : Slice Std.U64 → RustM (alloc.vec.Vec Std.U64)

/-- [lean_da::commit::as_bytes]:
    Source: 'crates/lean_da/src/commit.rs', lines 147:0-151:1 -/
axiom commit.as_bytes : Slice Std.U64 → RustM (Slice Std.U8)

/-- [lean_da::membership::dual_codeword]:
    Source: 'crates/lean_da/src/membership.rs', lines 67:0-85:1
    Visibility: public -/
axiom membership.dual_codeword
  :
  Slice primitives.field.gf2_64x3.F192 → RustM (alloc.vec.Vec
    primitives.field.gf2_64x3.F192)

end lean_da
