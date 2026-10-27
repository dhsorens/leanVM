-- Models first needed by crates/signatures and crates/lean_da, of Rust standard library
-- items the pinned hax-lean CoreModels lacks. Each is a candidate for upstreaming there. A
-- `def` mirrors the Rust semantics; an `opaque` is an assumption about an item whose body
-- is not modelled.
module
public import Aeneas
public import CoreModels
@[expose] public section
open CoreModels Aeneas
open Aeneas.Std hiding namespace core alloc
open RustM ControlFlow Error

namespace CoreModels

/-! ## Integers -/

/-- `usize::next_power_of_two`: the least power of two at least `x` (`1` for `0`). Rust
panics on overflow in debug builds and returns `0` in release ones; this models the panic. -/
def core.num.Usize.next_power_of_two (x : Std.Usize) : RustM Std.Usize :=
  let p := (List.range (Usize.numBits + 1)).find? (fun i => x.val ≤ 2 ^ i)
  match p with
  | some i => if 2 ^ i ≤ Usize.max then ok ⟨BitVec.ofNat _ (2 ^ i)⟩ else fail .panic
  | none => fail .panic

/-! ## `bool`, ranges -/

/-- `bool::then_some`: `if self { Some(t) } else { None }`. -/
def core.bool.Bool.then_some {T : Type} (self : Bool) (t : T) : RustM (core.option.Option T) :=
  ok (if self then .Some t else .None)

/-- `Iterator::next` of `RangeInclusive`: `start` until it reaches `end`, then `end` once
more, setting `exhausted`; `None` once exhausted or when `start > end`. -/
def core.ops.range.RangeInclusive.Insts.CoreIterTraitsIteratorIterator.next {A : Type}
    (StepInst : core.iter.range.Step A) (self : core.ops.range.RangeInclusive A) :
    RustM (core.option.Option A × core.ops.range.RangeInclusive A) := do
  let nonempty ← StepInst.corecmpPartialOrdInst.le self.start_ self.end_
  if self.exhausted || !nonempty then ok (.None, self)
  else
    let before ← StepInst.corecmpPartialOrdInst.lt self.start_ self.end_
    let current ← StepInst.cloneCloneInst.clone self.start_
    if before then
      let next ← StepInst.forward_unchecked current 1#usize
      ok (.Some self.start_, { self with start_ := next })
    else ok (.Some current, { self with exhausted := true })

/-! ## Arrays and slices -/

/-- `<[[T; N]]>::as_flattened`: the arrays' elements in order. -/
def core.slice.SliceArray.as_flattened {T : Type} {N : Std.Usize} (self : Slice (Array T N)) :
    RustM (Slice T) :=
  let flat := (self.val.map Array.val).flatten
  if h : flat.length ≤ Usize.max then ok (Slice.from flat h) else fail .panic

/-- `<[[T; N]]>::as_flattened_mut`, assumed: the arrays' elements in order, and the back
function regrouping the flat slice into the arrays. -/
opaque core.slice.SliceArray.as_flattened_mut {T : Type} {N : Std.Usize}
    (self : Slice (Array T N)) : RustM (Slice T × (Slice T → Slice (Array T N)))

/-- `Ord::cmp` of `[T; N]`: lexicographic, the first unequal elements deciding. -/
def core.Array.Insts.CoreCmpOrd.cmp {T : Type} {N : Std.Usize} (OrdInst : core.cmp.Ord T)
    (self other : Array T N) : RustM core.cmp.Ordering :=
  (self.val.zip other.val).foldlM
    (fun order (x, y) => match order with
      | .Equal => OrdInst.cmp x y
      | _ => ok order)
    .Equal

/-! ## `Arc` and `Mutex` -/

/-- `Arc<T>`, as the value it shares: the extraction only reads through it. -/
def alloc.sync.Arc (T : Type) : Type := T

/-- `Deref` of `Arc`: the shared value. -/
def alloc.sync.Arc.Insts.CoreOpsDerefDeref.deref {T : Type} (self : alloc.sync.Arc T) :
    RustM T :=
  ok self

/-- `std::sync::Mutex<T>`, assumed: interior mutability has no value model here. -/
opaque std.sync.poison.mutex.Mutex (T : Type) : Type

/-- `Mutex::new`, assumed. -/
opaque std.sync.poison.mutex.Mutex.new {T : Type} (value : T) :
    RustM (std.sync.poison.mutex.Mutex T)

end CoreModels
