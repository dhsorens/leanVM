-- [stable_lean_vm_core]: external types.
-- Seeded by hax from Extraction/TypesExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import FiatShamirProver.Extraction
public import Isa.Extraction
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


namespace stable_lean_vm_core

/-- [stable_lean_vm_core::constraints::Claims]
    Source: 'crates/stable_prover/lean_vm_core/src/constraints.rs', lines 88:0-91:1 -/
axiom constraints.Claims : Type

/-- [stable_lean_vm_core::constraints::Air]
    Source: 'crates/stable_prover/lean_vm_core/src/constraints.rs', lines 94:0-100:1 -/
axiom constraints.Air : Type

/-- [stable_lean_vm_core::cpu::execute::ExecError]
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/execute.rs', lines 95:0-101:1
    Visibility: public -/
axiom cpu.execute.ExecError : Type

/-- [stable_lean_vm_core::cpu::hints::GPow]
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 28:0-34:1
    Visibility: public -/
axiom cpu.hints.GPow : Type

/-- [stable_lean_vm_core::cpu::layout::Layout]
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/layout.rs', lines 57:0-72:1
    Visibility: public -/
axiom cpu.layout.Layout : Type

/-- [stable_lean_vm_core::leaf::BusProof]
    Source: 'crates/stable_prover/lean_vm_core/src/leaf.rs', lines 110:0-115:1 -/
axiom leaf.BusProof : Type

/-- [stable_lean_vm_core::leaf::ColumnClaim]
    Source: 'crates/stable_prover/lean_vm_core/src/leaf.rs', lines 102:0-106:1 -/
axiom leaf.ColumnClaim : Type

end stable_lean_vm_core
