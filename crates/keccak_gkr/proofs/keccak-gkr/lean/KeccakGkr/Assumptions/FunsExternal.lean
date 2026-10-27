-- [keccak_gkr]: external functions.
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
open keccak_gkr

/-- [keccak_gkr::basis::clear_column]:
    Source: 'crates/keccak_gkr/src/basis.rs', lines 21:0-29:1 -/
axiom basis.clear_column
  :
  Array (Array Std.U64 3#usize) 192#usize → Array (Array Std.U64 3#usize)
    192#usize → Std.Usize → RustM ((Array (Array Std.U64 3#usize)
    192#usize) × (Array (Array Std.U64 3#usize) 192#usize))

/-- [keccak_gkr::kernels::skip_row_portable]:
    Source: 'crates/keccak_gkr/src/kernels.rs', lines 185:0-196:1
    Visibility: public -/
axiom kernels.skip_row_portable
  :
  kernels.SkipAcc → Array (Array Std.U32 136#usize) 5#usize → Array (Array
    Std.U64 3#usize) 5#usize → RustM kernels.SkipAcc

/-- [keccak_gkr::kernels::{keccak_gkr::kernels::SkipBlock}::run]:
    Source: 'crates/keccak_gkr/src/kernels.rs', lines 280:12-291:13
    Visibility: public -/
axiom kernels.SkipBlock.run
  :
  kernels.SkipBlock → Slice Std.U64 → Slice (Array Std.U64 3#usize) →
    RustM kernels.SkipBlock

/-- [keccak_gkr::{impl core::fmt::Debug for keccak_gkr::OutputClaim}::fmt]:
    Source: 'crates/keccak_gkr/src/lib.rs', lines 116:16-116:21
    Visibility: public -/
axiom OutputClaim.Insts.CoreFmtDebug.fmt
  :
  OutputClaim → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [keccak_gkr::{keccak_gkr::OutputClaim}::of_inputs]:
    Source: 'crates/keccak_gkr/src/lib.rs', lines 126:4-153:5
    Visibility: public -/
axiom OutputClaim.of_inputs
  :
  witness.Shape → Slice (Array Std.U64 25#usize) → alloc.vec.Vec
    primitives.field.gf2_64x3.F192 → RustM OutputClaim

/-- [keccak_gkr::prover::{keccak_gkr::prover::Round<'a>}::fold]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 506:4-571:5 -/
axiom prover.Round.fold
  :
  prover.Round → Slice Std.U64 → prover.Rows → Slice Std.U64 → Slice
    Std.U64 → Array Std.U64 3#usize → Slice primitives.field.gf2_64x3.F192
    → RustM ((primitives.field.gf2_64x3.F192 ×
    primitives.field.gf2_64x3.F192) × (Slice Std.U64))

/-- [keccak_gkr::prover::{keccak_gkr::prover::Layer<'_0>}::table]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 354:4-415:5 -/
axiom prover.Layer.table
  :
  prover.Layer → prover.Round → Slice primitives.field.gf2_64x3.F192 →
    Slice primitives.field.gf2_64x3.F192 → prover.Rows → Slice Std.U64 →
    Slice Std.U64 → RustM ((primitives.field.gf2_64x3.F192 ×
    primitives.field.gf2_64x3.F192) × (Slice Std.U64) × (Slice Std.U64))

/-- [keccak_gkr::prover::{keccak_gkr::prover::Layer<'_0>}::skip_sums]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 309:4-348:5 -/
axiom prover.Layer.skip_sums
  :
  prover.Layer → protocol.Claim → power.PowerField →
    primitives.field.gf2_64x3.F192 → Array primitives.field.gf2_64x3.F192
    16#usize → RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192)

/-- [keccak_gkr::prover::{keccak_gkr::prover::Layer<'_0>}::pack_products]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 244:4-300:5 -/
axiom prover.Layer.pack_products
  :
  prover.Layer → protocol.Claim → RustM (alloc.vec.Vec (Array
    primitives.field.gf2_64x3.F192 47#usize))

/-- [keccak_gkr::open::spare_slices]:
    Source: 'crates/keccak_gkr/src/open.rs', lines 255:0-283:1 -/
axiom open.spare_slices
  :
  witness.Shape → Slice primitives.field.gf2_64.F64 → Slice
    primitives.field.gf2_64x3.F192 → RustM (alloc.vec.Vec (Array
    primitives.field.gf2_64x3.F192 64#usize))

/-- [keccak_gkr::open::fold_packs]:
    Source: 'crates/keccak_gkr/src/open.rs', lines 102:0-147:1 -/
axiom open.fold_packs
  :
  witness.Witness → Slice primitives.field.gf2_64x3.F192 → RustM
    (alloc.vec.Vec primitives.field.gf2_64x3.F192)

/-- [keccak_gkr::open::output_claim]:
    Source: 'crates/keccak_gkr/src/open.rs', lines 220:0-227:1
    Visibility: public -/
axiom open.output_claim
  :
  witness.Shape → Slice primitives.field.gf2_64.F64 → Slice
    primitives.field.gf2_64x3.F192 → protocol.Claim → RustM ((alloc.vec.Vec
    primitives.field.gf2_64x3.F192) × primitives.field.gf2_64x3.F192)

/-- [keccak_gkr::open::{impl core::fmt::Debug for keccak_gkr::open::Opening}::fmt]:
    Source: 'crates/keccak_gkr/src/open.rs', lines 21:16-21:21
    Visibility: public -/
axiom open.Opening.Insts.CoreFmtDebug.fmt
  :
  open.Opening → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [keccak_gkr::open::{impl core::fmt::Debug for keccak_gkr::open::WordOpening}::fmt]:
    Source: 'crates/keccak_gkr/src/open.rs', lines 28:16-28:21
    Visibility: public -/
axiom open.WordOpening.Insts.CoreFmtDebug.fmt
  :
  open.WordOpening → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [keccak_gkr::open::{impl core::fmt::Debug for keccak_gkr::open::Openings}::fmt]:
    Source: 'crates/keccak_gkr/src/open.rs', lines 36:16-36:21
    Visibility: public -/
axiom open.Openings.Insts.CoreFmtDebug.fmt
  :
  open.Openings → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [keccak_gkr::open::le_bytes]:
    Source: 'crates/keccak_gkr/src/open.rs', lines 150:0-156:1 -/
axiom open.le_bytes : Array Std.U64 8#usize → RustM (Array Std.U8 64#usize)

/-- [keccak_gkr::power::{keccak_gkr::power::PowerField}::dot_pair]:
    Source: 'crates/keccak_gkr/src/power.rs', lines 122:4-125:5
    Visibility: public -/
axiom power.PowerField.dot_pair
  :
  power.PowerField → Array (Slice Std.U64) 2#usize → Array (Slice Std.U64)
    2#usize → Std.Usize → RustM ((Array Std.U64 6#usize) × (Array Std.U64
    6#usize))

/-- [keccak_gkr::power::dot_pair_portable]:
    Source: 'crates/keccak_gkr/src/power.rs', lines 196:0-214:1
    Visibility: public -/
axiom power.dot_pair_portable
  :
  Array (Slice Std.U64) 2#usize → Array (Slice Std.U64) 2#usize → Std.Usize
    → RustM ((Array Std.U64 6#usize) × (Array Std.U64 6#usize))

/-- [keccak_gkr::protocol::{impl core::fmt::Debug for keccak_gkr::protocol::Claim}::fmt]:
    Source: 'crates/keccak_gkr/src/protocol.rs', lines 20:16-20:21
    Visibility: public -/
axiom protocol.Claim.Insts.CoreFmtDebug.fmt
  :
  protocol.Claim → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [keccak_gkr::prover::{keccak_gkr::prover::Part}::pack]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 68:4-74:5 -/
axiom prover.Part.pack : Array Std.U64 8#usize → RustM prover.Part

/-- [keccak_gkr::prover::{keccak_gkr::prover::Part}::add]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 77:4-118:5 -/
axiom prover.Part.add : prover.Part → prover.Part → RustM prover.Part

/-- [keccak_gkr::prover::{keccak_gkr::prover::Groups}::add_rows]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 162:4-188:5 -/
axiom prover.Groups.add_rows
  :
  prover.Groups → Array prover.Part 1600#usize → Array prover.Part
    192#usize → Array prover.Part 256#usize → RustM ((Array prover.Part
    192#usize) × (Array prover.Part 256#usize))

/-- [keccak_gkr::prover::{keccak_gkr::prover::Round<'a>}::factors]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 465:4-483:5 -/
axiom prover.Round.factors
  :
  prover.Round → Slice Std.U64 → Slice Std.U64 → Slice Std.U64 → RustM
    ((Slice Std.U64) × (Slice Std.U64))

/-- [keccak_gkr::prover::{keccak_gkr::prover::Round<'a>}::add_pair]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 487:4-498:5 -/
axiom prover.Round.add_pair
  :
  prover.Round → prover.RoundSums → Slice Std.U64 → Slice Std.U64 →
    Slice Std.U64 → primitives.field.gf2_64x3.F192 → RustM
    (prover.RoundSums × (Slice Std.U64))

/-- [keccak_gkr::prover::{keccak_gkr::prover::Round<'a>}::add_padding]:
    Source: 'crates/keccak_gkr/src/prover.rs', lines 575:4-584:5 -/
axiom prover.Round.add_padding
  :
  prover.Round → prover.RoundSums → prover.Rows → Slice Std.U64 → Slice
    primitives.field.gf2_64x3.F192 → RustM prover.RoundSums

/-- [keccak_gkr::witness::{impl core::fmt::Debug for keccak_gkr::witness::Shape}::fmt]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 29:22-29:27
    Visibility: public -/
axiom witness.Shape.Insts.CoreFmtDebug.fmt
  :
  witness.Shape → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [keccak_gkr::witness::{keccak_gkr::witness::Extent}::slot]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 127:4-134:5
    Visibility: public -/
axiom witness.Extent.slot
  : witness.Extent → Std.Usize → RustM (witness.Slot × witness.Extent)

/-- [keccak_gkr::witness::transpose64]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 151:0-172:1
    Visibility: public -/
axiom witness.transpose64
  : Array Std.U64 64#usize → RustM (Array Std.U64 64#usize)

/-- [keccak_gkr::witness::block]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 203:0-260:1
    Visibility: public -/
axiom witness.block
  {T0 : Type _}
  (coreopsfunctionFnMutT0TupleUsizeUsizeShared0ArrayU6464TupleInst :
  core.ops.function.FnMut T0 (Std.Usize × Std.Usize × (Array Std.U64
  64#usize)) Unit) :
  Std.Usize → Slice (Array Std.U64 25#usize) → witness.Slot → T0 →
    RustM Unit

/-- [keccak_gkr::witness::block_lanes]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 266:0-276:1
    Visibility: public -/
axiom witness.block_lanes
  :
  Std.Usize → Slice (Array Std.U64 25#usize) → witness.Slot → RustM
    (alloc.vec.Vec Std.U64)

/-- [keccak_gkr::witness::{keccak_gkr::witness::Column<'a>}::write]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 318:4-321:5 -/
axiom witness.Column.write
  :
  witness.Column → primitives.stream.Stream → Std.Usize → Std.Usize →
    Std.Usize → Slice Std.U64 → RustM witness.Column

/-- [keccak_gkr::witness::{keccak_gkr::witness::Column<'a>}::write_block]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 327:4-333:5 -/
axiom witness.Column.write_block
  : witness.Column → Std.Usize → Slice Std.U64 → RustM witness.Column

/-- [keccak_gkr::witness::{keccak_gkr::witness::Witness}::generate]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 342:4-365:5
    Visibility: public -/
axiom witness.Witness.generate
  :
  witness.Shape → Slice (Array Std.U64 25#usize) → Slice
    primitives.field.gf2_64.F64 → RustM (witness.Witness × (Slice
    primitives.field.gf2_64.F64))

/-- [keccak_gkr::witness::{keccak_gkr::witness::Witness}::from_blocks]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 374:4-387:5
    Visibility: public -/
axiom witness.Witness.from_blocks
  :
  witness.Shape → alloc.vec.Vec witness.Extent → Slice (alloc.vec.Vec
    Std.U64) → Slice primitives.field.gf2_64.F64 → RustM (witness.Witness
    × (Slice primitives.field.gf2_64.F64))

/-- [keccak_gkr::witness::{keccak_gkr::witness::Witness}::from_extents]:
    Source: 'crates/keccak_gkr/src/witness.rs', lines 395:4-414:5 -/
axiom witness.Witness.from_extents
  :
  witness.Shape → alloc.vec.Vec witness.Extent → Std.Usize →
    core.option.Option witness.Extent → RustM witness.Witness

