-- [primitives]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import Primitives.Extraction.Types
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
open primitives

/-- [primitives::bits::bit_transpose_64bytes]:
    Source: 'crates/primitives/src/bits.rs', lines 16:0-32:1
    Visibility: public -/
axiom bits.bit_transpose_64bytes
  :
  Array Std.U8 64#usize → Array Std.U8 64#usize → RustM (Array Std.U8
    64#usize)

/-- [primitives::field::gf2_64::{impl core::fmt::Debug for primitives::field::gf2_64::F64}::fmt]:
    Source: 'crates/primitives/src/field/gf2_64.rs', lines 17:22-17:27
    Visibility: public -/
axiom field.gf2_64.F64.Insts.CoreFmtDebug.fmt
  :
  field.gf2_64.F64 → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [primitives::field::gf2_64x3::{impl core::fmt::Debug for primitives::field::gf2_64x3::F192}::fmt]:
    Source: 'crates/primitives/src/field/gf2_64x3.rs', lines 32:22-32:27
    Visibility: public -/
axiom field.gf2_64x3.F192.Insts.CoreFmtDebug.fmt
  :
  field.gf2_64x3.F192 → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [primitives::field::gf2_64x3::{impl core::fmt::Debug for primitives::field::gf2_64x3::Weights8}::fmt]:
    Source: 'crates/primitives/src/field/gf2_64x3.rs', lines 297:22-297:27
    Visibility: public -/
axiom field.gf2_64x3.Weights8.Insts.CoreFmtDebug.fmt
  :
  field.gf2_64x3.Weights8 → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [primitives::field::gf2_64x3::{impl core::fmt::Debug for primitives::field::gf2_64x3::F192Unreduced}::fmt]:
    Source: 'crates/primitives/src/field/gf2_64x3.rs', lines 362:22-362:27
    Visibility: public -/
axiom field.gf2_64x3.F192Unreduced.Insts.CoreFmtDebug.fmt
  :
  field.gf2_64x3.F192Unreduced → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [primitives::field::g_powers]:
    Source: 'crates/primitives/src/field/mod.rs', lines 70:0-81:1
    Visibility: public -/
axiom field.g_powers : Std.Usize → RustM (alloc.vec.Vec field.gf2_64.F64)

/-- [primitives::field::g_pow32_by_lookup]:
    Source: 'crates/primitives/src/field/mod.rs', lines 104:0-128:1
    Visibility: public -/
axiom field.g_pow32_by_lookup : Std.U32 → RustM field.gf2_64.F64

/-- [primitives::hash::{impl primitives::hash::Lanes64 for u64}::store]:
    Source: 'crates/primitives/src/hash.rs', lines 172:4-174:5 -/
axiom U64.Insts.PrimitivesHashLanes64.store
  : Std.U64 → MutRawPtr Std.U64 → RustM Unit

/-- [primitives::hash::{impl primitives::hash::Lanes64 for u64}::load]:
    Source: 'crates/primitives/src/hash.rs', lines 168:4-170:5 -/
axiom U64.Insts.PrimitivesHashLanes64.load
  : ConstRawPtr Std.U64 → RustM Std.U64

/-- [primitives::hash::LANES]
    Source: 'crates/primitives/src/hash.rs', lines 545:0-545:40
    Visibility: public -/
axiom hash.LANES : RustM Std.Usize

/-- [primitives::hash::hash_group]:
    Source: 'crates/primitives/src/hash.rs', lines 557:0-613:1 -/
axiom hash.hash_group
  {S : Type _} (Lanes64Inst : hash.Lanes64 S) :
  Slice (ConstRawPtr Std.U8) → Std.Usize → Array Std.U64 25#usize →
    MutRawPtr Std.U8 → RustM Unit

/-- [primitives::hash::hash_many_with]:
    Source: 'crates/primitives/src/hash.rs', lines 620:0-637:1 -/
axiom hash.hash_many_with
  {S : Type _} (Lanes64Inst : hash.Lanes64 S) :
  Slice Std.U8 → Std.Usize → Array Std.U64 25#usize → Slice Std.U8 →
    RustM (Slice Std.U8)

/-- [primitives::hash::hash_many_from_state]:
    Source: 'crates/primitives/src/hash.rs', lines 648:0-654:1
    Visibility: public -/
axiom hash.hash_many_from_state
  :
  Slice Std.U8 → Std.Usize → Array Std.U64 25#usize → Slice Std.U8 →
    RustM (Slice Std.U8)

/-- [primitives::hash::keccak_f_many]:
    Source: 'crates/primitives/src/hash.rs', lines 657:0-665:1
    Visibility: public -/
axiom hash.keccak_f_many
  : Slice (Array Std.U64 25#usize) → RustM (Slice (Array Std.U64 25#usize))

/-- [primitives::hash::permute_group]:
    Source: 'crates/primitives/src/hash.rs', lines 669:0-690:1 -/
axiom hash.permute_group
  {S : Type _} (Lanes64Inst : hash.Lanes64 S) :
  Slice (Array Std.U64 25#usize) → RustM (Slice (Array Std.U64 25#usize))

/-- [primitives::pretty_integer]:
    Source: 'crates/primitives/src/lib.rs', lines 26:0-49:1
    Visibility: public -/
axiom pretty_integer
  {T0 : Type _} (allocstringToStringInst : alloc.string.ToString T0) :
  T0 → RustM alloc.string.String

/-- [primitives::pretty_f64]:
    Source: 'crates/primitives/src/lib.rs', lines 63:0-96:1
    Visibility: public -/
axiom pretty_f64 : F64 → RustM alloc.string.String

/-- [primitives::uninit_vec]:
    Source: 'crates/primitives/src/lib.rs', lines 124:0-131:1
    Visibility: public -/
axiom uninit_vec
  {T : Type _} (coremarkerCopyInst : core.marker.Copy T) :
  Std.Usize → RustM (alloc.vec.Vec T)

/-- [primitives::par_collect]:
    Source: 'crates/primitives/src/lib.rs', lines 137:0-166:1
    Visibility: public -/
axiom par_collect
  {T : Type _} {T1 : Type _} (coreopsfunctionFnT1TupleUsizeTInst :
  core.ops.function.Fn T1 Std.Usize T) :
  Std.Usize → T1 → RustM (alloc.vec.Vec T)

/-- [primitives::multilinear::eq_table]:
    Source: 'crates/primitives/src/multilinear.rs', lines 37:0-44:1
    Visibility: public -/
axiom multilinear.eq_table
  : Slice field.gf2_64x3.F192 → RustM (alloc.vec.Vec field.gf2_64x3.F192)

/-- [primitives::multilinear::fill_eq_table_uninit]:
    Source: 'crates/primitives/src/multilinear.rs', lines 58:0-78:1
    Visibility: public -/
axiom multilinear.fill_eq_table_uninit
  :
  Slice field.gf2_64x3.F192 → field.gf2_64x3.F192 → Slice
    (core.mem.maybe_uninit.MaybeUninit field.gf2_64x3.F192) → RustM (Slice
    (core.mem.maybe_uninit.MaybeUninit field.gf2_64x3.F192))

/-- [primitives::multilinear::fill_eq_doubling]:
    Source: 'crates/primitives/src/multilinear.rs', lines 89:0-111:1 -/
axiom multilinear.fill_eq_doubling
  :
  Slice field.gf2_64x3.F192 → field.gf2_64x3.F192 → Slice
    (core.mem.maybe_uninit.MaybeUninit field.gf2_64x3.F192) → RustM (Slice
    (core.mem.maybe_uninit.MaybeUninit field.gf2_64x3.F192))

/-- [primitives::multilinear::fold_high_k]:
    Source: 'crates/primitives/src/multilinear.rs', lines 129:0-146:1
    Visibility: public -/
axiom multilinear.fold_high_k
  :
  Slice field.gf2_64.F64 → field.gf2_64x3.F192 → RustM (alloc.vec.Vec
    field.gf2_64x3.F192)

/-- [primitives::multilinear::packed_eq]:
    Source: 'crates/primitives/src/multilinear.rs', lines 274:0-276:1 -/
axiom multilinear.packed_eq
  : Slice field.gf2_64x3.F192 → RustM (alloc.vec.Vec field.gf2_64x3.Weights8)

/-- [primitives::multilinear::mle_eval_par]:
    Source: 'crates/primitives/src/multilinear.rs', lines 258:0-268:1
    Visibility: public -/
axiom multilinear.mle_eval_par
  :
  Slice field.gf2_64.F64 → Slice field.gf2_64x3.F192 → RustM
    field.gf2_64x3.F192

/-- [primitives::stream::{primitives::stream::Stream}::copy]:
    Source: 'crates/primitives/src/stream.rs', lines 29:4-34:5
    Visibility: public -/
axiom stream.Stream.copy
  {T : Type _} (coremarkerCopyInst : core.marker.Copy T) :
  stream.Stream → Slice T → Slice T → RustM (Slice T)

/-- [primitives::stream::{primitives::stream::Stream}::copy_uninit]:
    Source: 'crates/primitives/src/stream.rs', lines 41:4-44:5
    Visibility: public -/
axiom stream.Stream.copy_uninit
  {T : Type _} (coremarkerCopyInst : core.marker.Copy T) :
  stream.Stream → MutRawPtr T → Slice T → RustM Unit

/-- [primitives::stream::copy_raw]:
    Source: 'crates/primitives/src/stream.rs', lines 50:0-69:1 -/
axiom stream.copy_raw
  : MutRawPtr Std.U8 → ConstRawPtr Std.U8 → Std.Usize → RustM Unit

/-- [primitives::stream::{impl core::ops::drop::Drop for primitives::stream::Stream}::drop]:
    Source: 'crates/primitives/src/stream.rs', lines 73:4-79:5
    Visibility: public -/
axiom stream.Stream.Insts.CoreOpsDropDrop.drop
  : stream.Stream → RustM stream.Stream

