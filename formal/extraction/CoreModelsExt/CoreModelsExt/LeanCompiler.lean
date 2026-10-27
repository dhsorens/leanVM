-- Models first needed by crates/lean_compiler, of Rust standard library items the pinned
-- hax-lean CoreModels lacks. Each is a candidate for upstreaming there. A `def` mirrors the
-- Rust semantics; an `opaque` is an assumption about an item whose body is not modelled.
module
public import Aeneas
public import CoreModels
public import CoreModelsExt.Verifier
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

namespace CoreModels

/-! Dictionaries exist at every type: the witnesses `opaque` needs, nothing more. -/

local instance {X : Type} : Inhabited (core.hash.Hash X) := ⟨{ hash := fun _ _ h => ok h }⟩

local instance {X Y : Type} : Inhabited (core.borrow.Borrow X Y) := ⟨{ borrow := fun _ => default }⟩

local instance {X : Type} : Inhabited (core.default.Default X) := ⟨{ default := default }⟩

local instance {X Y : Type} : Inhabited (core.convert.From X Y) := ⟨{ «from» := fun _ => default }⟩

/-! ## Scalars, `bool`, `Option` -/

/-- `&u32 + u32`, failing on overflow as `u32 + u32` does. -/
def core.U32.Insts.CoreOpsArithAddShared0U32U32.add (self rhs : Std.U32) : RustM Std.U32 :=
  self + rhs

/-- `bool::then_some`: `if self { Some(t) } else { None }`. -/
def core.bool.Bool.then_some {T : Type} (self : Bool) (t : T) : RustM (core.option.Option T) :=
  ok (if self then .Some t else .None)

/-- `Option<&T>::copied`: references are erased, so the option itself. -/
def core.option.OptionShared0T.copied {T : Type} (_ : core.marker.Copy T)
    (self : core.option.Option T) : RustM (core.option.Option T) :=
  ok self

/-! ## Strings -/

/-- `String::clone`. -/
def alloc.string.String.Insts.CoreCloneClone.clone (self : alloc.string.String) :
    RustM alloc.string.String :=
  ok self

/-- `String: Clone`. -/
@[reducible]
def alloc.string.String.Insts.CoreCloneClone : core.clone.Clone alloc.string.String where
  clone := alloc.string.String.Insts.CoreCloneClone.clone
  clone_from := fun _ s => ok s

/-- `String: Eq`, by characters. -/
def alloc.string.String.Insts.CoreCmpEq : core.cmp.Eq alloc.string.String where
  PartialEqInst :=
    { eq := fun a b => ok (@decide _ (instDecidableEqString a b))
      ne := fun a b => ok !(@decide _ (instDecidableEqString a b)) }

/-- `str: Eq`, by bytes. -/
def core.Str.Insts.CoreCmpEq : core.cmp.Eq Str where
  PartialEqInst := { eq := fun a b => ok (a.val == b.val), ne := fun a b => ok (a.val != b.val) }

/-- `String: From<&str>`, the UTF-8 decoding of the bytes. -/
opaque alloc.string.String.Insts.CoreConvertFromShared0Str : core.convert.From alloc.string.String Str

/-! ## Hashing -/

/-- `core::hash::BuildHasher`, a dictionary whose methods are not modelled: the hashed
collections' operations that would call them are opaque. -/
structure core.hash.BuildHasher (Self : Type) where

/-- `Hash` for `String`, its bytes then `0xff`. -/
opaque alloc.string.String.Insts.CoreHashHash : core.hash.Hash alloc.string.String

/-- `Hash` for `str`, its bytes then `0xff`. -/
opaque core.Str.Insts.CoreHashHash : core.hash.Hash Str

/-- `String: Borrow<str>`, `String::as_str`, its UTF-8 encoding. -/
opaque alloc.string.String.Insts.CoreBorrowBorrowStr : core.borrow.Borrow alloc.string.String Str

/-- The blanket `T: Borrow<T>`, the identity. -/
def core.borrow.Borrow.Blanket (T : Type) : core.borrow.Borrow T T where
  borrow := fun x => ok x

/-! ## `HashMap`, `HashSet`

A hashed map and set, assumed: the types and the operations the extraction calls are opaque. -/

/-- `std::hash::RandomState`, the default hasher builder. -/
opaque std.hash.random.RandomState : Type

/-- `RandomState: Default`, freshly seeded keys. -/
opaque std.hash.random.RandomState.Insts.CoreDefaultDefault :
  core.default.Default std.hash.random.RandomState

/-- `RandomState: Clone`. -/
def std.hash.random.RandomState.Insts.CoreCloneClone : core.clone.Clone std.hash.random.RandomState where
  clone := fun s => ok s
  clone_from := fun _ s => ok s

/-- `RandomState: BuildHasher<Hasher = DefaultHasher>`. -/
def std.hash.random.RandomState.Insts.CoreHashBuildHasherDefaultHasher :
  core.hash.BuildHasher std.hash.random.RandomState := {}

opaque std.collections.hash.map.HashMap (K V S A : Type) : Type

opaque std.collections.hash.set.HashSet (T S A : Type) : Type

/-- `HashMap::default`, the empty map. -/
opaque std.collections.hash.map.HashMapKVSGlobal.Insts.CoreDefaultDefault.default {S : Type}
    (K V : Type) (DefaultS : core.default.Default S) :
    RustM (std.collections.hash.map.HashMap K V S alloc.alloc.Global)

/-- `HashMap: Clone`, entry by entry. -/
opaque std.collections.hash.map.HashMap.Insts.CoreCloneClone.clone {K V S A : Type}
    (CloneK : core.clone.Clone K) (CloneV : core.clone.Clone V) (CloneS : core.clone.Clone S)
    (CloneA : core.clone.Clone A) (self : std.collections.hash.map.HashMap K V S A) :
    RustM (std.collections.hash.map.HashMap K V S A)

/-- `HashMap::get`: the value at a key, if any. -/
opaque std.collections.hash.map.HashMap.get {K V S Q : Type} (EqK : core.cmp.Eq K)
    (HashK : core.hash.Hash K) (BuildS : core.hash.BuildHasher S) (BorrowKQ : core.borrow.Borrow K Q)
    (HashQ : core.hash.Hash Q) (EqQ : core.cmp.Eq Q)
    (self : std.collections.hash.map.HashMap K V S alloc.alloc.Global) (k : Q) :
    RustM (core.option.Option V)

/-- `HashMap::get_mut`: the value at a key, if any, and the map with it written back. -/
opaque std.collections.hash.map.HashMap.get_mut {K V S Q : Type} (EqK : core.cmp.Eq K)
    (HashK : core.hash.Hash K) (BuildS : core.hash.BuildHasher S) (BorrowKQ : core.borrow.Borrow K Q)
    (HashQ : core.hash.Hash Q) (EqQ : core.cmp.Eq Q)
    (self : std.collections.hash.map.HashMap K V S alloc.alloc.Global) (k : Q) :
    RustM (core.option.Option V ×
      (core.option.Option V → std.collections.hash.map.HashMap K V S alloc.alloc.Global))

/-- `map[k]`: the value at a key, panicking when it is absent. -/
opaque std.collections.hash.map.HashMap.Insts.CoreOpsIndexIndexShared0QV.index {K V S Q : Type}
    (EqK : core.cmp.Eq K) (HashK : core.hash.Hash K) (BorrowKQ : core.borrow.Borrow K Q)
    (EqQ : core.cmp.Eq Q) (HashQ : core.hash.Hash Q) (BuildS : core.hash.BuildHasher S)
    (self : std.collections.hash.map.HashMap K V S alloc.alloc.Global) (k : Q) : RustM V

/-! ## `BTreeMap` -/

/-- `BTreeMap::new`, the empty map. -/
opaque alloc.collections.btree.map.BTreeMapKVGlobal.new (K V : Type) :
    RustM (alloc.collections.btree.map.BTreeMap K V alloc.alloc.Global)

end CoreModels
