-- [stable_lean_vm_core]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import LeanVmCore.Extraction.Types
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

/-- [stable_lean_vm_core::cpu::execute::{impl core::clone::Clone for stable_lean_vm_core::cpu::execute::ExecError}::clone]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/execute.rs', lines 94:9-94:14
    Visibility: public -/
axiom cpu.execute.ExecError.Insts.CoreCloneClone.clone
  : cpu.execute.ExecError → RustM cpu.execute.ExecError

/-- [stable_lean_vm_core::cpu::execute::{impl core::cmp::PartialEq<stable_lean_vm_core::cpu::execute::ExecError> for stable_lean_vm_core::cpu::execute::ExecError}::eq]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/execute.rs', lines 94:23-94:32
    Visibility: public -/
axiom cpu.execute.ExecError.Insts.CoreCmpPartialEqExecError.eq
  : cpu.execute.ExecError → cpu.execute.ExecError → RustM Bool

/-- [stable_lean_vm_core::cpu::hints::{stable_lean_vm_core::cpu::hints::GPow}::new]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 70:4-78:5
    Visibility: public -/
axiom cpu.hints.GPow.new : Std.Usize → RustM cpu.hints.GPow

/-- [stable_lean_vm_core::cpu::hints::{stable_lean_vm_core::cpu::hints::GPow}::pow]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 82:4-84:5
    Visibility: public -/
axiom cpu.hints.GPow.pow
  : cpu.hints.GPow → Std.Usize → RustM stable_primitives.field.gf2_64.F64

/-- [stable_lean_vm_core::cpu::hints::{stable_lean_vm_core::cpu::hints::GPow}::grow_to]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 87:4-100:5
    Visibility: public -/
axiom cpu.hints.GPow.grow_to
  : cpu.hints.GPow → Std.Usize → RustM cpu.hints.GPow

/-- [stable_lean_vm_core::cpu::hints::{stable_lean_vm_core::cpu::hints::GPow}::note]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 104:4-107:5
    Visibility: public -/
axiom cpu.hints.GPow.note
  : cpu.hints.GPow → Std.Usize → RustM cpu.hints.GPow

/-- [stable_lean_vm_core::cpu::hints::{stable_lean_vm_core::cpu::hints::GPow}::log_below]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 115:4-127:5 -/
axiom cpu.hints.GPow.log_below
  :
  cpu.hints.GPow → stable_primitives.field.gf2_64.F64 → Std.Usize → RustM
    ((core.option.Option Std.U32) × cpu.hints.GPow)

/-- [stable_lean_vm_core::cpu::hints::{stable_lean_vm_core::cpu::hints::GPow}::lookup]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 130:4-132:5 -/
axiom cpu.hints.GPow.lookup
  :
  cpu.hints.GPow → stable_primitives.field.gf2_64.F64 → RustM
    (core.option.Option Std.U32)

/-- [stable_lean_vm_core::cpu::hints::{stable_lean_vm_core::cpu::hints::GPow}::resolve]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 137:4-146:5 -/
axiom cpu.hints.GPow.resolve
  :
  cpu.hints.GPow → stable_primitives.field.gf2_64.F64 → RustM
    (core.option.Option Std.Usize)

/-- [stable_lean_vm_core::cpu::hints::bounded_dlog]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/hints.rs', lines 152:0-177:1 -/
axiom cpu.hints.bounded_dlog
  :
  stable_primitives.field.gf2_64.F64 → Std.U32 → RustM (core.option.Option
    Std.U128)

/-- [stable_lean_vm_core::cpu::announce_public]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 30:0-36:1 -/
axiom cpu.announce_public
  :
  fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool →
    Std.Usize → Array Std.Usize 6#usize → Std.Usize → RustM
    (fiat_shamir_prover.transcript.ProverState
    stable_primitives.field.gf2_64x2.F128 stable_primitives.transcript.Pool)

/-- [stable_lean_vm_core::cpu::{impl core::fmt::Debug for stable_lean_vm_core::cpu::ProveError}::fmt]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 41:16-41:21
    Visibility: public -/
axiom cpu.ProveError.Insts.CoreFmtDebug.fmt
  :
  cpu.ProveError → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [stable_lean_vm_core::cpu::{impl core::fmt::Display for stable_lean_vm_core::cpu::ProveError}::fmt]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 57:4-75:5
    Visibility: public -/
axiom cpu.ProveError.Insts.CoreFmtDisplay.fmt
  :
  cpu.ProveError → core.fmt.Formatter → RustM ((core.result.Result Unit
    core.fmt.Error) × core.fmt.Formatter)

/-- [stable_lean_vm_core::cpu::airs]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 83:0-106:1 -/
axiom cpu.airs
  :
  Array Std.Usize 6#usize → leaf.BusProof → Slice (Slice
    stable_primitives.field.gf2_64.F64) →
    stable_primitives.field.gf2_64x2.F128 → RustM (alloc.vec.Vec
    constraints.Air)

/-- [stable_lean_vm_core::cpu::xi_form_base]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 111:0-113:1
    Visibility: public -/
axiom cpu.xi_form_base : RustM Std.Usize

/-- [stable_lean_vm_core::cpu::keccak_output_claim]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 122:0-128:1 -/
axiom cpu.keccak_output_claim
  : Slice constraints.Claims → RustM stable_keccak_gkr.OutputClaim

/-- [stable_lean_vm_core::cpu::prove]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 133:0-212:1
    Visibility: public -/
axiom cpu.prove
  :
  isa.program.Program → Slice (alloc.string.String × (alloc.vec.Vec
    (alloc.vec.Vec stable_primitives.field.gf2_64x2.F128))) → Array
    stable_primitives.field.gf2_64x2.F128 2#usize → Std.Usize → RustM
    (core.result.Result (verifier.transcript.Proof × isa.prover.Stats)
    cpu.ProveError)

/-- [stable_lean_vm_core::cpu::finish_claims]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 220:0-238:1 -/
axiom cpu.finish_claims
  :
  cpu.layout.Layout → alloc.vec.Vec leaf.ColumnClaim → Slice
    constraints.Claims → stable_primitives.field.gf2_64x2.F128 → RustM
    (alloc.vec.Vec stable_pcs.stack_open.StackClaim)

/-- [stable_lean_vm_core::cpu::pi_point]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 244:0-248:1 -/
axiom cpu.pi_point
  :
  stable_primitives.field.gf2_64x2.F128 → cpu.layout.Layout → RustM
    (alloc.vec.Vec stable_primitives.field.gf2_64x2.F128)

/-- [stable_lean_vm_core::cpu::public_input_bytes]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 260:0-262:1
    Visibility: public -/
axiom cpu.public_input_bytes
  :
  Array stable_primitives.field.gf2_64x2.F128 2#usize → RustM (Array Std.U8
    32#usize)

/-- [stable_lean_vm_core::cpu::verify]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 266:0-272:1
    Visibility: public -/
axiom cpu.verify
  :
  isa.program.Program → Array stable_primitives.field.gf2_64x2.F128 2#usize
    → verifier.transcript.Proof → RustM (core.result.Result
    verifier.Summary verifier.VerifierError)

/-- [stable_lean_vm_core::cpu::slot_claim]:
    Source: 'crates/stable_prover/lean_vm_core/src/cpu/mod.rs', lines 280:0-289:1 -/
axiom cpu.slot_claim
  :
  cpu.layout.Layout → Std.Usize → alloc.vec.Vec
    stable_primitives.field.gf2_64x2.F128 → RustM
    stable_pcs.stack_open.StackClaim

/-- [stable_lean_vm_core::eq::eq_sums]:
    Source: 'crates/stable_prover/lean_vm_core/src/eq.rs', lines 46:0-73:1 -/
axiom eq.eq_sums
  :
  Slice stable_primitives.field.gf2_64x2.F128 → Slice ((Slice
    stable_primitives.field.gf2_64.F64) × (core.option.Option (Slice
    stable_primitives.field.gf2_64.F64))) → RustM (alloc.vec.Vec
    stable_primitives.field.gf2_64x2.F128)

/-- [stable_lean_vm_core::filled]:
    Source: 'crates/stable_prover/lean_vm_core/src/lib.rs', lines 54:0-60:1 -/
axiom filled
  {T : Type _} (coremarkerCopyInst : core.marker.Copy T) :
  Std.Usize → T → RustM (alloc.vec.Vec T)

/-- [stable_lean_vm_core::prover::{impl isa::prover::Prover for stable_lean_vm_core::prover::StableProver}::dot_rows]:
    Source: 'crates/stable_prover/lean_vm_core/src/prover.rs', lines 63:4-75:5
    Visibility: public -/
axiom prover.StableProver.Insts.IsaProverProver.dot_rows
  :
  Slice Std.U64 → Slice verifier.field.E → RustM (alloc.vec.Vec
    verifier.field.E)

/-- [stable_lean_vm_core::prover::{impl isa::prover::Prover for stable_lean_vm_core::prover::StableProver}::combine_rows]:
    Source: 'crates/stable_prover/lean_vm_core/src/prover.rs', lines 43:4-61:5
    Visibility: public -/
axiom prover.StableProver.Insts.IsaProverProver.combine_rows
  :
  Slice Std.U64 → Slice verifier.field.E → RustM (alloc.vec.Vec
    verifier.field.E)

/-- [stable_lean_vm_core::prover::{impl isa::prover::Prover for stable_lean_vm_core::prover::StableProver}::prove]:
    Source: 'crates/stable_prover/lean_vm_core/src/prover.rs', lines 21:4-37:5
    Visibility: public -/
axiom prover.StableProver.Insts.IsaProverProver.prove
  :
  isa.program.Program → Slice (alloc.string.String × (alloc.vec.Vec
    (alloc.vec.Vec verifier.field.E))) → Array verifier.field.E 2#usize →
    Std.Usize → RustM (core.result.Result (verifier.transcript.Proof ×
    isa.prover.Stats) alloc.string.String)

/-- [stable_lean_vm_core::prover::{impl isa::prover::Prover for stable_lean_vm_core::prover::StableProver}::set_num_threads]:
    Source: 'crates/stable_prover/lean_vm_core/src/prover.rs', lines 17:4-19:5
    Visibility: public -/
axiom prover.StableProver.Insts.IsaProverProver.set_num_threads
  : Std.Usize → RustM Unit

end stable_lean_vm_core
