-- [rec_aggregation]: the items it uses from other workspace crates, as axioms.
-- Aeneas emits declarations only for the crate's own opaque items, so these are written by
-- hand, each with the type the generated code expects. A struct whose fields the generated
-- code reads mirrors the Rust definition instead.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

/-! ## `primitives` -/

/-- `primitives::field::gf2_64::F64(u64)`, a GF(2^64) element: Aeneas represents a struct of one
field as that field. -/
def primitives.field.gf2_64.F64 := Std.U64

/-- `primitives::field::gf2_64x3::F192`: `c0 + c1*y + c2*y^2` (gf2_64x3.rs). -/
structure primitives.field.gf2_64x3.F192 where
  c0 : Std.U64
  c1 : Std.U64
  c2 : Std.U64

/-- `F192::ZERO`. -/
axiom primitives.field.gf2_64x3.F192.ZERO : RustM primitives.field.gf2_64x3.F192

/-- `F192::new`. -/
axiom primitives.field.gf2_64x3.F192.new :
  Std.U64 → Std.U64 → Std.U64 → RustM primitives.field.gf2_64x3.F192

/-- `F192::mul_base`, the product by a base-field element. -/
axiom primitives.field.gf2_64x3.F192.mul_base :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64.F64 →
    RustM primitives.field.gf2_64x3.F192

/-- `impl Clone for F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreCloneClone.clone :
  primitives.field.gf2_64x3.F192 → RustM primitives.field.gf2_64x3.F192

/-- `impl Clone for F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreCloneClone :
  core.clone.Clone primitives.field.gf2_64x3.F192

/-- `impl PartialEq for F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192.eq :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 → RustM Bool

/-- `impl PartialEq for F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreCmpPartialEqF192 :
  core.cmp.PartialEq primitives.field.gf2_64x3.F192 primitives.field.gf2_64x3.F192

/-- `impl From<F64> for F192`, the base field's embedding. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreConvertFromF64.from :
  primitives.field.gf2_64.F64 → RustM primitives.field.gf2_64x3.F192

/-- `impl Add for F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreOpsArithAddF192F192.add :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 →
    RustM primitives.field.gf2_64x3.F192

/-- `impl Mul for F192`. -/
axiom primitives.field.gf2_64x3.F192.Insts.CoreOpsArithMulF192F192.mul :
  primitives.field.gf2_64x3.F192 → primitives.field.gf2_64x3.F192 →
    RustM primitives.field.gf2_64x3.F192

/-- `primitives::field::g_pow`, a power of the multiplicative generator. -/
axiom primitives.field.g_pow : Std.Usize → RustM primitives.field.gf2_64.F64

/-- `primitives::hash::hash`, Keccak-256. -/
axiom primitives.hash.hash : Slice Std.U8 → RustM (Array Std.U8 32#usize)

/-- `primitives::hash::RATE`. -/
axiom primitives.hash.RATE : RustM Std.Usize

/-! ## `fiat_shamir` -/

/-- `fiat_shamir::FiatShamirState`, the duplex sponge. -/
axiom fiat_shamir.FiatShamirState : Type

/-- `FiatShamirState::observe`. -/
axiom fiat_shamir.FiatShamirState.observe :
  fiat_shamir.FiatShamirState → primitives.field.gf2_64x3.F192 →
    RustM fiat_shamir.FiatShamirState

/-- `FiatShamirState::sample`. -/
axiom fiat_shamir.FiatShamirState.sample :
  fiat_shamir.FiatShamirState →
    RustM (primitives.field.gf2_64x3.F192 × fiat_shamir.FiatShamirState)

/-- `fiat_shamir::transcript::Proof`, a proof's wire form. -/
axiom fiat_shamir.transcript.Proof : Type

/-- `impl Clone for Proof`. -/
axiom fiat_shamir.transcript.Proof.Insts.CoreCloneClone.clone :
  fiat_shamir.transcript.Proof → RustM fiat_shamir.transcript.Proof

/-! ## `verifier` -/

/-- `verifier::VerifierError`. -/
axiom verifier.VerifierError : Type

/-- `impl Clone for VerifierError`. -/
axiom verifier.VerifierError.Insts.CoreCloneClone.clone :
  verifier.VerifierError → RustM verifier.VerifierError

/-- `impl PartialEq for VerifierError`. -/
axiom verifier.VerifierError.Insts.CoreCmpPartialEqVerifierError.eq :
  verifier.VerifierError → verifier.VerifierError → RustM Bool

/-- `verifier::Summary`, what a replay of a proof reads out. -/
axiom verifier.Summary : Type

/-- `verifier::bytecode::Bytecode`, the hashed bytecode table. -/
axiom verifier.bytecode.Bytecode : Type

/-- `verifier::transcript::Proof`, a proof as the verifier reads it. -/
axiom verifier.transcript.Proof : Type

/-- `verifier::verify_execution`, the native verifier. -/
axiom verifier.verify_execution :
  verifier.bytecode.Bytecode → Array Std.U8 32#usize → verifier.transcript.Proof →
    RustM (core.result.Result verifier.Summary verifier.VerifierError)

/-- `verifier::da::list_digest`, the digest of a DA root list. -/
axiom verifier.da.list_digest : Slice (Array Std.U8 32#usize) → RustM (Array Std.U8 32#usize)

/-! ## `pcs` -/

/-- `pcs::whir_config::ProverConfig`. -/
axiom pcs.whir_config.ProverConfig : Type

/-- `pcs::whir_config::LevelShapes`. -/
axiom pcs.whir_config.LevelShapes : Type

/-! ## `leanvm_core` -/

/-- `leanvm_core::cpu::Program`. -/
axiom leanvm_core.cpu.Program : Type

/-- `leanvm_core::cpu::Stats`. -/
axiom leanvm_core.cpu.Stats : Type

/-- `leanvm_core::cpu::layout::Layout`. -/
axiom leanvm_core.cpu.layout.Layout : Type

/-- `leanvm_core::cpu::ProveError`. -/
axiom leanvm_core.cpu.ProveError : Type

/-- `impl Clone for ProveError`. -/
axiom leanvm_core.cpu.ProveError.Insts.CoreCloneClone.clone :
  leanvm_core.cpu.ProveError → RustM leanvm_core.cpu.ProveError

/-- `impl PartialEq for ProveError`. -/
axiom leanvm_core.cpu.ProveError.Insts.CoreCmpPartialEqProveError.eq :
  leanvm_core.cpu.ProveError → leanvm_core.cpu.ProveError → RustM Bool

/-- `impl Error for ProveError`. -/
axiom leanvm_core.cpu.ProveError.Insts.CoreErrorError : core.error.Error leanvm_core.cpu.ProveError

/-- `leanvm_core::cpu::scalar_proof`, a wire proof in the verifier's form. -/
axiom leanvm_core.cpu.scalar_proof : fiat_shamir.transcript.Proof → RustM verifier.transcript.Proof

/-- `leanvm_core::cpu::public_input_bytes`, the public input as the verifier takes it. -/
axiom leanvm_core.cpu.public_input_bytes :
  Array primitives.field.gf2_64x3.F192 2#usize → RustM (Array Std.U8 32#usize)

/-- `leanvm_core::cpu::fs_seed`, the Fiat-Shamir seed of a program. -/
axiom leanvm_core.cpu.fs_seed :
  leanvm_core.cpu.Program → RustM (Array primitives.field.gf2_64x3.F192 2#usize)

/-- `Program::set_witness`. -/
axiom leanvm_core.cpu.Program.set_witness {S : Type}
  (IntoInst : core.convert.Into S alloc.string.String) :
  leanvm_core.cpu.Program → S → alloc.vec.Vec (alloc.vec.Vec primitives.field.gf2_64x3.F192) →
    RustM leanvm_core.cpu.Program

/-- `leanvm_core::leaf::Coord`, one tuple coordinate. -/
axiom leanvm_core.leaf.Coord : Type

/-- `leanvm_core::leaf::N_TUPLE_BITS`. -/
axiom leanvm_core.leaf.N_TUPLE_BITS : RustM Std.Usize

/-- `leanvm_core::leaf::N_BYTECODE_SELECTORS`. -/
axiom leanvm_core.leaf.N_BYTECODE_SELECTORS : RustM Std.Usize

/-- `leanvm_core::pcs::MIN_MU`. -/
axiom leanvm_core.pcs.MIN_MU : RustM Std.Usize

/-- `leanvm_core::pcs::MAX_MU`. -/
axiom leanvm_core.pcs.MAX_MU : RustM Std.Usize

/-! ## `lean_da` -/

/-- `lean_da::membership::membership_vector`. -/
axiom lean_da.membership.membership_vector :
  Array Std.U8 32#usize → RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192)

/-- `lean_da::membership::vector_digest`. -/
axiom lean_da.membership.vector_digest :
  Slice primitives.field.gf2_64x3.F192 → RustM (Array Std.U8 32#usize)

/-! ## `signatures` -/

/-- `signatures::lean_xmss::scheme::LeanXmssPublicKey`. -/
axiom signatures.lean_xmss.scheme.LeanXmssPublicKey : Type

/-- `LeanXmssPublicKey::flatten`, its 32 bytes. -/
axiom signatures.lean_xmss.scheme.LeanXmssPublicKey.flatten :
  signatures.lean_xmss.scheme.LeanXmssPublicKey → RustM (Array Std.U8 32#usize)

/-- `impl PartialEq for LeanXmssPublicKey`. -/
axiom signatures.lean_xmss.scheme.LeanXmssPublicKey.Insts.CoreCmpPartialEqLeanXmssPublicKey :
  core.cmp.PartialEq signatures.lean_xmss.scheme.LeanXmssPublicKey
    signatures.lean_xmss.scheme.LeanXmssPublicKey

/-- `impl PartialOrd for LeanXmssPublicKey`. -/
axiom signatures.lean_xmss.scheme.LeanXmssPublicKey.Insts.CoreCmpPartialOrdLeanXmssPublicKey :
  core.cmp.PartialOrd signatures.lean_xmss.scheme.LeanXmssPublicKey
    signatures.lean_xmss.scheme.LeanXmssPublicKey

/-- `impl Ord for LeanXmssPublicKey`. -/
axiom signatures.lean_xmss.scheme.LeanXmssPublicKey.Insts.CoreCmpOrd :
  core.cmp.Ord signatures.lean_xmss.scheme.LeanXmssPublicKey

/-- `signatures::lean_xmss::scheme::LeanXmssSignature`. -/
axiom signatures.lean_xmss.scheme.LeanXmssSignature : Type

/-- `signatures::lean_sphincs::scheme::LeanSphincsPublicKey`. -/
axiom signatures.lean_sphincs.scheme.LeanSphincsPublicKey : Type

/-- `LeanSphincsPublicKey::flatten`, its 32 bytes. -/
axiom signatures.lean_sphincs.scheme.LeanSphincsPublicKey.flatten :
  signatures.lean_sphincs.scheme.LeanSphincsPublicKey → RustM (Array Std.U8 32#usize)

/-- `impl PartialEq for LeanSphincsPublicKey`. -/
axiom signatures.lean_sphincs.scheme.LeanSphincsPublicKey.Insts.CoreCmpPartialEqLeanSphincsPublicKey :
  core.cmp.PartialEq signatures.lean_sphincs.scheme.LeanSphincsPublicKey
    signatures.lean_sphincs.scheme.LeanSphincsPublicKey

/-- `impl PartialOrd for LeanSphincsPublicKey`. -/
axiom signatures.lean_sphincs.scheme.LeanSphincsPublicKey.Insts.CoreCmpPartialOrdLeanSphincsPublicKey :
  core.cmp.PartialOrd signatures.lean_sphincs.scheme.LeanSphincsPublicKey
    signatures.lean_sphincs.scheme.LeanSphincsPublicKey

/-- `impl Ord for LeanSphincsPublicKey`. -/
axiom signatures.lean_sphincs.scheme.LeanSphincsPublicKey.Insts.CoreCmpOrd :
  core.cmp.Ord signatures.lean_sphincs.scheme.LeanSphincsPublicKey

/-- `signatures::lean_sphincs::scheme::LeanSphincsSignature`. -/
axiom signatures.lean_sphincs.scheme.LeanSphincsSignature : Type

/-- `signatures::tweak::N`. -/
axiom signatures.tweak.N : RustM Std.Usize

/-- `signatures::lean_xmss::W`. -/
axiom signatures.lean_xmss.W : RustM Std.Usize

/-- `signatures::lean_xmss::V`. -/
axiom signatures.lean_xmss.V : RustM Std.Usize

/-- `signatures::lean_xmss::CHAIN_LEN`. -/
axiom signatures.lean_xmss.CHAIN_LEN : RustM Std.Usize

/-- `signatures::lean_xmss::LOG_LIFETIME`. -/
axiom signatures.lean_xmss.LOG_LIFETIME : RustM Std.Usize

/-- `signatures::lean_sphincs::W`. -/
axiom signatures.lean_sphincs.W : RustM Std.Usize

/-- `signatures::lean_sphincs::V`. -/
axiom signatures.lean_sphincs.V : RustM Std.Usize

/-- `signatures::lean_sphincs::H`. -/
axiom signatures.lean_sphincs.H : RustM Std.Usize

/-- `signatures::lean_sphincs::COUNTER_LEN`. -/
axiom signatures.lean_sphincs.COUNTER_LEN : RustM Std.Usize

/-- `signatures::lean_sphincs::DIGEST_BITS`. -/
axiom signatures.lean_sphincs.DIGEST_BITS : RustM Std.Usize

/-- `signatures::lean_sphincs::DIGEST_WORD_BYTES`. -/
axiom signatures.lean_sphincs.DIGEST_WORD_BYTES : RustM Std.Usize

/-- `signatures::lean_sphincs::FOREST_CHAINS`. -/
axiom signatures.lean_sphincs.FOREST_CHAINS : RustM Std.Usize

/-- `signatures::lean_sphincs::FOREST_TREES`. -/
axiom signatures.lean_sphincs.FOREST_TREES : RustM Std.Usize

/-- `signatures::lean_sphincs::SUBTREES`. -/
axiom signatures.lean_sphincs.SUBTREES : RustM Std.Usize

/-- `signatures::lean_sphincs::SUBTREE_HEIGHT`. -/
axiom signatures.lean_sphincs.SUBTREE_HEIGHT : RustM Std.Usize

/-- `signatures::lean_sphincs::TREE_HEIGHT`. -/
axiom signatures.lean_sphincs.TREE_HEIGHT : RustM Std.Usize
