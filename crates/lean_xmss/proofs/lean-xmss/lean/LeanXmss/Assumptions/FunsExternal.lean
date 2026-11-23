-- [lean_xmss]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import LeanXmss.Extraction.Types
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

namespace lean_xmss

/-- [lean_xmss::hash::{impl core::fmt::Debug for lean_xmss::hash::Tweak}::fmt]:
    Source: 'crates/lean_xmss/src/hash.rs', lines 47:22-47:27
    Visibility: public -/
axiom hash.Tweak.Insts.CoreFmtDebug.fmt
  :
  hash.Tweak → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [lean_xmss::LEAF_INDEX_SIZE]
    Source: 'crates/lean_xmss/src/lib.rs', lines 62:0-62:65 -/
axiom LEAF_INDEX_SIZE : RustM Std.Usize

/-- [lean_xmss::scheme::{impl core::fmt::Debug for lean_xmss::scheme::LeanXmssPublicKey}::fmt]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 15:9-15:14
    Visibility: public -/
axiom scheme.LeanXmssPublicKey.Insts.CoreFmtDebug.fmt
  :
  scheme.LeanXmssPublicKey → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_xmss::scheme::{lean_xmss::scheme::LeanXmssPublicKey}::to_bytes]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 22:4-27:5
    Visibility: public -/
axiom scheme.LeanXmssPublicKey.to_bytes
  : scheme.LeanXmssPublicKey → RustM (Array Std.U8 32#usize)

/-- [lean_xmss::scheme::{impl core::fmt::Debug for lean_xmss::scheme::LayerSignature}::fmt]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 37:9-37:14
    Visibility: public -/
axiom scheme.LayerSignature.Insts.CoreFmtDebug.fmt
  :
  scheme.LayerSignature → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_xmss::scheme::{lean_xmss::scheme::LayerSignature}::parts]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 54:4-60:5 -/
axiom scheme.LayerSignature.parts
  : scheme.LayerSignature → RustM (Array (Slice Std.U8) 3#usize)

/-- [lean_xmss::scheme::{lean_xmss::scheme::LayerSignature}::read]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 63:4-69:5 -/
axiom scheme.LayerSignature.read
  : Slice Std.U8 → RustM (scheme.LayerSignature × (Slice Std.U8))

/-- [lean_xmss::scheme::take]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 73:0-77:1 -/
axiom scheme.take
  (L : Std.Usize) : Slice Std.U8 → RustM ((Array Std.U8 L) × (Slice Std.U8))

/-- [lean_xmss::scheme::{impl core::fmt::Debug for lean_xmss::scheme::LeanXmssSignature}::fmt]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 80:9-80:14
    Visibility: public -/
axiom scheme.LeanXmssSignature.Insts.CoreFmtDebug.fmt
  :
  scheme.LeanXmssSignature → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_xmss::scheme::{lean_xmss::scheme::LeanXmssSignature}::to_bytes]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 92:4-105:5
    Visibility: public -/
axiom scheme.LeanXmssSignature.to_bytes
  : scheme.LeanXmssSignature → RustM (Array Std.U8 2404#usize)

/-- [lean_xmss::scheme::{impl core::fmt::Debug for lean_xmss::scheme::LeanXmssExpandedSecretKey}::fmt]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 136:4-140:5
    Visibility: public -/
axiom scheme.LeanXmssExpandedSecretKey.Insts.CoreFmtDebug.fmt
  :
  scheme.LeanXmssExpandedSecretKey → core.fmt.Formatter → RustM
    ((core.result.Result Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_xmss::scheme::CACHED_BOTTOM_SIZE]
    Source: 'crates/lean_xmss/src/scheme.rs', lines 152:0-152:87 -/
axiom scheme.CACHED_BOTTOM_SIZE : RustM Std.Usize

/-- [lean_xmss::wots::wots_sign]:
    Source: 'crates/lean_xmss/src/wots.rs', lines 104:0-123:1 -/
axiom wots.wots_sign
  :
  Array Std.U8 16#usize → hash.SchemeSeed → Std.Usize → Std.U32 → Slice
    Std.U8 → RustM (core.option.Option ((Array Std.U8 16#usize) × (Array
    (Array Std.U8 16#usize) 58#usize)))

/-- [lean_xmss::tree::{lean_xmss::tree::LayerTree}::path]:
    Source: 'crates/lean_xmss/src/tree.rs', lines 70:4-76:5 -/
axiom tree.LayerTree.path
  :
  tree.LayerTree → Array Std.U8 16#usize → hash.SchemeSeed → Std.U32 →
    RustM (Array (Array Std.U8 16#usize) 16#usize)

/-- [lean_xmss::scheme::{lean_xmss::scheme::LeanXmssExpandedSecretKey}::bottom_tree]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 259:4-276:5 -/
axiom scheme.LeanXmssExpandedSecretKey.bottom_tree
  :
  scheme.LeanXmssExpandedSecretKey → Std.U32 → RustM (alloc.sync.Arc
    scheme.BottomTree)

/-- [lean_xmss::tree::levels]:
    Source: 'crates/lean_xmss/src/tree.rs', lines 17:0-24:1 -/
axiom tree.levels
  :
  Array Std.U8 16#usize → Std.Usize → Std.U32 → Std.Usize → Std.Usize
    → alloc.vec.Vec (Array Std.U8 16#usize) → RustM (alloc.vec.Vec
    (alloc.vec.Vec (Array Std.U8 16#usize)))

/-- [lean_xmss::scheme::{lean_xmss::scheme::LeanXmssExpandedSecretKey}::cache_to_bytes]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 204:4-212:5
    Visibility: public -/
axiom scheme.LeanXmssExpandedSecretKey.cache_to_bytes
  : scheme.LeanXmssExpandedSecretKey → RustM (alloc.vec.Vec Std.U8)

/-- [lean_xmss::scheme::{lean_xmss::scheme::LeanXmssExpandedSecretKey}::from_cache_bytes]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 220:4-244:5
    Visibility: public -/
axiom scheme.LeanXmssExpandedSecretKey.from_cache_bytes
  :
  Array Std.U8 32#usize → scheme.LeanXmssPublicKey → Slice Std.U8 → RustM
    (core.option.Option scheme.LeanXmssExpandedSecretKey)

/-- [lean_xmss::scheme::{lean_xmss::scheme::LeanXmssExpandedSecretKey}::cache]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 279:4-289:5 -/
axiom scheme.LeanXmssExpandedSecretKey.cache
  :
  scheme.LeanXmssExpandedSecretKey → alloc.sync.Arc scheme.BottomTree →
    RustM (alloc.sync.Arc scheme.BottomTree)

/-- [lean_xmss::scheme::use_cached]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 294:0-299:1 -/
axiom scheme.use_cached
  :
  alloc.collections.vec_deque.VecDeque (alloc.sync.Arc scheme.BottomTree)
    alloc.alloc.Global → Std.U32 → RustM ((core.option.Option
    (alloc.sync.Arc scheme.BottomTree)) ×
    (alloc.collections.vec_deque.VecDeque (alloc.sync.Arc scheme.BottomTree)
    alloc.alloc.Global))

/-- [lean_xmss::scheme::verify]:
    Source: 'crates/lean_xmss/src/scheme.rs', lines 302:0-310:1
    Visibility: public -/
axiom scheme.verify
  :
  scheme.LeanXmssPublicKey → Array Std.U8 32#usize →
    scheme.LeanXmssSignature → RustM Bool

/-- [lean_xmss::tree::subtree]:
    Source: 'crates/lean_xmss/src/tree.rs', lines 28:0-34:1 -/
axiom tree.subtree
  :
  Array Std.U8 16#usize → hash.SchemeSeed → Std.Usize → Std.U32 → RustM
    (alloc.vec.Vec (alloc.vec.Vec (Array Std.U8 16#usize)))

/-- [lean_xmss::tree::{lean_xmss::tree::LayerTree}::from_bytes]:
    Source: 'crates/lean_xmss/src/tree.rs', lines 54:4-57:5 -/
axiom tree.LayerTree.from_bytes
  : Std.Usize → Std.U32 → Slice Std.U8 → RustM tree.LayerTree

/-- [lean_xmss::wots::wots_secrets]:
    Source: 'crates/lean_xmss/src/wots.rs', lines 21:0-27:1 -/
axiom wots.wots_secrets
  :
  Array Std.U8 16#usize → hash.SchemeSeed → Std.Usize → Std.U32 → RustM
    (Array (Array Std.U8 16#usize) 58#usize)

/-- [lean_xmss::wots::least_trial]:
    Source: 'crates/lean_xmss/src/wots.rs', lines 81:0-97:1 -/
axiom wots.least_trial
  : Slice Std.U8 → Std.U128 → RustM (core.option.Option Std.U64)

end lean_xmss
