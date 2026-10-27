-- [leanvm_core]: external types.
-- Seeded by hax from Extraction/TypesExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import FiatShamir.Extraction
public import KeccakGkr.Extraction
public import Parallel.Extraction
public import Pcs.Extraction
public import Primitives.Extraction
public import Verifier.Extraction
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

namespace leanvm_core

/-- [leanvm_core::constraints::Claims]
    Source: 'crates/leanvm_core/src/constraints.rs', lines 43:0-46:1
    Visibility: public -/
axiom constraints.Claims : Type

/-- [leanvm_core::constraints::Air]
    Source: 'crates/leanvm_core/src/constraints.rs', lines 54:0-59:1
    Visibility: public -/
axiom constraints.Air : Type

/-- [leanvm_core::cpu::execute::Memory]
    Source: 'crates/leanvm_core/src/cpu/execute.rs', lines 80:0-83:1
    Visibility: public -/
axiom cpu.execute.Memory : Type

/-- [leanvm_core::cpu::execute::ExecError]
    Source: 'crates/leanvm_core/src/cpu/execute.rs', lines 113:0-119:1
    Visibility: public -/
axiom cpu.execute.ExecError : Type

/-- [leanvm_core::cpu::layout::Layout]
    Source: 'crates/leanvm_core/src/cpu/layout.rs', lines 134:0-152:1
    Visibility: public -/
axiom cpu.layout.Layout : Type

/-- [leanvm_core::leaf::BusForm]
    Source: 'crates/leanvm_core/src/leaf.rs', lines 492:0-497:1
    Visibility: public -/
axiom leaf.BusForm : Type

/-- [leanvm_core::cpu::RowForm]
    Source: 'crates/leanvm_core/src/cpu/mod.rs', lines 363:0-367:1 -/
axiom cpu.RowForm : Type

/-- [leanvm_core::cpu::Stats]
    Source: 'crates/leanvm_core/src/cpu/mod.rs', lines 473:0-485:1
    Visibility: public -/
axiom cpu.Stats : Type

/-- [leanvm_core::leaf::ColumnClaim]
    Source: 'crates/leanvm_core/src/leaf.rs', lines 104:0-108:1
    Visibility: public -/
axiom leaf.ColumnClaim : Type

/-- [leanvm_core::cpu::trace::Rows]
    Source: 'crates/leanvm_core/src/cpu/trace.rs', lines 60:0-63:1 -/
axiom cpu.trace.Rows (T : Type _) : Type

/-- [leanvm_core::cpu::trace::Trace]
    Source: 'crates/leanvm_core/src/cpu/trace.rs', lines 100:0-110:1 -/
axiom cpu.trace.Trace : Type

/-- [leanvm_core::leaf::Coord]
    Source: 'crates/leanvm_core/src/leaf.rs', lines 21:0-48:1
    Visibility: public -/
axiom leaf.Coord : Type

/-- [leanvm_core::tables::FillCtx]
    Source: 'crates/leanvm_core/src/tables.rs', lines 188:0-201:1
    Visibility: public -/
axiom tables.FillCtx : Type

end leanvm_core
