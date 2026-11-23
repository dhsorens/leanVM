-- [lean_sphincs]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import LeanSphincs.Extraction.Types
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

namespace lean_sphincs

/-- [lean_sphincs::fors::{impl core::fmt::Debug for lean_sphincs::fors::ForsTreeOpening}::fmt]:
    Source: 'crates/lean_sphincs/src/fors.rs', lines 13:22-13:27
    Visibility: public -/
axiom fors.ForsTreeOpening.Insts.CoreFmtDebug.fmt
  :
  fors.ForsTreeOpening → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_sphincs::wots::{lean_sphincs::wots::OtsKey}::of_index]:
    Source: 'crates/lean_sphincs/src/wots.rs', lines 26:4-34:5
    Visibility: public -/
axiom wots.OtsKey.of_index : Std.Usize → Std.U64 → RustM wots.OtsKey

/-- [lean_sphincs::scheme::merkle_levels]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 180:0-192:1 -/
axiom scheme.merkle_levels
  {T0 : Type _}
  (coreopsfunctionFnT0TupleUsizeUsizeSharedArrayArrayU8162ArrayU816Inst :
  core.ops.function.Fn T0 (Std.Usize × Std.Usize × (Array (Array Std.U8
  16#usize) 2#usize)) (Array Std.U8 16#usize)) :
  alloc.vec.Vec (Array Std.U8 16#usize) → Std.Usize → T0 → RustM
    (alloc.vec.Vec (alloc.vec.Vec (Array Std.U8 16#usize)))

/-- [lean_sphincs::fors::fors_recover]:
    Source: 'crates/lean_sphincs/src/fors.rs', lines 91:0-106:1
    Visibility: public -/
axiom fors.fors_recover
  {T0 : Type _} (coreopsfunctionFnMutT0TupleShared0ArrayArrayU8162TupleInst :
  core.ops.function.FnMut T0 (Array (Array Std.U8 16#usize) 2#usize) Unit) :
  Array Std.U8 16#usize → Std.U64 → Array Std.Usize 24#usize → Array
    fors.ForsTreeOpening 24#usize → T0 → RustM (Array Std.U8 16#usize)

/-- [lean_sphincs::hash::{impl core::fmt::Debug for lean_sphincs::hash::Adrs}::fmt]:
    Source: 'crates/lean_sphincs/src/hash.rs', lines 32:22-32:27
    Visibility: public -/
axiom hash.Adrs.Insts.CoreFmtDebug.fmt
  :
  hash.Adrs → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_sphincs::hash::h_msg]:
    Source: 'crates/lean_sphincs/src/hash.rs', lines 132:0-140:1
    Visibility: public -/
axiom hash.h_msg
  :
  Array Std.U8 16#usize → Array Std.U8 16#usize → Array Std.U8 16#usize →
    Array Std.U8 32#usize → RustM (Array Std.U8 64#usize)

/-- [lean_sphincs::scheme::path_range]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 91:0-94:1 -/
axiom scheme.path_range : Std.Usize → RustM (core.ops.range.Range Std.Usize)

/-- [lean_sphincs::scheme::{impl core::fmt::Debug for lean_sphincs::scheme::LeanSphincsPublicKey}::fmt]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 13:22-13:27
    Visibility: public -/
axiom scheme.LeanSphincsPublicKey.Insts.CoreFmtDebug.fmt
  :
  scheme.LeanSphincsPublicKey → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_sphincs::scheme::{lean_sphincs::scheme::LeanSphincsPublicKey}::to_bytes]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 21:4-26:5
    Visibility: public -/
axiom scheme.LeanSphincsPublicKey.to_bytes
  : scheme.LeanSphincsPublicKey → RustM (Array Std.U8 32#usize)

/-- [lean_sphincs::scheme::{lean_sphincs::scheme::LeanSphincsPublicKey}::from_bytes]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 28:4-33:5
    Visibility: public -/
axiom scheme.LeanSphincsPublicKey.from_bytes
  : Array Std.U8 32#usize → RustM scheme.LeanSphincsPublicKey

/-- [lean_sphincs::scheme::{impl core::fmt::Debug for lean_sphincs::scheme::LayerSignature}::fmt]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 63:22-63:27
    Visibility: public -/
axiom scheme.LayerSignature.Insts.CoreFmtDebug.fmt
  :
  scheme.LayerSignature → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_sphincs::scheme::{impl core::fmt::Debug for lean_sphincs::scheme::LeanSphincsSignature}::fmt]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 80:16-80:21
    Visibility: public -/
axiom scheme.LeanSphincsSignature.Insts.CoreFmtDebug.fmt
  :
  scheme.LeanSphincsSignature → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_sphincs::scheme::{lean_sphincs::scheme::LeanSphincsSignature}::to_bytes]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 105:4-124:5
    Visibility: public -/
axiom scheme.LeanSphincsSignature.to_bytes
  : scheme.LeanSphincsSignature → RustM (Array Std.U8 7740#usize)

/-- [lean_sphincs::scheme::{lean_sphincs::scheme::LeanSphincsSignature}::from_bytes]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 126:4-155:5
    Visibility: public -/
axiom scheme.LeanSphincsSignature.from_bytes
  : Array Std.U8 7740#usize → RustM scheme.LeanSphincsSignature

/-- [lean_sphincs::scheme::sign]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 242:0-273:1
    Visibility: public -/
axiom scheme.sign
  :
  Array Std.U8 32#usize → Array Std.U8 32#usize → RustM
    scheme.LeanSphincsSignature

/-- [lean_sphincs::scheme::verify]:
    Source: 'crates/lean_sphincs/src/scheme.rs', lines 290:0-302:1
    Visibility: public -/
axiom scheme.verify
  :
  scheme.LeanSphincsPublicKey → Array Std.U8 32#usize →
    scheme.LeanSphincsSignature → RustM Bool

/-- [lean_sphincs::wots::{impl core::fmt::Debug for lean_sphincs::wots::OtsKey}::fmt]:
    Source: 'crates/lean_sphincs/src/wots.rs', lines 16:22-16:27
    Visibility: public -/
axiom wots.OtsKey.Insts.CoreFmtDebug.fmt
  :
  wots.OtsKey → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_sphincs::wots::codeword]:
    Source: 'crates/lean_sphincs/src/wots.rs', lines 85:0-89:1 -/
axiom wots.codeword
  :
  Array Std.U8 16#usize → RustM (core.option.Option (Array Std.U8 64#usize))

end lean_sphincs
