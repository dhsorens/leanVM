-- [fiat_shamir]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import FiatShamir.Extraction.Types
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
open fiat_shamir

/-- [fiat_shamir::{fiat_shamir::FiatShamirState}::grind_pow]:
    Source: 'crates/fiat_shamir/src/lib.rs', lines 160:4-199:5
    Visibility: public -/
axiom FiatShamirState.grind_pow
  : FiatShamirState → Std.U32 → RustM (Std.U64 × FiatShamirState)

/-- [fiat_shamir::merkle::{impl core::fmt::Debug for fiat_shamir::merkle::PrunedMerklePaths}::fmt]:
    Source: 'crates/fiat_shamir/src/merkle.rs', lines 88:16-88:21
    Visibility: public -/
axiom merkle.PrunedMerklePaths.Insts.CoreFmtDebug.fmt
  :
  merkle.PrunedMerklePaths → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [fiat_shamir::transcript::{impl core::fmt::Debug for fiat_shamir::transcript::Proof}::fmt]:
    Source: 'crates/fiat_shamir/src/transcript.rs', lines 8:16-8:21
    Visibility: public -/
axiom transcript.Proof.Insts.CoreFmtDebug.fmt
  :
  transcript.Proof → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

