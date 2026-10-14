import VCVio.EvalDist.ProbabilityNotation
import VCVio.OracleComp.ProbComp

/-!
# One notation for probabilities

VCVio is retiring `Pr[p | mx]` for `Pr{let x ← mx}[p x]`, the measure of the event under the
computation's distribution. The zero knowledge files were written on the first and are stated,
in `Statement.lean`, on the second: this is the bridge.
-/

set_option linter.deprecated false

open OracleComp

namespace QuotientSecurity

/-- The two notations are the same number. -/
theorem prEvent_eq_probEvent {α : Type} (mx : ProbComp α) (p : α → Prop) :
    Pr{let x ← mx}[p x] = Pr[p | mx] := by
  let _ : MeasurableSpace α := ⊤
  rw [prEvent_eq_evalDist_of_discrete, evalDist_apply_setOf]

end QuotientSecurity
