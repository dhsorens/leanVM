-- [signatures]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import Signatures.Extraction.Types
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
open signatures

-- Items of other workspace crates the extraction uses, which hax does not declare: written
-- here by hand, above the generated declarations (wire.py keeps this header as it is).

-- `primitives::hash::RATE`: Keccak-256's rate, in bytes.
def primitives.hash.RATE : RustM Std.Usize := ok 136#usize

-- `primitives::hash::Hasher::new`, assumed: the empty Keccak-256 sponge.
axiom primitives.hash.Hasher.new : RustM primitives.hash.Hasher

-- `primitives::hash::Hasher::update`, assumed: absorbs the bytes; the second component is
-- the back function of the `&mut Self` it returns.
axiom primitives.hash.Hasher.update :
  primitives.hash.Hasher → Slice Std.U8 →
    RustM (primitives.hash.Hasher × (primitives.hash.Hasher → primitives.hash.Hasher))

-- `primitives::hash::Hasher::finalize`, assumed: the Keccak-256 digest of what was absorbed.
axiom primitives.hash.Hasher.finalize : primitives.hash.Hasher → RustM (Array Std.U8 32#usize)

-- The derived `Clone` of `primitives::hash::Hasher`, a struct of arrays and a `usize`.
def primitives.hash.Hasher.Insts.CoreCloneClone.clone (self : primitives.hash.Hasher) :
    RustM primitives.hash.Hasher :=
  ok self

-- `parallel::map_collect`: `[f(0), .., f(n_tasks - 1)]`, here computed in order.
def parallel.map_collect {T F : Type} (FnInst : core.ops.function.Fn F Std.Usize T)
    (n_tasks : Std.Usize) (f : F) : RustM (alloc.vec.Vec T) := do
  let empty ← alloc.vec.Vec.new T
  (List.range n_tasks.val).foldlM
    (fun out i => do
      let x ← FnInst.call f ⟨BitVec.ofNat _ i⟩
      alloc.vec.Vec.push out x)
    empty

-- `parallel::find_first`: the least `i < n_tasks` with `pred(i)`, here searched in order.
def parallel.find_first {P : Type} (FnInst : core.ops.function.Fn P Std.Usize Bool)
    (n_tasks : Std.Usize) (pred : P) : RustM (core.option.Option Std.Usize) :=
  (List.range n_tasks.val).foldlM
    (fun found i => match found with
      | .some _ => ok found
      | .none => do
        let hit ← FnInst.call pred ⟨BitVec.ofNat _ i⟩
        ok (if hit then .some ⟨BitVec.ofNat _ i⟩ else .none))
    .none

/-- [signatures::lean_sphincs::forest::{impl core::fmt::Debug for signatures::lean_sphincs::forest::Mark}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/forest.rs', lines 84:22-84:27
    Visibility: public -/
axiom lean_sphincs.forest.Mark.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.forest.Mark → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::forest::{impl core::fmt::Debug for signatures::lean_sphincs::forest::SubtreeOpening}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/forest.rs', lines 93:22-93:27
    Visibility: public -/
axiom lean_sphincs.forest.SubtreeOpening.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.forest.SubtreeOpening → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::forest::{impl core::fmt::Debug for signatures::lean_sphincs::forest::TreeOpening}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/forest.rs', lines 100:22-100:27
    Visibility: public -/
axiom lean_sphincs.forest.TreeOpening.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.forest.TreeOpening → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::scheme::{impl core::fmt::Debug for signatures::lean_sphincs::scheme::LeanSphincsPublicKey}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/scheme.rs', lines 19:22-19:27
    Visibility: public -/
axiom lean_sphincs.scheme.LeanSphincsPublicKey.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.scheme.LeanSphincsPublicKey → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::scheme::{impl core::fmt::Debug for signatures::lean_sphincs::scheme::LeanSphincsSecretKey}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/scheme.rs', lines 73:4-78:5
    Visibility: public -/
axiom lean_sphincs.scheme.LeanSphincsSecretKey.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.scheme.LeanSphincsSecretKey → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::scheme::{impl core::fmt::Debug for signatures::lean_sphincs::scheme::LeanSphincsSignature}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/scheme.rs', lines 137:16-137:21
    Visibility: public -/
axiom lean_sphincs.scheme.LeanSphincsSignature.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.scheme.LeanSphincsSignature → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::scheme::{impl core::fmt::Debug for signatures::lean_sphincs::scheme::LeanSphincsSignError}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/scheme.rs', lines 209:22-209:27
    Visibility: public -/
axiom lean_sphincs.scheme.LeanSphincsSignError.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.scheme.LeanSphincsSignError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::scheme::{impl core::fmt::Debug for signatures::lean_sphincs::scheme::LeanSphincsVerifyError}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/scheme.rs', lines 217:22-217:27
    Visibility: public -/
axiom lean_sphincs.scheme.LeanSphincsVerifyError.Insts.CoreFmtDebug.fmt
  :
  lean_sphincs.scheme.LeanSphincsVerifyError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::scheme::{impl core::fmt::Display for signatures::lean_sphincs::scheme::LeanSphincsSignError}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/scheme.rs', lines 225:4-230:5
    Visibility: public -/
axiom lean_sphincs.scheme.LeanSphincsSignError.Insts.CoreFmtDisplay.fmt
  :
  lean_sphincs.scheme.LeanSphincsSignError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_sphincs::scheme::{impl core::fmt::Display for signatures::lean_sphincs::scheme::LeanSphincsVerifyError}::fmt]:
    Source: 'crates/signatures/src/lean_sphincs/scheme.rs', lines 236:4-241:5
    Visibility: public -/
axiom lean_sphincs.scheme.LeanSphincsVerifyError.Insts.CoreFmtDisplay.fmt
  :
  lean_sphincs.scheme.LeanSphincsVerifyError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Debug for signatures::lean_xmss::scheme::LeanXmssPublicKey}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 15:9-15:14
    Visibility: public -/
axiom lean_xmss.scheme.LeanXmssPublicKey.Insts.CoreFmtDebug.fmt
  :
  lean_xmss.scheme.LeanXmssPublicKey → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Debug for signatures::lean_xmss::scheme::LayerSignature}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 40:9-40:14
    Visibility: public -/
axiom lean_xmss.scheme.LayerSignature.Insts.CoreFmtDebug.fmt
  :
  lean_xmss.scheme.LayerSignature → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Debug for signatures::lean_xmss::scheme::LeanXmssSignature}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 50:9-50:14
    Visibility: public -/
axiom lean_xmss.scheme.LeanXmssSignature.Insts.CoreFmtDebug.fmt
  :
  lean_xmss.scheme.LeanXmssSignature → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Debug for signatures::lean_xmss::scheme::LeanXmssSecretKey}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 114:4-118:5
    Visibility: public -/
axiom lean_xmss.scheme.LeanXmssSecretKey.Insts.CoreFmtDebug.fmt
  :
  lean_xmss.scheme.LeanXmssSecretKey → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Debug for signatures::lean_xmss::scheme::LeanXmssSignError}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 140:9-140:14
    Visibility: public -/
axiom lean_xmss.scheme.LeanXmssSignError.Insts.CoreFmtDebug.fmt
  :
  lean_xmss.scheme.LeanXmssSignError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Display for signatures::lean_xmss::scheme::LeanXmssSignError}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 146:4-150:5
    Visibility: public -/
axiom lean_xmss.scheme.LeanXmssSignError.Insts.CoreFmtDisplay.fmt
  :
  lean_xmss.scheme.LeanXmssSignError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{signatures::lean_xmss::scheme::LeanXmssSecretKey}::bottom_tree]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 236:4-263:5 -/
axiom lean_xmss.scheme.LeanXmssSecretKey.bottom_tree
  :
  lean_xmss.scheme.LeanXmssSecretKey → Std.U32 →
    core.ops.range.RangeInclusive Std.U32 → RustM (core.result.Result
    (alloc.sync.Arc lean_xmss.scheme.BottomTree)
    lean_xmss.scheme.LeanXmssSignError)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Debug for signatures::lean_xmss::scheme::LeanXmssVerifyError}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 266:9-266:14
    Visibility: public -/
axiom lean_xmss.scheme.LeanXmssVerifyError.Insts.CoreFmtDebug.fmt
  :
  lean_xmss.scheme.LeanXmssVerifyError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::lean_xmss::scheme::{impl core::fmt::Display for signatures::lean_xmss::scheme::LeanXmssVerifyError}::fmt]:
    Source: 'crates/signatures/src/lean_xmss/scheme.rs', lines 275:4-280:5
    Visibility: public -/
axiom lean_xmss.scheme.LeanXmssVerifyError.Insts.CoreFmtDisplay.fmt
  :
  lean_xmss.scheme.LeanXmssVerifyError → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [signatures::tweak::{impl core::fmt::Debug for signatures::tweak::Tweak}::fmt]:
    Source: 'crates/signatures/src/tweak.rs', lines 33:22-33:27
    Visibility: public -/
axiom tweak.Tweak.Insts.CoreFmtDebug.fmt
  :
  tweak.Tweak → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

