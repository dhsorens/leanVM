-- [claims]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import Claims.Extraction.Types
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

namespace claims

/-- [claims::{impl core::clone::Clone for claims::AggregateClaims}::clone]:
    Source: 'crates/claims/src/lib.rs', lines 19:9-19:14
    Visibility: public -/
axiom AggregateClaims.Insts.CoreCloneClone.clone
  : AggregateClaims → RustM AggregateClaims

/-- [claims::{impl core::fmt::Debug for claims::AggregateClaims}::fmt]:
    Source: 'crates/claims/src/lib.rs', lines 19:16-19:21
    Visibility: public -/
axiom AggregateClaims.Insts.CoreFmtDebug.fmt
  :
  AggregateClaims → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [claims::{impl core::fmt::Debug for claims::OutputClaims<'a>}::fmt]:
    Source: 'crates/claims/src/lib.rs', lines 28:22-28:27
    Visibility: public -/
axiom OutputClaims.Insts.CoreFmtDebug.fmt
  :
  OutputClaims → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [claims::encode_claims]:
    Source: 'crates/claims/src/lib.rs', lines 43:0-49:1 -/
axiom encode_claims
  {K : Type _} {T1 : Type _} (coreopsfunctionFnT1TupleShared0KArrayU832Inst :
  core.ops.function.Fn T1 K (Array Std.U8 32#usize)) :
  alloc.vec.Vec Std.U8 → Slice (K × (Array Std.U8 32#usize)) → T1 →
    RustM (alloc.vec.Vec Std.U8)

/-- [claims::decode_claims]:
    Source: 'crates/claims/src/lib.rs', lines 52:0-59:1 -/
axiom decode_claims
  {K : Type _} {T1 : Type _} (coreopsfunctionFnT1TupleShared0ArrayU832KInst :
  core.ops.function.Fn T1 (Array Std.U8 32#usize) K) :
  Slice Std.U8 → T1 → RustM ((core.option.Option (alloc.vec.Vec (K ×
    (Array Std.U8 32#usize)))) × (Slice Std.U8))

/-- [claims::{claims::AggregateClaims}::to_bytes]:
    Source: 'crates/claims/src/lib.rs', lines 69:4-81:5
    Visibility: public -/
axiom AggregateClaims.to_bytes
  : AggregateClaims → RustM (alloc.vec.Vec Std.U8)

/-- [claims::{claims::AggregateClaims}::from_bytes]:
    Source: 'crates/claims/src/lib.rs', lines 84:4-97:5
    Visibility: public -/
axiom AggregateClaims.from_bytes
  : Slice Std.U8 → RustM (core.option.Option AggregateClaims)

end claims
