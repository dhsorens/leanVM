import QuotientSecurity.NonInteractive
import QuotientSecurity.Bits

/-!
# Zero knowledge as one bound

For every event on the outcome (the proof, its verdict, its challenges and the oracle's table),
the real experiment and the simulator's give it probabilities that differ by at most
`(2 N + 4 deg) / q + |U| / |H|`: the fraction of challenges that are not good for the witness,
and of handles the oracle was already asked about. At the protocol's sizes the first is below
`2^-128`.
-/

set_option linter.unusedSectionVars false
-- These files are written on VCVio's `Pr[p | mx]`, which it is retiring; `Statement.lean` states the
-- results on its replacement, through `prEvent_eq_probEvent`.
set_option linter.deprecated false

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

/-- Two experiments that agree on the outcomes satisfying `p` give `p ∧ q` the same
probability. -/
theorem probEvent_and_congr {α : Type} (X Y : ProbComp α) (p q : α → Prop)
    (heq : ∀ o, p o → Pr[= o | X] = Pr[= o | Y]) :
    Pr[fun o => p o ∧ q o | X] = Pr[fun o => p o ∧ q o | Y] := by
  classical
  rw [probEvent_eq_tsum_ite, probEvent_eq_tsum_ite]
  refine tsum_congr fun o => ?_
  split_ifs with h
  · exact heq o h.1
  · rfl

variable [Fintype H] [DecidableEq H]

open Classical in
/-- The first handle of an experiment that draws it uniformly is rarely one of a given set. -/
theorem prob_handle_le (U : Finset H) (p : H → Prop) (hU : ∀ c₁, c₁ ∉ U → p c₁)
    {α : Type} (inner : H → ProbComp α) (handle : α → H)
    (hinner : ∀ c₁, ∀ y ∈ support (inner c₁), handle y = c₁) :
    Pr[fun y => ¬ p (handle y) | ($ᵗ H) >>= inner]
      ≤ (U.card : ENNReal) / (Fintype.card H : ENNReal) := by
  have hstep : Pr[fun y => ¬ p (handle y) | ($ᵗ H) >>= inner] ≤ Pr[fun c₁ => c₁ ∈ U | $ᵗ H] := by
    refine probEvent_bind_le_probEvent fun c₁ _ hc => ?_
    refine probEvent_eq_zero fun y hy => ?_
    rw [hinner c₁ y hy, not_not]
    exact hU c₁ hc
  refine hstep.trans (le_of_eq ?_)
  have hfilter : (Finset.univ.filter fun c₁ : H => c₁ ∈ U) = U := by
    ext c
    simp
  rw [probEvent_uniformSample, hfilter]

/-- The error of the simulation: the challenges that are not good, and the handles that are not
fresh. -/
noncomputable def zkBound (P : Params E) (van : K[X]) (U : Finset H) : ENNReal :=
  (zkError P van : ENNReal) + (U.card : ENNReal) / (Fintype.card H : ENNReal)

attribute [local irreducible] Good Fresh in
/-- The outcomes that are not good (a first handle that is not fresh, challenges that are not
good for the witness) are rare, in the real experiment and in the simulator's. -/
theorem prob_not_good (c₀ : (ofFn (ZAnswer P H)).QueryCache) (stmt : Fin P.words → E)
    (U : Finset H) (hU : ∀ c₁, c₁ ∉ U → Fresh c₀ stmt c₁)
    (gK : Fin 4 → K[X]) (van : K[X]) (hvan0 : van ≠ 0) :
    Pr[fun o => ¬ (Fresh c₀ stmt o.1.c₁ ∧ Good (P := P) gK van o.1.ch o.1.t) |
        realNI c₀ stmt gK van] ≤ zkBound P van U ∧
      Pr[fun o => ¬ (Fresh c₀ stmt o.1.c₁ ∧ Good (P := P) gK van o.1.ch o.1.t) |
        simNI (K := K) c₀ stmt] ≤ zkBound P van U := by
  classical
  set good : Outcome (E := E) H × (ofFn (ZAnswer P H)).QueryCache → Prop :=
    fun o => Fresh c₀ stmt o.1.c₁ ∧ Good (P := P) gK van o.1.ch o.1.t with hgood
  have hopen : Pr[fun o => ¬ Good (P := P) gK van o.1.ch o.1.t | openNI c₀ stmt gK van]
      ≤ (zkError P van : ENNReal) := by
    unfold openNI
    refine probEvent_bind_le_of_forall_le fun m _ => ?_
    refine prob_not_good_le gK van hvan0 _ fun c o ho => ?_
    rw [support_pure, Set.mem_singleton_iff] at ho
    subst ho
    exact ⟨rfl, rfl⟩
  have hsimGood : Pr[fun o => ¬ Good (P := P) gK van o.1.ch o.1.t | simNI (K := K) c₀ stmt]
      ≤ (zkError P van : ENNReal) := by
    unfold simNI
    refine prob_not_good_le gK van hvan0 _ fun c o ho => ?_
    rw [mem_support_bind_iff] at ho
    obtain ⟨a, -, ha⟩ := ho
    rw [support_pure, Set.mem_singleton_iff] at ha
    subst ha
    exact ⟨rfl, rfl⟩
  -- The first handle is rarely not fresh, in both.
  have hrealFresh : Pr[fun o => ¬ Fresh c₀ stmt o.1.c₁ | realNI c₀ stmt gK van]
      ≤ (U.card : ENNReal) / (Fintype.card H : ENNReal) := by
    unfold realNI
    refine probEvent_bind_le_of_forall_le fun m _ => ?_
    refine prob_handle_le U (Fresh c₀ stmt) hU _
      (fun o : Outcome (E := E) H × (ofFn (ZAnswer P H)).QueryCache => o.1.c₁) fun c₁ y hy => ?_
    rw [mem_support_bind_iff] at hy
    obtain ⟨c₂, -, hy⟩ := hy
    exact run_proverRO_handle c₀ stmt gK van m c₁ c₂ y hy
  have hsimFresh : Pr[fun o => ¬ Fresh c₀ stmt o.1.c₁ | simNI (K := K) c₀ stmt]
      ≤ (U.card : ENNReal) / (Fintype.card H : ENNReal) := by
    unfold simNI challenges
    simp only [bind_assoc, pure_bind]
    refine prob_handle_le U (Fresh c₀ stmt) hU _
      (fun o : Outcome (E := E) H × (ofFn (ZAnswer P H)).QueryCache => o.1.c₁) fun c₁ y hy => ?_
    simp only [mem_support_bind_iff, support_pure, Set.mem_singleton_iff] at hy
    obtain ⟨c₂, -, ch, -, t, -, ρ, -, a, -, rfl⟩ := hy
    rfl
  have hbadReal : Pr[fun o => ¬ good o | realNI c₀ stmt gK van] ≤ zkBound P van U := by
    have hsplit : Pr[fun o => ¬ good o | realNI c₀ stmt gK van]
        ≤ Pr[fun o => Fresh c₀ stmt o.1.c₁ ∧ ¬ Good (P := P) gK van o.1.ch o.1.t |
              realNI c₀ stmt gK van]
          + Pr[fun o => ¬ Fresh c₀ stmt o.1.c₁ | realNI c₀ stmt gK van] :=
      probEvent_le_add_of_imp_or fun o _ ho => by
        by_cases hf : Fresh c₀ stmt o.1.c₁
        · exact Or.inl ⟨hf, fun hg => ho ⟨hf, hg⟩⟩
        · exact Or.inr hf
    have hcongr := probEvent_and_congr (realNI c₀ stmt gK van) (openNI c₀ stmt gK van)
      (fun o => Fresh c₀ stmt o.1.c₁) (fun o => ¬ Good (P := P) gK van o.1.ch o.1.t)
      (fun o hf => realNI_eq_openNI c₀ stmt gK van o hf)
    have hle : Pr[fun o => Fresh c₀ stmt o.1.c₁ ∧ ¬ Good (P := P) gK van o.1.ch o.1.t |
        openNI c₀ stmt gK van] ≤ (zkError P van : ENNReal) :=
      (probEvent_mono fun o _ h => h.2).trans hopen
    rw [hcongr] at hsplit
    exact hsplit.trans (add_le_add hle hrealFresh)
  have hbadSim : Pr[fun o => ¬ good o | simNI (K := K) c₀ stmt] ≤ zkBound P van U := by
    have hsplit : Pr[fun o => ¬ good o | simNI (K := K) c₀ stmt]
        ≤ Pr[fun o => ¬ Good (P := P) gK van o.1.ch o.1.t | simNI (K := K) c₀ stmt]
          + Pr[fun o => ¬ Fresh c₀ stmt o.1.c₁ | simNI (K := K) c₀ stmt] :=
      probEvent_le_add_of_imp_or fun o _ ho => by
        by_cases hf : Fresh c₀ stmt o.1.c₁
        · exact Or.inl fun hg => ho ⟨hf, hg⟩
        · exact Or.inr hf
    exact hsplit.trans (add_le_add hsimGood hsimFresh)
  exact ⟨hbadReal, hbadSim⟩

attribute [local irreducible] Good Fresh in
/-- **Zero knowledge, as one bound.** Let the oracle hold whatever it was asked before, `U`
containing every handle it was asked about with this statement. Then for every event on the
outcome (the proof, its verdict, its challenges, the oracle's table), the real experiment and
the simulator's give probabilities within `zkBound` of each other. -/
theorem zeroKnowledge (h3 : finrank K E = 3) (hE : P.Exact)
    (c₀ : (ofFn (ZAnswer P H)).QueryCache) (stmt : Fin P.words → E)
    (U : Finset H) (hU : ∀ c₁, c₁ ∉ U → Fresh c₀ stmt c₁)
    (gK : Fin 4 → K[X]) (van : K[X]) (hvan0 : van ≠ 0)
    (hvan : ∀ x : P.T, aeval (rowPoly.eval (x : E)) van = 0)
    (hsat : P.Sat stmt (P.cells (committed gK van 0)))
    (S : Outcome (E := E) H × (ofFn (ZAnswer P H)).QueryCache → Prop) :
    Pr[S | realNI c₀ stmt gK van] ≤ Pr[S | simNI (K := K) c₀ stmt] + zkBound P van U ∧
      Pr[S | simNI (K := K) c₀ stmt] ≤ Pr[S | realNI c₀ stmt gK van] + zkBound P van U := by
  classical
  set good : Outcome (E := E) H × (ofFn (ZAnswer P H)).QueryCache → Prop :=
    fun o => Fresh c₀ stmt o.1.c₁ ∧ Good (P := P) gK van o.1.ch o.1.t with hgood
  have heq : ∀ o, good o → Pr[= o | realNI c₀ stmt gK van] = Pr[= o | simNI (K := K) c₀ stmt] :=
    fun o h => realNI_eq_simNI h3 hE c₀ stmt gK van hvan hsat o h.1 h.2
  -- The open experiment's challenges are rarely not good.
  obtain ⟨hbadReal, hbadSim⟩ := prob_not_good c₀ stmt U hU gK van hvan0
  exact ⟨probEvent_le_add_of_eq_on _ _ _ _ heq hbadReal S,
    probEvent_le_add_of_eq_on _ _ _ _ (fun o h => (heq o h).symm) hbadSim S⟩

/-- The first handle of a hash input. -/
def ZKey.handle : ZKey P H → H
  | .first _ c₁ => c₁
  | .second _ c₁ _ => c₁
  | .third _ c₁ _ _ _ => c₁

/-- **An oracle asked `Q` things knows at most `Q` handles.** If the oracle's state is empty
outside a finite set of hash inputs, the handles that are not fresh are at most as many. -/
theorem exists_handles (c₀ : (ofFn (ZAnswer P H)).QueryCache) (stmt : Fin P.words → E)
    (keys : Finset (ZKey P H)) (hkeys : ∀ k, k ∉ keys → c₀ k = none) :
    ∃ U : Finset H, U.card ≤ keys.card ∧ ∀ c₁, c₁ ∉ U → Fresh c₀ stmt c₁ := by
  classical
  refine ⟨keys.image ZKey.handle, Finset.card_image_le, fun c₁ hc => ?_⟩
  have hnone : ∀ k : ZKey P H, k.handle = c₁ → c₀ k = none := fun k hk =>
    hkeys k fun hmem => hc (Finset.mem_image.mpr ⟨k, hmem, hk⟩)
  exact ⟨hnone _ rfl, fun c₂ => hnone _ rfl, fun c₂ a s => hnone _ rfl⟩

/-- **128 bits.** At the protocol's sizes the challenges' part of the bound is below `2^-128`. -/
theorem zkError_le (hq : Fintype.card E = 2 ^ 192) (hN : P.nCells = 2 ^ 22) (van : K[X])
    (hdeg : van.natDegree ≤ 2 ^ 20) : zkError P van ≤ 1 / 2 ^ 128 := by
  unfold zkError
  refine div_le_two_pow Fintype.card_pos ?_
  rw [hq, hN]
  calc (2 * 2 ^ 22 + 4 * van.natDegree) * 2 ^ 128 ≤ (2 * 2 ^ 22 + 4 * 2 ^ 20) * 2 ^ 128 := by
        gcongr
    _ ≤ 2 ^ 192 := by norm_num

end QuotientSecurity
