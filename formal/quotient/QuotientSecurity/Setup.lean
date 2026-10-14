import QuotientSecurity.PublicWeight
import QuotientSecurity.Distance

/-!
# The setting of the statements

Definitions only: everything `Statement.lean` mentions that is not a library notion. The circuit,
the relation, what a proof is, and the two experiments of zero knowledge.
-/

open OracleSpec OracleComp Polynomial

namespace QuotientSecurity

/-- **A circuit**: `2^20` rows of four cells, a cell being named by 22 bits. Its points are the
span of a Cantor basis, `wiring` says which cells must be equal, and `c k` is the weight that bit
`k < 8` of a cell's index gives it in a public word. The theorems hold for every circuit; they
are about `flock::quotient` when these are that circuit's, which Lean does not check. -/
structure Instance (F : Type) [Field F] [CharP F 2] where
  basis : CantorBasis F (20 + 2)
  wiring : Equiv.Perm (Fin (20 + 2) → Bool)
  c : ℕ → F

namespace Instance

variable {F : Type} [Field F] [DecidableEq F] [CharP F 2] (I : Instance F)

/-- The protocol's parameters on this circuit: the cells, the polynomials the verifier
evaluates, the public words. -/
noncomputable def params : Params F :=
  membershipParams I.basis le22 I.wiring (invSeq I.basis.β) I.c (invSeq_zero _)
    fun d hd _ => invSeq_sum I.basis.β I.basis.zero d hd

/-- The degrees a proof's polynomials may have: the sizes of the tables they are committed in. -/
noncomputable def bounds : I.params.Bounds :=
  membershipBounds I.basis le22 I.wiring (invSeq I.basis.β) I.c (invSeq_zero _)
    fun d hd _ => invSeq_sum I.basis.β I.basis.zero d hd

/-- **The relation**, on an assignment `w` of a field element to every cell. `cellBits (y, r)` is
the cell of row `y` with role `r` (`X`, `Y`, `C`, `V`).

1. Every row satisfies the gate: on elements of `GF(4)`, read as a bit and a carry, it says the
   `V` cell holds the sum bit and the carry out of the bits of `X`, `Y` and the carry of `C`.
2. Cells wired together are equal.
3. Each public word is the weighted sum of its cells: word `J` reads the cells whose bits 8 to
   10 spell `J` and whose bits from 11 on are zero.

The cells are arbitrary field elements: that they are bits is a consequence, for a wiring with
no loop (`AdderCircuit.determined`), not a hypothesis. -/
def Relation (stmt : Fin 8 → F) (w : (Fin (20 + 2) → Bool) → F) : Prop :=
  (∀ y : Fin 20 → Bool, gate (I.basis.β 1) (w (cellBits (y, 0))) (w (cellBits (y, 1)))
      (w (cellBits (y, 2))) (w (cellBits (y, 3))) = 0) ∧
    (∀ x, w (I.wiring x) = w x) ∧
    ∀ J : Fin 8, ∑ x, regionWeight I.c J x * w x = stmt J

/-- The statement of `flock::quotient`: four words chosen by the user, then `(1, 0, 0, 0)`. The
theorems are for any eight words, these included. -/
def protocolStatement (s : Fin 4 → F) : Fin 8 → F := ![s 0, s 1, s 2, s 3, 1, 0, 0, 0]

/-- The witness polynomial of a first message `g`: `sum_j X_j * g_j(X^4 + X)`, on the basis
`X_j = 1, X, X^2 + X, X^3 + X^2`. -/
noncomputable def witnessPoly (g : Fin 4 → F[X]) : F[X] := ∑ j, digit j * (g j).comp rowPoly

/-- **The cells a first message holds**: its witness polynomial at each cell's point. -/
noncomputable def cellsOf (g : Fin 4 → F[X]) (x : Fin (20 + 2) → Bool) : F :=
  (witnessPoly g).eval (I.basis.point x)

/-! ## Soundness: proofs and adversaries

The commitment is ideal and binding: a proof carries its polynomials, and the random oracle is
asked about them directly. -/

/-- **A statement with a proof of it.** `stmt`: eight words. `g`: the first message, four
polynomials of degree at most `2^21`. `R`: the second, five polynomials of degree at most
`2^24`. `v`: five field elements. -/
abbrev Proof := QuotientSecurity.Proof I.params I.bounds

/-- **An adversary**: any computation that asks the random oracle and outputs a statement with a
proof. -/
abbrev Adversary := OracleComp (ofFn (Answer I.params I.bounds)) I.Proof

/-! ## Zero knowledge: the two experiments

The commitment is ideal and its openings reveal nothing: a commitment is a handle drawn at
random in `H`, and of the four claims the experiments output only whether they are true. -/

section Experiments

variable {K E : Type} [Field K] [Field E] [Algebra K E] [DecidableEq E] [CharP E 2] [Fintype E]
variable [Fintype K] [DecidableEq K] [FiniteDimensional K E]
variable [SampleableType K] [SampleableType E] {H : Type} [SampleableType H]
variable (I : Instance E)

variable (H) in
/-- The oracle's table: what it has answered so far. -/
abbrev Table := (ofFn (ZAnswer I.params H)).QueryCache

variable (H) in
/-- **What an experiment outputs**: the two handles, the five field elements, the verdict, the
three challenges, and the oracle's table afterwards. -/
abbrev View := Outcome (E := E) H × I.Table H

/-- The cells of a witness given by four polynomials over `K`. -/
noncomputable def witnessCells (gK : Fin 4 → K[X]) : (Fin (20 + 2) → Bool) → E :=
  I.cellsOf fun j => (gK j).map (algebraMap K E)

/-- **The real experiment**: the honest prover on the witness `gK`, each polynomial masked by
three random coefficients, against the random oracle in the state `c₀`. -/
noncomputable def real (c₀ : I.Table H) (stmt : Fin 8 → E) (gK : Fin 4 → K[X]) :
    ProbComp (I.View H) :=
  realNI c₀ stmt gK (digitPoly 20)

variable (K) in
/-- **The simulator**: given the statement and the oracle's state, and no witness. -/
noncomputable def sim (c₀ : I.Table H) (stmt : Fin 8 → E) : ProbComp (I.View H) :=
  simNI (K := K) c₀ stmt

end Experiments

end Instance

end QuotientSecurity
