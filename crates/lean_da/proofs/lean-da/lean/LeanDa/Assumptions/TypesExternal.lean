-- [lean_da]: external types.
-- Seeded by hax from Extraction/TypesExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
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

-- Items of other workspace crates the extraction uses, which hax does not declare: written
-- here by hand, above the generated declarations (wire.py keeps this header as it is).

-- `primitives::field::gf2_64x3::F192`: `c0 + c1 y + c2 y^2`, its three 64-bit coefficients.
structure primitives.field.gf2_64x3.F192 where
  c0 : Std.U64
  c1 : Std.U64
  c2 : Std.U64

-- `fiat_shamir::FiatShamirState`: the duplex sponge over Keccak-f, assumed.
axiom fiat_shamir.FiatShamirState : Type

