-- [stable_keccak_gkr]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import KeccakGkr.Extraction.Types
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

namespace stable_keccak_gkr

/-- [stable_keccak_gkr::kernels::embed_run]:
    Source: 'crates/stable_prover/keccak_gkr/src/kernels.rs', lines 36:0-44:1
    Visibility: public -/
axiom kernels.embed_run
  :
  Slice Std.U64 → Std.Usize → RustM (Array (Array Std.U64 8#usize)
    32#usize)

/-- [stable_keccak_gkr::kernels::field_map]:
    Source: 'crates/stable_prover/keccak_gkr/src/kernels.rs', lines 50:0-53:1
    Visibility: public -/
axiom kernels.field_map
  :
  Array stable_primitives.field.gf2_64x2.F128 8#usize → RustM (Array
    stable_primitives.field.lanes.portable.ByteMap 16#usize)

/-- [stable_keccak_gkr::kernels::map_sums]:
    Source: 'crates/stable_prover/keccak_gkr/src/kernels.rs', lines 56:0-69:1
    Visibility: public -/
axiom kernels.map_sums
  {T0 : Type _} (coreopsfunctionFnT0TupleUsizeArrayU648Inst :
  core.ops.function.Fn T0 Std.Usize (Array Std.U64 8#usize)) :
  Slice (Array stable_primitives.field.lanes.portable.ByteMap 16#usize) → T0
    → RustM (Array Std.U128 64#usize)

/-- [stable_keccak_gkr::layer::prove_layer]:
    Source: 'crates/stable_prover/keccak_gkr/src/layer.rs', lines 23:0-68:1 -/
axiom layer.prove_layer
  :
  fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    witness.Witness → Std.Usize → protocol.Claim → table.Tables → RustM
    (protocol.Claim × (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool) ×
    table.Tables)

/-- [stable_keccak_gkr::layer::{stable_keccak_gkr::layer::Layer<'a>}::task_weights]:
    Source: 'crates/stable_prover/keccak_gkr/src/layer.rs', lines 115:4-124:5
    Visibility: public -/
axiom layer.Layer.task_weights
  :
  layer.Layer → Slice stable_primitives.field.gf2_64x2.F128 → RustM
    (alloc.vec.Vec stable_primitives.field.gf2_64x2.F128)

/-- [stable_keccak_gkr::layer::{stable_keccak_gkr::layer::Sumcheck}::round]:
    Source: 'crates/stable_prover/keccak_gkr/src/layer.rs', lines 138:4-150:5
    Visibility: public -/
axiom layer.Sumcheck.round
  :
  layer.Sumcheck → fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    stable_primitives.field.gf2_64x2.F128 → core.option.Option
    stable_primitives.field.gf2_64x2.F128 →
    stable_primitives.field.gf2_64x2.F128 →
    stable_primitives.field.gf2_64x2.F128 → RustM
    (stable_primitives.field.gf2_64x2.F128 × layer.Sumcheck ×
    (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool))

/-- [stable_keccak_gkr::layer::prove_positions]:
    Source: 'crates/stable_prover/keccak_gkr/src/layer.rs', lines 156:0-175:1 -/
axiom layer.prove_positions
  :
  fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    Slice stable_primitives.field.gf2_64x2.F128 → alloc.vec.Vec
    stable_primitives.field.gf2_64x2.F128 →
    stable_primitives.field.gf2_64x2.F128 → RustM (((alloc.vec.Vec
    stable_primitives.field.gf2_64x2.F128) × (Array
    stable_primitives.field.gf2_64x2.F128 3#usize)) ×
    (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool))

/-- [stable_keccak_gkr::{impl core::fmt::Debug for stable_keccak_gkr::OutputClaim}::fmt]:
    Source: 'crates/stable_prover/keccak_gkr/src/lib.rs', lines 55:16-55:21
    Visibility: public -/
axiom OutputClaim.Insts.CoreFmtDebug.fmt
  :
  OutputClaim → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [stable_keccak_gkr::{stable_keccak_gkr::witness::Witness}::prove]:
    Source: 'crates/stable_prover/keccak_gkr/src/lib.rs', lines 66:4-97:5
    Visibility: public -/
axiom Witness.prove
  :
  witness.Witness → fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    Slice stable_primitives.field.gf2_64.F64 → OutputClaim → RustM
    (open.Openings × (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool))

/-- [stable_keccak_gkr::open::{impl core::fmt::Debug for stable_keccak_gkr::open::Openings}::fmt]:
    Source: 'crates/stable_prover/keccak_gkr/src/open.rs', lines 25:16-25:21
    Visibility: public -/
axiom open.Openings.Insts.CoreFmtDebug.fmt
  :
  open.Openings → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [stable_keccak_gkr::open::slices]:
    Source: 'crates/stable_prover/keccak_gkr/src/open.rs', lines 67:0-91:1 -/
axiom open.slices
  :
  witness.Shape → Slice stable_primitives.field.gf2_64.F64 → Slice
    stable_primitives.field.gf2_64x2.F128 → RustM (alloc.vec.Vec
    stable_primitives.field.gf2_64x2.F128)

/-- [stable_keccak_gkr::open::open_outputs]:
    Source: 'crates/stable_prover/keccak_gkr/src/open.rs', lines 117:0-127:1
    Visibility: public -/
axiom open.open_outputs
  :
  fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    witness.Shape → Slice stable_primitives.field.gf2_64x2.F128 →
    protocol.Claim → alloc.vec.Vec stable_primitives.field.gf2_64x2.F128 →
    RustM ((alloc.vec.Vec stable_primitives.field.gf2_64x2.F128) ×
    (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool))

/-- [stable_keccak_gkr::open::open_inputs]:
    Source: 'crates/stable_prover/keccak_gkr/src/open.rs', lines 130:0-156:1
    Visibility: public -/
axiom open.open_inputs
  :
  fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    witness.Shape → Slice stable_primitives.field.gf2_64.F64 →
    protocol.Claim → RustM ((alloc.vec.Vec
    stable_primitives.field.gf2_64x2.F128) ×
    (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool))

/-- [stable_keccak_gkr::product::polynomial]:
    Source: 'crates/stable_prover/keccak_gkr/src/product.rs', lines 33:0-65:1 -/
axiom product.polynomial
  :
  layer.Layer → protocol.Claim → RustM ((Array
    stable_primitives.field.gf2_64x2.F128 47#usize) × (alloc.vec.Vec (Array
    stable_primitives.field.gf2_64x2.F128 47#usize)))

/-- [stable_keccak_gkr::product::block_sums]:
    Source: 'crates/stable_prover/keccak_gkr/src/product.rs', lines 69:0-89:1 -/
axiom product.block_sums
  :
  Slice (Array stable_primitives.field.lanes.portable.ByteMap 16#usize) →
    Slice Std.U64 → Slice (Array Std.U64 192#usize) → Array Std.U128
    1536#usize → RustM ((Slice (Array Std.U64 192#usize)) × (Array Std.U128
    1536#usize))

/-- [stable_keccak_gkr::protocol::{impl core::fmt::Debug for stable_keccak_gkr::protocol::Claim}::fmt]:
    Source: 'crates/stable_prover/keccak_gkr/src/protocol.rs', lines 13:16-13:21
    Visibility: public -/
axiom protocol.Claim.Insts.CoreFmtDebug.fmt
  :
  protocol.Claim → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [stable_keccak_gkr::protocol::first_claim]:
    Source: 'crates/stable_prover/keccak_gkr/src/protocol.rs', lines 25:0-32:1
    Visibility: public -/
axiom protocol.first_claim
  :
  Slice stable_primitives.field.gf2_64x2.F128 → Slice
    stable_primitives.field.gf2_64x2.F128 → Slice
    stable_primitives.field.gf2_64x2.F128 → RustM protocol.Claim

/-- [stable_keccak_gkr::protocol::instance_weights]:
    Source: 'crates/stable_prover/keccak_gkr/src/protocol.rs', lines 35:0-43:1
    Visibility: public -/
axiom protocol.instance_weights
  :
  stable_primitives.field.gf2_64x2.F128 → RustM (Array
    stable_primitives.field.gf2_64x2.F128 16#usize)

/-- [stable_keccak_gkr::skip::sums]:
    Source: 'crates/stable_prover/keccak_gkr/src/skip.rs', lines 68:0-103:1 -/
axiom skip.sums
  :
  layer.Layer → protocol.Claim → stable_primitives.field.gf2_64x2.F128 →
    Slice (Array stable_primitives.field.gf2_64x2.F128 47#usize) → RustM
    (alloc.vec.Vec stable_primitives.field.gf2_64x2.F128)

/-- [stable_keccak_gkr::skip::block_sums]:
    Source: 'crates/stable_prover/keccak_gkr/src/skip.rs', lines 109:0-130:1 -/
axiom skip.block_sums
  :
  Slice Std.U64 → Array (alloc.vec.Vec Std.U64) 2#usize → Slice (Array
    (Array Std.U64 8#usize) 130#usize) → Slice (Array
    stable_primitives.field.lanes.portable.Wide8 2#usize) → RustM ((Slice
    (Array (Array Std.U64 8#usize) 130#usize)) × (Slice (Array
    stable_primitives.field.lanes.portable.Wide8 2#usize)))

/-- [stable_keccak_gkr::skip::extend]:
    Source: 'crates/stable_prover/keccak_gkr/src/skip.rs', lines 134:0-148:1 -/
axiom skip.extend
  :
  Array (Array Std.U64 8#usize) 32#usize → Array (Array Std.U64 8#usize)
    130#usize → RustM (Array (Array Std.U64 8#usize) 130#usize)

/-- [stable_keccak_gkr::skip::prove_rounds]:
    Source: 'crates/stable_prover/keccak_gkr/src/skip.rs', lines 151:0-171:1 -/
axiom skip.prove_rounds
  :
  fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    protocol.Claim → alloc.vec.Vec stable_primitives.field.gf2_64x2.F128 →
    layer.Sumcheck → RustM ((fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool) ×
    layer.Sumcheck)

/-- [stable_keccak_gkr::skip::{stable_keccak_gkr::skip::AtS}::new]:
    Source: 'crates/stable_prover/keccak_gkr/src/skip.rs', lines 185:4-207:5 -/
axiom skip.AtS.new : stable_primitives.field.gf2_64x2.F128 → RustM skip.AtS

/-- [stable_keccak_gkr::skip::{stable_keccak_gkr::skip::AtS}::eval]:
    Source: 'crates/stable_prover/keccak_gkr/src/skip.rs', lines 215:4-218:5 -/
axiom skip.AtS.eval
  :
  skip.AtS → Array Std.U128 2#usize → RustM
    stable_primitives.field.gf2_64x2.F128

/-- [stable_keccak_gkr::table::{stable_keccak_gkr::table::Tables}::new]:
    Source: 'crates/stable_prover/keccak_gkr/src/table.rs', lines 25:4-28:5
    Visibility: public -/
axiom table.Tables.new : witness.Shape → RustM table.Tables

/-- [stable_keccak_gkr::table::{stable_keccak_gkr::table::Summand}::new]:
    Source: 'crates/stable_prover/keccak_gkr/src/table.rs', lines 41:4-47:5
    Visibility: public -/
axiom table.Summand.new
  :
  protocol.Claim → stable_primitives.field.gf2_64x2.F128 → RustM
    table.Summand

/-- [stable_keccak_gkr::table::{stable_keccak_gkr::table::PackFold}::new]:
    Source: 'crates/stable_prover/keccak_gkr/src/table.rs', lines 73:4-78:5 -/
axiom table.PackFold.new
  :
  Array stable_primitives.field.gf2_64x2.F128 16#usize → Slice
    stable_primitives.field.gf2_64x2.F128 → RustM table.PackFold

/-- [stable_keccak_gkr::table::{stable_keccak_gkr::table::PackFold}::rows]:
    Source: 'crates/stable_prover/keccak_gkr/src/table.rs', lines 81:4-100:5 -/
axiom table.PackFold.rows
  :
  table.PackFold → Slice Std.U64 → Slice
    stable_primitives.field.gf2_64x2.F128 → RustM (Slice
    stable_primitives.field.gf2_64x2.F128)

/-- [stable_keccak_gkr::table::fill]:
    Source: 'crates/stable_prover/keccak_gkr/src/table.rs', lines 106:0-152:1 -/
axiom table.fill
  :
  layer.Layer → protocol.Claim → table.Summand → Array
    stable_primitives.field.gf2_64x2.F128 16#usize → Slice
    stable_primitives.field.gf2_64x2.F128 → table.Tables → RustM
    ((stable_primitives.field.gf2_64x2.F128 ×
    stable_primitives.field.gf2_64x2.F128) × table.Tables)

/-- [stable_keccak_gkr::table::prove_rounds]:
    Source: 'crates/stable_prover/keccak_gkr/src/table.rs', lines 156:0-174:1 -/
axiom table.prove_rounds
  :
  fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    protocol.Claim → table.Summand → (stable_primitives.field.gf2_64x2.F128
    × stable_primitives.field.gf2_64x2.F128) → table.Tables →
    layer.Sumcheck → RustM ((alloc.vec.Vec
    stable_primitives.field.gf2_64x2.F128) ×
    (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool) ×
    table.Tables × layer.Sumcheck)

/-- [stable_keccak_gkr::table::fold_rows]:
    Source: 'crates/stable_prover/keccak_gkr/src/table.rs', lines 179:0-209:1 -/
axiom table.fold_rows
  :
  table.Summand → Slice stable_primitives.field.gf2_64x2.F128 → Slice
    stable_primitives.field.gf2_64x2.F128 →
    stable_primitives.field.gf2_64x2.F128 → Slice
    stable_primitives.field.gf2_64x2.F128 → RustM
    ((stable_primitives.field.gf2_64x2.F128 ×
    stable_primitives.field.gf2_64x2.F128) × (Slice
    stable_primitives.field.gf2_64x2.F128))

/-- [stable_keccak_gkr::witness::{impl core::fmt::Debug for stable_keccak_gkr::witness::Shape}::fmt]:
    Source: 'crates/stable_prover/keccak_gkr/src/witness.rs', lines 21:22-21:27
    Visibility: public -/
axiom witness.Shape.Insts.CoreFmtDebug.fmt
  :
  witness.Shape → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [stable_keccak_gkr::witness::transpose64]:
    Source: 'crates/stable_prover/keccak_gkr/src/witness.rs', lines 94:0-116:1 -/
axiom witness.transpose64
  : Array Std.U64 64#usize → RustM (Array Std.U64 64#usize)

/-- [stable_keccak_gkr::witness::run_block]:
    Source: 'crates/stable_prover/keccak_gkr/src/witness.rs', lines 126:0-183:1 -/
axiom witness.run_block
  :
  Std.Usize → Slice (Array Std.U64 25#usize) → Bool → RustM
    ((alloc.vec.Vec Std.U64) × (alloc.vec.Vec Std.U64))

/-- [stable_keccak_gkr::witness::commit_states]:
    Source: 'crates/stable_prover/keccak_gkr/src/witness.rs', lines 190:0-211:1
    Visibility: public -/
axiom witness.commit_states
  :
  witness.Shape → Slice (Array Std.U64 25#usize) → Slice
    stable_primitives.field.gf2_64.F64 → RustM (Slice
    stable_primitives.field.gf2_64.F64)

/-- [stable_keccak_gkr::witness::{stable_keccak_gkr::witness::Witness}::generate]:
    Source: 'crates/stable_prover/keccak_gkr/src/witness.rs', lines 215:4-219:5
    Visibility: public -/
axiom witness.Witness.generate
  :
  witness.Shape → Slice (Array Std.U64 25#usize) → Slice
    stable_primitives.field.gf2_64.F64 → RustM (witness.Witness × (Slice
    stable_primitives.field.gf2_64.F64))

end stable_keccak_gkr
