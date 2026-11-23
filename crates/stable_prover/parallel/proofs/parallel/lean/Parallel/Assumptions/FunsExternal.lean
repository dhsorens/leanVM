-- [stable_parallel]: external functions.
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

namespace stable_parallel

/-- [stable_parallel::init]:
    Source: 'crates/stable_prover/parallel/src/lib.rs', lines 91:0-94:1
    Visibility: public -/
axiom init : RustM Unit

/-- [stable_parallel::chunks_mut]:
    Source: 'crates/stable_prover/parallel/src/lib.rs', lines 304:0-311:1
    Visibility: public -/
axiom chunks_mut
  {T : Type _} {F : Type _} (coreopsfunctionFnFPairUsizeMut0SliceTupleInst :
  core.ops.function.Fn F (Std.Usize × (Slice T)) Unit) :
  Slice T → Std.Usize → F → RustM (Slice T)

/-- [stable_parallel::map_collect]:
    Source: 'crates/stable_prover/parallel/src/lib.rs', lines 407:0-420:1
    Visibility: public -/
axiom map_collect
  {T : Type _} {F : Type _} (coreopsfunctionFnFTupleUsizeTInst :
  core.ops.function.Fn F Std.Usize T) :
  Std.Usize → F → RustM (alloc.vec.Vec T)

/-- [stable_parallel::find_first]:
    Source: 'crates/stable_prover/parallel/src/lib.rs', lines 428:0-443:1
    Visibility: public -/
axiom find_first
  {P : Type _} (coreopsfunctionFnPTupleUsizeBoolInst : core.ops.function.Fn P
  Std.Usize Bool) :
  Std.Usize → P → RustM (core.option.Option Std.Usize)

/-- [stable_parallel::map_reduce]:
    Source: 'crates/stable_prover/parallel/src/lib.rs', lines 486:0-508:1
    Visibility: public -/
axiom map_reduce
  {T : Type _} {ID : Type _} {M : Type _} {R : Type _}
  (coreopsfunctionFnOnceIDTupleTInst : core.ops.function.FnOnce ID Unit T)
  (coreopsfunctionFnMTupleUsizeTInst : core.ops.function.Fn M Std.Usize T)
  (coreopsfunctionFnRPairTInst : core.ops.function.Fn R (T × T) T) :
  Std.Usize → ID → M → R → RustM T

end stable_parallel
