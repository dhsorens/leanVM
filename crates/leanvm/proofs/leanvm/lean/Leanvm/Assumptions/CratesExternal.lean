-- [leanvm]: the items it uses from other workspace crates, as axioms. Aeneas emits
-- declarations only for the crate's own opaque items, so these are written by hand.
module
public import Aeneas
public import CoreModels
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

/-- `leanvm_core::init_prover`, the prover's one-time setup. -/
axiom leanvm_core.init_prover : RustM Unit

/-- `rec_aggregation::warm_up`, which builds the aggregation guest and its tables once. -/
axiom rec_aggregation.aggregation.warm_up : RustM Unit
