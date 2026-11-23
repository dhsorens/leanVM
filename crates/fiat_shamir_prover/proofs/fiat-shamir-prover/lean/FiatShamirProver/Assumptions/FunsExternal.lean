-- [fiat_shamir_prover]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import FiatShamirProver.Extraction.Types
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

namespace fiat_shamir_prover

/-- [fiat_shamir_prover::{impl fiat_shamir_prover::Search for fiat_shamir_prover::Sequential}::find_first]:
    Source: 'crates/fiat_shamir_prover/src/lib.rs', lines 53:4-55:5
    Visibility: public -/
axiom Sequential.Insts.Fiat_shamir_proverSearch.find_first
  :
  Std.Usize → Dyn (fun _dyn => core.ops.function.Fn _dyn Std.Usize Bool) →
    RustM (core.option.Option Std.Usize)

/-- [fiat_shamir_prover::{fiat_shamir_prover::FiatShamirState<F>}::sample]:
    Source: 'crates/fiat_shamir_prover/src/lib.rs', lines 145:4-147:5
    Visibility: public -/
axiom FiatShamirState.sample
  {F : Type _} (ScalarInst : Scalar F) :
  FiatShamirState F → RustM (F × (FiatShamirState F))

/-- [fiat_shamir_prover::{fiat_shamir_prover::FiatShamirState<F>}::sample_vec]:
    Source: 'crates/fiat_shamir_prover/src/lib.rs', lines 150:4-152:5
    Visibility: public -/
axiom FiatShamirState.sample_vec
  {F : Type _} (ScalarInst : Scalar F) :
  FiatShamirState F → Std.Usize → RustM ((alloc.vec.Vec F) ×
    (FiatShamirState F))

/-- [fiat_shamir_prover::{fiat_shamir_prover::FiatShamirState<F>}::grind_from]:
    Source: 'crates/fiat_shamir_prover/src/lib.rs', lines 164:4-199:5 -/
axiom FiatShamirState.grind_from
  {F : Type _} {S : Type _} (ScalarInst : Scalar F) (SearchInst : Search S) :
  FiatShamirState F → Std.U32 → Std.U64 → RustM ((core.option.Option
    Std.U64) × (FiatShamirState F))

/-- [fiat_shamir_prover::merkle::hash_words]:
    Source: 'crates/fiat_shamir_prover/src/merkle.rs', lines 16:0-18:1
    Visibility: public -/
axiom merkle.hash_words
  {T0 : Type _} {Clause0_IntoIter : Type _}
  (coreitertraitscollectIntoIteratorT0U64Clause0_IntoIterInst :
  core.iter.traits.collect.IntoIterator T0 Std.U64 Clause0_IntoIter) :
  T0 → RustM (Array Std.U8 32#usize)

/-- [fiat_shamir_prover::merkle::open]:
    Source: 'crates/fiat_shamir_prover/src/merkle.rs', lines 25:0-45:1
    Visibility: public -/
axiom merkle.open
  {R : Type _} {T1 : Type _} {T2 : Type _} {Clause0_IntoIter : Type _}
  (coreitertraitscollectIntoIteratorRU64Clause0_IntoIterInst :
  core.iter.traits.collect.IntoIterator R Std.U64 Clause0_IntoIter)
  (coreopsfunctionFnT1PairUsizeUsizeArrayU832Inst : core.ops.function.Fn T1
  (Std.Usize × Std.Usize) (Array Std.U8 32#usize))
  (coreopsfunctionFnT2TupleUsizeRInst : core.ops.function.Fn T2 Std.Usize R) :
  Std.Usize → Slice Std.Usize → Std.Usize → T1 → T2 → RustM
    (alloc.vec.Vec verifier.merkle.MerklePath)

end fiat_shamir_prover
