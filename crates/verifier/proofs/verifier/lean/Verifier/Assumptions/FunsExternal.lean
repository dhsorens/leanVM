-- [verifier]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import Verifier.Extraction.Types
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
namespace verifier

/-- [verifier::bus::verify_gkr_grand_products]:
    Source: 'crates/verifier/src/bus.rs', lines 14:0-51:1 -/
axiom bus.verify_gkr_grand_products
  :
  Std.Usize → transcript.Transcript → RustM ((core.result.Result (field.E
    × (alloc.vec.Vec field.E) × (alloc.vec.Vec field.E)) VerifierError) ×
    transcript.Transcript)

/-- [verifier::bus::{verifier::bus::ColumnClaim}::on_stack]:
    Source: 'crates/verifier/src/bus.rs', lines 88:4-91:5
    Visibility: public -/
axiom bus.ColumnClaim.on_stack
  :
  bus.ColumnClaim → layout.Layout → RustM (core.option.Option ((Dyn (fun
    _dyn => core.ops.function.Fn _dyn (Slice field.E) field.E)) × field.E))

/-- [verifier::bus::verify_bus_balance]:
    Source: 'crates/verifier/src/bus.rs', lines 105:0-212:1
    Visibility: public -/
axiom bus.verify_bus_balance
  :
  layout.Layout → transcript.Transcript → RustM ((core.result.Result
    bus.BusResult VerifierError) × transcript.Transcript)

/-- [verifier::bus::table_sumcheck]:
    Source: 'crates/verifier/src/bus.rs', lines 217:0-258:1
    Visibility: public -/
axiom bus.table_sumcheck
  :
  Slice layout.Table → Slice Std.Usize → Slice (alloc.vec.Vec layout.Form)
    → Slice field.E → Slice field.E → Slice field.E → field.E →
    transcript.Transcript → RustM ((core.result.Result (alloc.vec.Vec
    ((alloc.vec.Vec field.E) × (alloc.vec.Vec field.E))) VerifierError) ×
    transcript.Transcript)

/-- [verifier::bytecode::{impl core::fmt::Debug for verifier::bytecode::Bytecode}::fmt]:
    Source: 'crates/verifier/src/bytecode.rs', lines 13:16-13:21
    Visibility: public -/
axiom bytecode.Bytecode.Insts.CoreFmtDebug.fmt
  :
  bytecode.Bytecode → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::bytecode::{impl core::fmt::Debug for verifier::bytecode::Block}::fmt]:
    Source: 'crates/verifier/src/bytecode.rs', lines 26:22-26:27
    Visibility: public -/
axiom bytecode.Block.Insts.CoreFmtDebug.fmt
  :
  bytecode.Block → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::bytecode::{verifier::bytecode::Bytecode}::new]:
    Source: 'crates/verifier/src/bytecode.rs', lines 48:4-91:5
    Visibility: public -/
axiom bytecode.Bytecode.new : Slice Std.U64 → RustM bytecode.Bytecode

/-- [verifier::bytecode::{verifier::bytecode::Bytecode}::evaluate]:
    Source: 'crates/verifier/src/bytecode.rs', lines 106:4-138:5
    Visibility: public -/
axiom bytecode.Bytecode.evaluate
  :
  bytecode.Bytecode → Slice field.E → RustM (core.result.Result field.E
    VerifierError)

/-- [verifier::da::membership_challenges]:
    Source: 'crates/verifier/src/da.rs', lines 16:0-22:1
    Visibility: public -/
axiom da.membership_challenges
  : Array Std.U8 32#usize → RustM (alloc.vec.Vec field.E)

/-- [verifier::da::encode]:
    Source: 'crates/verifier/src/da.rs', lines 48:0-67:1 -/
axiom da.encode : Slice field.E → RustM (Slice field.E)

/-- [verifier::da::dual_codeword]:
    Source: 'crates/verifier/src/da.rs', lines 70:0-82:1
    Visibility: public -/
axiom da.dual_codeword : Slice field.E → RustM (alloc.vec.Vec field.E)

/-- [verifier::da::vector_digest]:
    Source: 'crates/verifier/src/da.rs', lines 91:0-98:1
    Visibility: public -/
axiom da.vector_digest : Slice field.E → RustM (Array Std.U8 32#usize)

/-- [verifier::field::{impl core::fmt::Debug for verifier::field::K}::fmt]:
    Source: 'crates/verifier/src/field.rs', lines 56:22-56:27
    Visibility: public -/
axiom field.K.Insts.CoreFmtDebug.fmt
  :
  field.K → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::field::{impl core::fmt::Debug for verifier::field::E}::fmt]:
    Source: 'crates/verifier/src/field.rs', lines 106:22-106:27
    Visibility: public -/
axiom field.E.Insts.CoreFmtDebug.fmt
  :
  field.E → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::hash::{impl core::fmt::Debug for verifier::hash::Digest}::fmt]:
    Source: 'crates/verifier/src/hash.rs', lines 106:22-106:27
    Visibility: public -/
axiom hash.Digest.Insts.CoreFmtDebug.fmt
  :
  hash.Digest → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::keccak::{impl core::fmt::Debug for verifier::keccak::KeccakShape}::fmt]:
    Source: 'crates/verifier/src/keccak.rs', lines 49:22-49:27
    Visibility: public -/
axiom keccak.KeccakShape.Insts.CoreFmtDebug.fmt
  :
  keccak.KeccakShape → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::keccak::verify_layer]:
    Source: 'crates/verifier/src/keccak.rs', lines 116:0-188:1 -/
axiom keccak.verify_layer
  :
  transcript.Transcript → keccak.KeccakShape → Std.Usize → keccak.Claim
    → RustM ((core.result.Result keccak.Claim VerifierError) ×
    transcript.Transcript)

/-- [verifier::transcript::{verifier::transcript::Transcript<'a>}::next_scalars]:
    Source: 'crates/verifier/src/transcript.rs', lines 149:4-151:5
    Visibility: public -/
axiom transcript.Transcript.next_scalars
  :
  transcript.Transcript → Std.Usize → RustM ((core.result.Result
    (alloc.vec.Vec field.E) VerifierError) × transcript.Transcript)

/-- [verifier::keccak::verify_keccak]:
    Source: 'crates/verifier/src/keccak.rs', lines 233:0-292:1
    Visibility: public -/
axiom keccak.verify_keccak
  :
  transcript.Transcript → keccak.KeccakShape → Slice field.E → Slice
    field.E → RustM ((core.result.Result keccak.KeccakOpenings VerifierError)
    × transcript.Transcript)

/-- [verifier::layout::{impl core::fmt::Debug for verifier::layout::Form}::fmt]:
    Source: 'crates/verifier/src/layout.rs', lines 15:16-15:21
    Visibility: public -/
axiom layout.Form.Insts.CoreFmtDebug.fmt
  :
  layout.Form → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::layout::{impl core::fmt::Debug for verifier::layout::BusBlock}::fmt]:
    Source: 'crates/verifier/src/layout.rs', lines 56:16-56:21
    Visibility: public -/
axiom layout.BusBlock.Insts.CoreFmtDebug.fmt
  :
  layout.BusBlock → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::layout::cols]:
    Source: 'crates/verifier/src/layout.rs', lines 103:0-110:1 -/
axiom layout.cols
  {N : Std.Usize} : Slice Str → Array Str N → RustM (Array Std.Usize N)

/-- [verifier::layout::{impl core::fmt::Debug for verifier::layout::Flushes}::fmt]:
    Source: 'crates/verifier/src/layout.rs', lines 132:16-132:21
    Visibility: public -/
axiom layout.Flushes.Insts.CoreFmtDebug.fmt
  :
  layout.Flushes → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::layout::jump_constraints]:
    Source: 'crates/verifier/src/layout.rs', lines 303:0-306:1 -/
axiom layout.jump_constraints : Slice field.E → RustM (alloc.vec.Vec field.E)

/-- [verifier::layout::flushes_arith]:
    Source: 'crates/verifier/src/layout.rs', lines 218:0-243:1 -/
axiom layout.flushes_arith : Std.Usize → Bool → RustM layout.Flushes

/-- [verifier::layout::flushes_set]:
    Source: 'crates/verifier/src/layout.rs', lines 245:0-254:1 -/
axiom layout.flushes_set : RustM layout.Flushes

/-- [verifier::layout::flushes_deref]:
    Source: 'crates/verifier/src/layout.rs', lines 256:0-279:1 -/
axiom layout.flushes_deref : RustM layout.Flushes

/-- [verifier::layout::flushes_jump]:
    Source: 'crates/verifier/src/layout.rs', lines 281:0-301:1 -/
axiom layout.flushes_jump : RustM layout.Flushes

/-- [verifier::layout::flushes_keccak]:
    Source: 'crates/verifier/src/layout.rs', lines 338:0-376:1 -/
axiom layout.flushes_keccak : RustM layout.Flushes

/-- [verifier::layout::KECCAK_IN]
    Source: 'crates/verifier/src/layout.rs', lines 399:0-399:47
    Visibility: public -/
axiom layout.KECCAK_IN : RustM Std.Usize

/-- [verifier::layout::TABLE_WIDTHS]
    Source: 'crates/verifier/src/layout.rs', lines 475:0-482:2 -/
axiom layout.TABLE_WIDTHS : RustM (Array Std.Usize 6#usize)

/-- [verifier::layout::keccak_columns]:
    Source: 'crates/verifier/src/layout.rs', lines 439:0-448:1 -/
axiom layout.keccak_columns : RustM (alloc.vec.Vec alloc.string.String)

/-- [verifier::layout::tables]:
    Source: 'crates/verifier/src/layout.rs', lines 450:0-473:1
    Visibility: public -/
axiom layout.tables : RustM (alloc.vec.Vec layout.Table)

/-- [verifier::layout::build_layout]:
    Source: 'crates/verifier/src/layout.rs', lines 496:0-597:1
    Visibility: public -/
axiom layout.build_layout
  :
  bytecode.Bytecode → Std.U64 → Slice Std.U64 → RustM (core.result.Result
    layout.Layout VerifierError)

/-- [verifier::{impl core::fmt::Debug for verifier::VerifierError}::fmt]:
    Source: 'crates/verifier/src/lib.rs', lines 45:22-45:27
    Visibility: public -/
axiom VerifierError.Insts.CoreFmtDebug.fmt
  :
  VerifierError → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::{impl core::fmt::Display for verifier::VerifierError}::fmt]:
    Source: 'crates/verifier/src/lib.rs', lines 79:4-111:5
    Visibility: public -/
axiom VerifierError.Insts.CoreFmtDisplay.fmt
  :
  VerifierError → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::{impl core::fmt::Debug for verifier::Summary}::fmt]:
    Source: 'crates/verifier/src/lib.rs', lines 154:16-154:21
    Visibility: public -/
axiom Summary.Insts.CoreFmtDebug.fmt
  :
  Summary → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::walk]:
    Source: 'crates/verifier/src/lib.rs', lines 229:0-344:1 -/
axiom walk
  :
  bytecode.Bytecode → Array Std.U8 32#usize → transcript.Proof → Bool →
    RustM (core.result.Result Summary VerifierError)

/-- [verifier::verify_keccak_batch]:
    Source: 'crates/verifier/src/lib.rs', lines 186:0-227:1
    Visibility: public -/
axiom verify_keccak_batch
  :
  Array Std.U8 32#usize → Std.Usize → Std.Usize → Std.Usize →
    transcript.Proof → RustM (core.result.Result Unit VerifierError)

/-- [verifier::merkle::{impl core::fmt::Debug for verifier::merkle::MerkleOpenings}::fmt]:
    Source: 'crates/verifier/src/merkle.rs', lines 8:16-8:21
    Visibility: public -/
axiom merkle.MerkleOpenings.Insts.CoreFmtDebug.fmt
  :
  merkle.MerkleOpenings → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::merkle::{impl core::fmt::Debug for verifier::merkle::PrunedMerklePaths}::fmt]:
    Source: 'crates/verifier/src/merkle.rs', lines 31:16-31:21
    Visibility: public -/
axiom merkle.PrunedMerklePaths.Insts.CoreFmtDebug.fmt
  :
  merkle.PrunedMerklePaths → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::merkle::{impl core::fmt::Debug for verifier::merkle::MerklePath}::fmt]:
    Source: 'crates/verifier/src/merkle.rs', lines 53:16-53:21
    Visibility: public -/
axiom merkle.MerklePath.Insts.CoreFmtDebug.fmt
  :
  merkle.MerklePath → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::merkle::{verifier::merkle::PrunedMerklePaths}::expand]:
    Source: 'crates/verifier/src/merkle.rs', lines 81:4-148:5 -/
axiom merkle.PrunedMerklePaths.expand
  :
  merkle.PrunedMerklePaths → Std.Usize → Slice Std.U64 → Std.Usize →
    Std.Usize → RustM (core.result.Result (hash.Digest × (alloc.vec.Vec
    merkle.MerklePath)) VerifierError)

/-- [verifier::multilinear::{impl core::fmt::Debug for verifier::multilinear::Placement}::fmt]:
    Source: 'crates/verifier/src/multilinear.rs', lines 120:22-120:27
    Visibility: public -/
axiom multilinear.Placement.Insts.CoreFmtDebug.fmt
  :
  multilinear.Placement → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::transcript::{verifier::transcript::Transcript<'a>}::samples]:
    Source: 'crates/verifier/src/transcript.rs', lines 129:4-131:5
    Visibility: public -/
axiom transcript.Transcript.samples
  :
  transcript.Transcript → Std.Usize → RustM ((alloc.vec.Vec field.E) ×
    transcript.Transcript)

/-- [verifier::transcript::{impl core::fmt::Debug for verifier::transcript::Proof}::fmt]:
    Source: 'crates/verifier/src/transcript.rs', lines 10:16-10:21
    Visibility: public -/
axiom transcript.Proof.Insts.CoreFmtDebug.fmt
  :
  transcript.Proof → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::transcript::{impl core::fmt::Debug for verifier::transcript::Sponge}::fmt]:
    Source: 'crates/verifier/src/transcript.rs', lines 37:16-37:21
    Visibility: public -/
axiom transcript.Sponge.Insts.CoreFmtDebug.fmt
  :
  transcript.Sponge → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [verifier::transcript::{verifier::transcript::Transcript<'a>}::merkle]:
    Source: 'crates/verifier/src/transcript.rs', lines 183:4-230:5
    Visibility: public -/
axiom transcript.Transcript.merkle
  :
  transcript.Transcript → hash.Digest → Std.U64 → Slice Std.U64 →
    Std.Usize → Std.Usize → RustM ((core.result.Result (alloc.vec.Vec
    (alloc.vec.Vec field.K)) VerifierError) × transcript.Transcript)

/-- [verifier::whir::derive_config]:
    Source: 'crates/verifier/src/whir.rs', lines 32:0-58:1 -/
axiom whir.derive_config
  :
  Std.Usize → Std.Usize → RustM (core.result.Result whir.WhirConfig
    VerifierError)

end verifier
