-- [lean_da]: external functions.
-- Seeded by hax from Extraction/FunsExternal_Template.lean: fill the holes.
-- hax never modifies this file; after re-extraction, compare it against the
-- regenerated template to see what changed.
module
public import Aeneas
public import CoreModels
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
open lean_da

-- Items of other workspace crates the extraction uses, which hax does not declare: written
-- here by hand, above the generated declarations (wire.py keeps this header as it is).

-- `primitives::hash::OUT_LEN`: a Keccak-256 digest's length, in bytes.
def primitives.hash.OUT_LEN : RustM Std.Usize := ok 32#usize

-- `primitives::hash::hash`, assumed: Keccak-256 (Ethereum's padding).
axiom primitives.hash.hash : Slice Std.U8 → RustM (Array Std.U8 32#usize)

-- `primitives::hash::hash_many(data, len, out)`, assumed: `out` holds the `hash` of each
-- `len`-byte input of `data`, in order; the result is `out` after the call.
axiom primitives.hash.hash_many : Slice Std.U8 → Std.Usize → Slice Std.U8 → RustM (Slice Std.U8)

-- `fiat_shamir::merkle::hash_pair`: `hash` of the 64 bytes `left | right`.
noncomputable def fiat_shamir.merkle.hash_pair (left right : Array Std.U8 32#usize) :
    RustM (Array Std.U8 32#usize) :=
  let buf := left.val ++ right.val
  if h : buf.length ≤ Usize.max then primitives.hash.hash (Slice.from buf h) else fail .panic

-- `fiat_shamir::merkle::hash_to_scalars`, assumed: a digest as two field words, each two
-- little-endian 64-bit halves and a zero.
axiom fiat_shamir.merkle.hash_to_scalars :
  Array Std.U8 32#usize → RustM (Array primitives.field.gf2_64x3.F192 2#usize)

-- `fiat_shamir::FiatShamirState::from_label`, assumed: the sponge seeded by a label.
axiom fiat_shamir.FiatShamirState.from_label : Slice Std.U8 → RustM fiat_shamir.FiatShamirState

-- `fiat_shamir::FiatShamirState::observe`, assumed: absorbs one field word.
axiom fiat_shamir.FiatShamirState.observe :
  fiat_shamir.FiatShamirState → primitives.field.gf2_64x3.F192 →
    RustM fiat_shamir.FiatShamirState

-- `fiat_shamir::FiatShamirState::sample_vec`, assumed: squeezes `n` field words.
axiom fiat_shamir.FiatShamirState.sample_vec :
  fiat_shamir.FiatShamirState → Std.Usize →
    RustM (alloc.vec.Vec primitives.field.gf2_64x3.F192 × fiat_shamir.FiatShamirState)

/-- [lean_da::commit::{impl core::fmt::Debug for lean_da::commit::DaCommitment}::fmt]:
    Source: 'crates/lean_da/src/commit.rs', lines 15:22-15:27
    Visibility: public -/
axiom commit.DaCommitment.Insts.CoreFmtDebug.fmt
  :
  commit.DaCommitment → core.fmt.Formatter → RustM ((core.result.Result
    Unit core.fmt.Error) × core.fmt.Formatter)

/-- [lean_da::encode::encode_rows]:
    Source: 'crates/lean_da/src/encode.rs', lines 18:0-35:1
    Visibility: public -/
axiom encode.encode_rows : Slice Std.U64 → RustM (alloc.vec.Vec Std.U64)

/-- [lean_da::commit::as_bytes]:
    Source: 'crates/lean_da/src/commit.rs', lines 147:0-151:1 -/
axiom commit.as_bytes : Slice Std.U64 → RustM (Slice Std.U8)

/-- [lean_da::membership::dual_codeword]:
    Source: 'crates/lean_da/src/membership.rs', lines 67:0-85:1
    Visibility: public -/
axiom membership.dual_codeword
  :
  Slice primitives.field.gf2_64x3.F192 → RustM (alloc.vec.Vec
    primitives.field.gf2_64x3.F192)

