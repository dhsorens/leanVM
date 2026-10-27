-- [parallel]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
public import Parallel.Extraction.Types
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
namespace parallel

/-- [parallel::topology::topology]:
    Source: 'crates/parallel/src/topology.rs', lines 31:0-47:1
    Visibility: public -/
axiom topology.topology : RustM topology.Topology

/-- [parallel::init]:
    Source: 'crates/parallel/src/lib.rs', lines 112:0-118:1
    Visibility: public -/
axiom init : RustM Unit

/-- [parallel::chunks_mut]:
    Source: 'crates/parallel/src/lib.rs', lines 340:0-350:1
    Visibility: public -/
axiom chunks_mut
  {T : Type _} {F : Type _} (coreopsfunctionFnFPairUsizeMut0SliceTupleInst :
  core.ops.function.Fn F (Std.Usize × (Slice T)) Unit) :
  Slice T → Std.Usize → F → RustM (Slice T)

/-- [parallel::map_collect]:
    Source: 'crates/parallel/src/lib.rs', lines 450:0-463:1
    Visibility: public -/
-- hand-maintained: a model rather than an axiom, `[f(0), .., f(n_tasks - 1)]` computed in order.
def map_collect {T F : Type} (FnInst : core.ops.function.Fn F Std.Usize T)
    (n_tasks : Std.Usize) (f : F) : RustM (alloc.vec.Vec T) := do
  let empty ← alloc.vec.Vec.new T
  (List.range n_tasks.val).foldlM
    (fun out i => do
      let x ← FnInst.call f ⟨BitVec.ofNat _ i⟩
      alloc.vec.Vec.push out x)
    empty

/-- [parallel::find_first]:
    Source: 'crates/parallel/src/lib.rs', lines 471:0-486:1
    Visibility: public -/
-- hand-maintained: a model rather than an axiom, the least `i < n_tasks` with `pred(i)`, searched in order.
def find_first {P : Type} (FnInst : core.ops.function.Fn P Std.Usize Bool)
    (n_tasks : Std.Usize) (pred : P) : RustM (core.option.Option Std.Usize) :=
  (List.range n_tasks.val).foldlM
    (fun found i => match found with
      | .some _ => ok found
      | .none => do
        let hit ← FnInst.call pred ⟨BitVec.ofNat _ i⟩
        ok (if hit then .some ⟨BitVec.ofNat _ i⟩ else .none))
    .none

/-- [parallel::map_reduce]:
    Source: 'crates/parallel/src/lib.rs', lines 515:0-532:1
    Visibility: public -/
axiom map_reduce
  {T : Type _} {ID : Type _} {M : Type _} {R : Type _}
  (coreopsfunctionFnIDTupleTInst : core.ops.function.Fn ID Unit T)
  (coreopsfunctionFnMTupleUsizeTInst : core.ops.function.Fn M Std.Usize T)
  (coreopsfunctionFnRPairTInst : core.ops.function.Fn R (T × T) T) :
  Std.Usize → ID → M → R → RustM T

end parallel
