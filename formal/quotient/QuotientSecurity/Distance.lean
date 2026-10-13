import QuotientSecurity.NonInteractive
import QuotientSecurity.Bits

/-!
# Zero knowledge as one bound

For every event on the outcome (the proof, its verdict, its challenges and the oracle's table),
the real experiment and the simulator's give it probabilities that differ by at most
`(2 N + 4 deg) / q`: the fraction of challenges that are not good for the witness. At the
protocol's sizes this is below `2^-128`.
-/

set_option linter.unusedSectionVars false

open OracleSpec OracleComp Polynomial Module NNReal

namespace QuotientSecurity

/-- Two experiments that agree on every good outcome, the bad ones being rare in the first,
give any event nearly the same probability. -/
theorem probEvent_le_add_of_eq_on {α : Type} (X Y : ProbComp α) (good : α → Prop) (ε : ENNReal)
    (heq : ∀ o, good o → Pr[= o | X] = Pr[= o | Y])
    (hbad : Pr[fun o => ¬ good o | X] ≤ ε) (S : α → Prop) :
    Pr[S | X] ≤ Pr[S | Y] + ε := by
  classical
  have h1 : Pr[S | X] ≤ Pr[fun o => S o ∧ good o | X] + Pr[fun o => ¬ good o | X] :=
    probEvent_le_add_of_imp_or fun o _ hS => by
      by_cases hg : good o
      · exact Or.inl ⟨hS, hg⟩
      · exact Or.inr hg
  have h2 : Pr[fun o => S o ∧ good o | X] = Pr[fun o => S o ∧ good o | Y] := by
    rw [probEvent_eq_tsum_ite, probEvent_eq_tsum_ite]
    refine tsum_congr fun o => ?_
    split_ifs with h
    · exact heq o h.2
    · rfl
  have h3 : Pr[fun o => S o ∧ good o | Y] ≤ Pr[S | Y] := probEvent_mono fun o _ h => h.1
  calc Pr[S | X] ≤ Pr[fun o => S o ∧ good o | X] + Pr[fun o => ¬ good o | X] := h1
    _ ≤ Pr[S | Y] + ε := add_le_add (h2 ▸ h3) hbad

variable {K E : Type} [Field K] [Field E] [Algebra K E] [DecidableEq E] [CharP E 2] [Fintype E]
variable {P : Params E} {H : Type} [SampleableType E] [SampleableType H]
variable [Fintype K] [DecidableEq K] [FiniteDimensional K E] [SampleableType K]

/-- The fraction of challenges that are not good. -/
noncomputable def zkError (P : Params E) (van : K[X]) : ℝ≥0 :=
  ((2 * P.nCells + 4 * van.natDegree : ℕ) : ℝ≥0) / (Fintype.card E : ℝ≥0)

open Classical in
/-- The handles and challenges are rarely not good for a witness. -/
theorem prob_not_good_challenges (gK : Fin 4 → K[X]) (van : K[X]) (hvan0 : van ≠ 0) :
    Pr[fun c : H × H × (E × E × E) × E × E => ¬ Good (P := P) gK van c.2.2.1 c.2.2.2.1 |
        challenges (E := E) (H := H)] ≤ (zkError P van : ENNReal) := by
  unfold challenges
  refine probEvent_bind_le_of_forall_le fun c₁ _ => probEvent_bind_le_of_forall_le fun c₂ _ => ?_
  -- What remains is a uniform `(ch, t, ρ)`, whose event looks at `(ch, t)` only.
  have hmap : (($ᵗ (E × E × E)) >>= fun ch => ($ᵗ E) >>= fun t => ($ᵗ E) >>= fun ρ =>
        (pure (c₁, c₂, ch, t, ρ) : ProbComp (H × H × (E × E × E) × E × E)))
      = (fun x : ((E × E × E) × E) × E => (c₁, c₂, x.1.1, x.1.2, x.2)) <$>
          ($ᵗ (((E × E × E) × E) × E)) := by
    have hprod : ∀ (α β : Type) [SampleableType α] [SampleableType β],
        ($ᵗ (α × β) : ProbComp (α × β))
          = ($ᵗ α) >>= fun a => ($ᵗ β) >>= fun b => pure (a, b) := by
      intro α β _ _
      show ((·, ·) <$> ($ᵗ α) <*> ($ᵗ β) : ProbComp (α × β)) = _
      simp [seq_eq_bind_map, map_eq_bind_pure_comp, bind_assoc]
    rw [hprod ((E × E × E) × E) E, hprod (E × E × E) E]
    simp [map_eq_bind_pure_comp, bind_assoc]
  rw [hmap, probEvent_map]
  simp only [Function.comp_def]
  rw [probEvent_uniformSample]
  have hcount : (Finset.univ.filter fun x : ((E × E × E) × E) × E =>
        ¬ Good (P := P) gK van x.1.1 x.1.2).card
      ≤ (2 * P.nCells + 4 * van.natDegree) * Fintype.card E ^ 3 * Fintype.card E := by
    have h := card_not_good_le (P := P) gK van hvan0
    have : (Finset.univ.filter fun x : ((E × E × E) × E) × E =>
          ¬ Good (P := P) gK van x.1.1 x.1.2)
        = (Finset.univ.filter fun x : (E × E × E) × E => ¬ Good (P := P) gK van x.1 x.2) ×ˢ
          (Finset.univ : Finset E) := by
      ext ⟨x, ρ⟩
      simp
    rw [this, Finset.card_product, Finset.card_univ]
    exact Nat.mul_le_mul_right _ h
  have hq : 0 < Fintype.card E := Fintype.card_pos
  have hcardE : (Fintype.card (((E × E × E) × E) × E) : ENNReal)
      = ((Fintype.card E ^ (4 + 1) : ℕ) : ENNReal) := by
    simp only [Fintype.card_prod]; push_cast; ring
  rw [hcardE]
  unfold zkError
  exact card_div_le hq (hcount.trans (le_of_eq (by ring)))

attribute [local irreducible] Good in
open Classical in
/-- An experiment that draws the handles and challenges, then outputs an outcome carrying them,
rarely has challenges that are not good. -/
theorem prob_not_good_le (gK : Fin 4 → K[X]) (van : K[X]) (hvan0 : van ≠ 0)
    (inner : H × H × (E × E × E) × E × E →
      ProbComp (Outcome (E := E) H × (ofFn (ZAnswer P H)).QueryCache))
    (hinner : ∀ c, ∀ o ∈ support (inner c), o.1.ch = c.2.2.1 ∧ o.1.t = c.2.2.2.1) :
    Pr[fun o => ¬ Good (P := P) gK van o.1.ch o.1.t | challenges (E := E) (H := H) >>= inner]
      ≤ (zkError P van : ENNReal) := by
  have hch := prob_not_good_challenges (P := P) (H := H) gK van hvan0
  have hstep : Pr[fun o => ¬ Good (P := P) gK van o.1.ch o.1.t |
        challenges (E := E) (H := H) >>= inner]
      ≤ Pr[fun c : H × H × (E × E × E) × E × E => ¬ Good (P := P) gK van c.2.2.1 c.2.2.2.1 |
          challenges (E := E) (H := H)] := by
    refine probEvent_bind_le_probEvent fun c _ hc => ?_
    rw [not_not] at hc
    refine probEvent_eq_zero fun o ho => ?_
    obtain ⟨h1, h2⟩ := hinner c o ho
    intro hng
    apply hng
    rw [h1, h2]
    exact hc
  exact hstep.trans hch

/-- **Zero knowledge, as one bound.** For every event on the outcome (the proof, its verdict, its
challenges, the oracle's table), the real experiment and the simulator's give probabilities
within `zkError` of each other. -/
theorem zeroKnowledge (h3 : finrank K E = 3) (hE : P.Exact) (stmt : Fin P.words → E)
    (gK : Fin 4 → K[X]) (van : K[X]) (hvan0 : van ≠ 0)
    (hvan : ∀ x : P.T, aeval (rowPoly.eval (x : E)) van = 0)
    (hsat : P.Sat stmt (P.cells (committed gK van 0)))
    (S : Outcome (E := E) H × (ofFn (ZAnswer P H)).QueryCache → Prop) :
    Pr[S | realNI (H := H) stmt gK van]
        ≤ Pr[S | simNI (K := K) (P := P) (H := H) stmt] + (zkError P van : ENNReal) ∧
      Pr[S | simNI (K := K) (P := P) (H := H) stmt]
        ≤ Pr[S | realNI (H := H) stmt gK van] + (zkError P van : ENNReal) := by
  classical
  have heq := fun o hgood => realNI_eq_simNI (H := H) h3 hE stmt gK van hvan hsat o hgood
  have hreal : Pr[fun o => ¬ Good (P := P) gK van o.1.ch o.1.t | realNI (H := H) stmt gK van]
      ≤ (zkError P van : ENNReal) := by
    rw [realNI_eq]
    refine probEvent_bind_le_of_forall_le fun m _ => ?_
    refine prob_not_good_le gK van hvan0 _ fun c o ho => ?_
    rw [support_pure, Set.mem_singleton_iff] at ho
    subst ho
    exact ⟨rfl, rfl⟩
  have hsim : Pr[fun o => ¬ Good (P := P) gK van o.1.ch o.1.t |
      simNI (K := K) (P := P) (H := H) stmt] ≤ (zkError P van : ENNReal) := by
    unfold simNI
    refine prob_not_good_le gK van hvan0 _ fun c o ho => ?_
    rw [mem_support_bind_iff] at ho
    obtain ⟨a, -, ha⟩ := ho
    rw [support_pure, Set.mem_singleton_iff] at ha
    subst ha
    exact ⟨rfl, rfl⟩
  exact ⟨probEvent_le_add_of_eq_on _ _ _ _ heq hreal S,
    probEvent_le_add_of_eq_on _ _ _ _ (fun o hgood => (heq o hgood).symm) hsim S⟩

/-- **128 bits.** At the protocol's sizes the bound is below `2^-128`. -/
theorem zkError_le (hq : Fintype.card E = 2 ^ 192) (hN : P.nCells = 2 ^ 22) (van : K[X])
    (hdeg : van.natDegree ≤ 2 ^ 20) : zkError P van ≤ 1 / 2 ^ 128 := by
  unfold zkError
  refine div_le_two_pow Fintype.card_pos ?_
  rw [hq, hN]
  calc (2 * 2 ^ 22 + 4 * van.natDegree) * 2 ^ 128 ≤ (2 * 2 ^ 22 + 4 * 2 ^ 20) * 2 ^ 128 := by
        gcongr
    _ ≤ 2 ^ 192 := by norm_num

end QuotientSecurity
