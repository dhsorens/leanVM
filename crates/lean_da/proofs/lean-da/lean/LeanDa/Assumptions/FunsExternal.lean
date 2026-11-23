-- [lean_da]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import LeanDa.Extraction.Types
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

namespace lean_da

/-- [lean_da::commit::{lean_da::commit::BlobMatrix}::build]:
    Source: 'crates/lean_da/src/commit.rs', lines 29:4-48:5
    Visibility: public -/
axiom commit.BlobMatrix.build
  :
  Slice (Array Std.U128 8192#usize) → RustM (core.result.Result
    commit.BlobMatrix commit.BlobCountError)

/-- [lean_da::commit::{lean_da::commit::BlobMatrix}::row]:
    Source: 'crates/lean_da/src/commit.rs', lines 57:4-59:5
    Visibility: public -/
axiom commit.BlobMatrix.row
  :
  commit.BlobMatrix → Std.Usize → RustM (core.option.Option (Array Std.U128
    16384#usize))

/-- [lean_da::commit::{lean_da::commit::BlobMatrix}::column]:
    Source: 'crates/lean_da/src/commit.rs', lines 62:4-64:5
    Visibility: public -/
axiom commit.BlobMatrix.column
  :
  commit.BlobMatrix → Std.Usize → RustM (core.option.Option
    (core.iter.adapters.filter_map.FilterMap (core.ops.range.Range Std.Usize)
    commit.BlobMatrix.column.closure.closure))

/-- [lean_da::commit::{lean_da::commit::BlobMatrix}::column::{closure}::{impl core::ops::function::FnMut<(usize,), core::option::Option<&'_ [u128; 128usize]>> for lean_da::commit::{lean_da::commit::BlobMatrix}::column::{closure}::{closure}<'_0>}::call_mut]:
    Source: 'crates/lean_da/src/commit.rs', lines 63:73-63:117 -/
axiom
  commit.BlobMatrix.column.closure.closure.Insts.CoreOpsFunctionFnMutTupleUsizeOptionSharedArrayU128128.call_mut
  :
  commit.BlobMatrix.column.closure.closure → Std.Usize → RustM
    ((core.option.Option (Array Std.U128 128#usize)) ×
    commit.BlobMatrix.column.closure.closure)

/-- [lean_da::commit::{lean_da::commit::BlobMatrix}::cell]:
    Source: 'crates/lean_da/src/commit.rs', lines 67:4-69:5
    Visibility: public -/
axiom commit.BlobMatrix.cell
  :
  commit.BlobMatrix → Std.Usize → Std.Usize → RustM (core.option.Option
    (Array Std.U128 128#usize))

/-- [lean_da::commit::{lean_da::commit::BlobMatrix}::merkle_path_for_cell]:
    Source: 'crates/lean_da/src/commit.rs', lines 78:4-84:5
    Visibility: public -/
axiom commit.BlobMatrix.merkle_path_for_cell
  :
  commit.BlobMatrix → Std.Usize → Std.Usize → RustM (core.option.Option
    (Array (Array Std.U8 32#usize) 12#usize))

/-- [lean_da::commit::verify_cell]:
    Source: 'crates/lean_da/src/commit.rs', lines 100:0-122:1
    Visibility: public -/
axiom commit.verify_cell
  :
  Array Std.U8 32#usize → Std.Usize → Std.Usize → Std.Usize → Array
    Std.U128 128#usize → Array (Array Std.U8 32#usize) 12#usize → RustM
    Bool

/-- [lean_da::commit::{impl core::fmt::Debug for lean_da::commit::BlobCountError}::fmt]:
    Source: 'crates/lean_da/src/commit.rs', lines 132:22-132:27
    Visibility: public -/
axiom commit.BlobCountError.Insts.CoreFmtDebug.fmt
  :
  commit.BlobCountError → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_da::commit::{impl core::fmt::Display for lean_da::commit::BlobCountError}::fmt]:
    Source: 'crates/lean_da/src/commit.rs', lines 139:4-141:5
    Visibility: public -/
axiom commit.BlobCountError.Insts.CoreFmtDisplay.fmt
  :
  commit.BlobCountError → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_da::commit::blob_merkle_nodes]:
    Source: 'crates/lean_da/src/commit.rs', lines 152:0-163:1 -/
axiom commit.blob_merkle_nodes
  :
  Slice (Array Std.U128 16384#usize) → RustM (alloc.vec.Vec (Array Std.U8
    32#usize))

/-- [lean_da::commit::fill_levels]:
    Source: 'crates/lean_da/src/commit.rs', lines 176:0-188:1 -/
axiom commit.fill_levels
  : Slice (Array Std.U8 32#usize) → RustM (Slice (Array Std.U8 32#usize))

/-- [lean_da::commit::as_bytes]:
    Source: 'crates/lean_da/src/commit.rs', lines 191:0-193:1 -/
axiom commit.as_bytes : Slice Std.U128 → RustM (alloc.vec.Vec Std.U8)

/-- [lean_da::encode::encode_rows]:
    Source: 'crates/lean_da/src/encode.rs', lines 12:0-23:1 -/
axiom encode.encode_rows
  : Slice (Array Std.U128 8192#usize) → RustM (alloc.vec.Vec Std.U128)

end lean_da
