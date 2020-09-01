import field_theory.separable
import field_theory.splitting_field
import linear_algebra.finite_dimensional
import ring_theory.adjoin

open finite_dimensional
open polynomial

/-- A computable specialization of `finsupp.emb_domain` from `fin i` to `ℕ`. -/
def finsupp.emb_fin_nat {M : Type*} [has_zero M] {i : ℕ} (f : fin i →₀ M) : ℕ →₀ M :=
{ to_fun := λ n, if h : n < i then f ⟨n, h⟩ else 0,
  support := f.support.map ⟨fin.val, fin.val_injective⟩,
  mem_support_to_fun := λ n, finset.mem_map.trans begin
    simp only [function.embedding.coe_fn_mk],
    split_ifs with h,
    { refine iff.trans _ finsupp.mem_support_iff,
      split,
      { rintros ⟨n', n'_mem, rfl⟩,
        rw fin.eta,
        exact n'_mem },
      { intro n_mem,
        exact ⟨⟨n, h⟩, n_mem, rfl⟩ } },
    { simp only [ne.def, eq_self_iff_true, not_true, iff_false, not_exists],
      rintros ⟨n', n_lt⟩ _ rfl,
      exact h n_lt },
  end }

@[simp] lemma finsupp.emb_fin_nat_apply {M : Type*} [has_zero M] {i : ℕ} (f : fin i →₀ M) (n : ℕ) :
  f.emb_fin_nat n = if h : n < i then f ⟨n, h⟩ else 0 := rfl

@[simp] lemma finsupp.emb_fin_nat_support {M : Type*} [has_zero M] {i : ℕ} (f : fin i →₀ M) :
  f.emb_fin_nat.support = f.support.map ⟨fin.val, fin.val_injective⟩ := rfl

@[simp] lemma finsupp.emb_fin_nat_sum {M N : Type*} [has_zero M] [add_comm_monoid N]
  {i : ℕ} (f : fin i →₀ M) (g : ℕ → M → N) :
  (f.emb_fin_nat).sum g = f.sum (λ i, g i) :=
begin
  simp_rw [finsupp.sum, finsupp.emb_fin_nat_support, finset.sum_map, function.embedding.coe_fn_mk],
  congr, ext j,
  congr,
  rw finsupp.emb_fin_nat_apply,
  split_ifs with h,
  { rw fin.eta },
  { exfalso,
    exact h j.2 }
end

@[simp] lemma finsupp.emb_fin_nat_eq_zero {M : Type*} [has_zero M] {i : ℕ} (f : fin i →₀ M) :
  f.emb_fin_nat = 0 ↔ f = 0 :=
begin
  rw [finsupp.ext_iff, finsupp.ext_iff],
  split; intros h n,
  { refine trans _ (h n),
    erw [finsupp.emb_fin_nat_apply, dif_pos n.2, fin.eta] },
  { by_cases hn : n < i,
    { exact trans (dif_pos hn) (h ⟨n, hn⟩) },
    { exact dif_neg hn } }
end

namespace polynomial

lemma degree_emb_fin_nat_lt {R : Type*} [semiring R] {i : ℕ} (f : fin i →₀ R) :
  degree (f.emb_fin_nat) < i :=
begin
  by_cases hf : f.emb_fin_nat = 0,
  { rw [hf, degree_zero],
    apply with_bot.bot_lt_some },
  erw [degree_eq_nat_degree hf, with_bot.some_lt_some],
  exact lt_of_not_ge (λ h, hf (leading_coeff_eq_zero.mp (dif_neg (not_lt_of_ge h))))
end

lemma eval₂_mod_by_monic_eq_self_of_root {R S : Type*} [comm_ring R] [comm_ring S] {f : R →+* S}
  {p q : polynomial R} (hq : q.monic) {x : S} (hx : q.eval₂ f x = 0) :
    (p %ₘ q).eval₂ f x = p.eval₂ f x :=
by rw [mod_by_monic_eq_sub_mul_div p hq, eval₂_sub, eval₂_mul, hx, zero_mul, sub_zero]

end polynomial

variables (R S : Type*) [comm_ring R] [comm_semiring S] [algebra R S]
variables (K L : Type*) [field K] [field L] [algebra K L]

/- A ring extension `S / R` is a simple extension if `S = R(x)` for some `x : S`. -/
@[class] def is_simple_extension : Prop :=
∃ x : S, (algebra.adjoin R {x} : subalgebra R S) = ⊤

namespace is_simple_extension

variables {R S}

lemma iff_exists_eq_aeval :
  is_simple_extension R S ↔ ∃ x : S, ∀ y : S, ∃ f : polynomial R, aeval x f = y :=
by simpa only [is_simple_extension, algebra.adjoin_singleton_eq_range, subalgebra.ext_iff,
               algebra.mem_top, iff_true] using iff.rfl

variables (R S)

/- A primitive element for `S / R` is an `x : S` such that `L = K(x)`. -/
noncomputable def primitive_element [simple : is_simple_extension R S] : S :=
classical.some simple

/- Adjoining the primitive element of `S` to `R` gives `S`. -/
lemma adjoin_primitive_element [simple : is_simple_extension R S] :
  (algebra.adjoin R {primitive_element R S} : subalgebra R S) = ⊤ :=
classical.some_spec simple

lemma mem_adjoin_primitive_element [is_simple_extension R S] (x : S) :
  x ∈ (algebra.adjoin R {primitive_element R S} : subalgebra R S) :=
(adjoin_primitive_element R S).symm ▸ algebra.mem_top

lemma adjoin_primitive_element_submodule [simple : is_simple_extension R S] :
  ((algebra.adjoin R {primitive_element R S} : subalgebra R S) : submodule R S) = ⊤ :=
by { ext, simp [mem_adjoin_primitive_element] }

lemma exists_eq_aeval_primitive_element (x : S) [is_simple_extension R S] :
  ∃ f : polynomial R, x = aeval (primitive_element R S) f :=
begin
  obtain ⟨f, hf⟩ : x ∈ (aeval (primitive_element R S)).range :=
    by simpa [algebra.adjoin_singleton_eq_range] using mem_adjoin_primitive_element R S x,
  exact ⟨f, hf.symm⟩
end

@[simp] lemma coe_aeval {S} [comm_ring S] [algebra R S] (A : subalgebra R S) (f : polynomial R) (y : A) :
  (aeval y f : S) = aeval (y : S) f :=
alg_hom_eval₂_algebra_map f A.val y

lemma is_simple_subalgebra_iff {S} [comm_ring S] [algebra R S] (A : subalgebra R S) :
  is_simple_extension R A ↔ ∃ x ∈ A, algebra.adjoin R {x} = A :=
⟨λ ⟨⟨x, mem⟩, hx⟩, ⟨x, mem, le_antisymm
  (algebra.adjoin_le (set.singleton_subset_iff.mpr mem))
  (λ y hy, begin
    have : subtype.mk y hy ∈ (⊤ : subalgebra R A) := algebra.mem_top,
    rw ← hx at this,
    rw algebra.adjoin_singleton_eq_range at this ⊢,
    obtain ⟨f, hf⟩ := this,
    use f,
    rw [subtype.ext_iff, subtype.coe_mk, coe_aeval] at hf,
    exact hf
  end)⟩,
 λ ⟨x, mem, hx⟩, ⟨⟨x, mem⟩, eq_top_iff.mpr (λ ⟨y, (hy : y ∈ A)⟩ _, begin
    rw [coe_coe, submodule.mem_coe, subalgebra.mem_to_submodule, algebra.adjoin_singleton_eq_range],
    rw [← hx, algebra.adjoin_singleton_eq_range] at hy,
    obtain ⟨f, hf⟩ := hy,
    use f,
    rw [subtype.ext_iff, coe_aeval, subtype.coe_mk],
    exact hf
  end)⟩⟩

lemma is_simple_top_iff {S} [comm_ring S] [algebra R S] :
  is_simple_extension R (⊤ : subalgebra R S) ↔ is_simple_extension R S :=
(is_simple_subalgebra_iff R ⊤).trans ⟨λ ⟨x, _, hx⟩, ⟨x, hx⟩, λ ⟨x, hx⟩, ⟨x, algebra.mem_top, hx⟩⟩

lemma is_simple_of_bot_eq_top (h : (⊥ : subalgebra R S) = ⊤) : is_simple_extension R S :=
⟨0, trans (eq_bot_iff.mpr (algebra.adjoin_le (by simpa using subalgebra.zero_mem ⊥))) h⟩

instance is_simple_bot : is_simple_extension R (⊥ : subalgebra R S) :=
begin
  refine is_simple_of_bot_eq_top _ _ (eq_top_iff.mpr _),
  rintros ⟨x, hx⟩ _,
  obtain ⟨y, rfl⟩ := algebra.mem_bot.mp hx,
  refine algebra.mem_bot.mpr ⟨y, _⟩,
  ext,
  refl
end

end is_simple_extension

open is_simple_extension

instance finite_field.is_simple_extension [fintype L] :
  is_simple_extension K L :=
begin
  obtain ⟨x, hx⟩ := is_cyclic.exists_generator (units L),
  simp_rw ← mem_powers_iff_mem_gpowers at hx,
  refine iff_exists_eq_aeval.mpr ⟨x, λ y, _⟩,
  by_cases hy : y = 0,
  { rw hy,
    exact ⟨0, eval₂_zero _ _⟩ },
  obtain ⟨y, rfl⟩ : is_unit y := is_unit.mk0 y hy,
  obtain ⟨n, rfl⟩ := hx y,
  use X^n,
  rw [alg_hom.map_pow, aeval_X, units.coe_pow]
end

namespace is_simple_extension

section is_algebraic

variables {K L} [is_simple_extension K L] (alg : algebra.is_algebraic K L)

lemma primitive_element_is_integral : is_integral K (primitive_element K L) :=
(is_algebraic_iff_is_integral _).mp (alg (primitive_element K L))

/-- The `minimal_polynomial` of a simple algebraic extension is the minimal
polynomial of a primitive element. -/
noncomputable def minimal_polynomial : polynomial K :=
minimal_polynomial (primitive_element_is_integral alg)

/-- The `degree` of a simple algebraic extension `L / K` is the degree of the
minimal polynomial of the primitive element.

Later, in `findim_eq_simple_degree`, we will prove this is the same as the
degree of `L` over `K` as vector spaces. -/
noncomputable def simple_degree := (minimal_polynomial alg).nat_degree

/-- The `power_basis` of a simple algebraic field extension `L / K` is a basis
for `L` as a vector space of `K`, consisting of the powers of the `primitive_element`. -/
noncomputable def power_basis : fin (simple_degree alg) → L :=
λ n, primitive_element K L ^ (n : ℕ)

@[simp] lemma power_basis_apply (n : fin (simple_degree alg)) :
  power_basis alg n = primitive_element K L ^ (n : ℕ) :=
rfl

@[simp] lemma total_power_basis_eq (f : fin (simple_degree alg) →₀ K) :
  finsupp.total _ _ _ (power_basis alg) f =
    aeval (primitive_element K L) (finsupp.emb_fin_nat f) :=
by simp [aeval, eval₂_eq_sum, finsupp.total, linear_map.smul_right, algebra.smul_def]

lemma linear_independent_power_basis :
  linear_independent K (power_basis alg) :=
begin
  rw linear_independent_iff,
  intros p hp,
  rw total_power_basis_eq at hp,
  rw ← finsupp.emb_fin_nat_eq_zero,
  refine minimal_polynomial.eq_zero_of_degree_lt (primitive_element_is_integral alg) _ hp,
  rw degree_eq_nat_degree (minimal_polynomial.ne_zero _),
  exact polynomial.degree_emb_fin_nat_lt _
end

lemma mem_span_power_basis (x : L) : x ∈ submodule.span K (set.range (power_basis alg)) :=
begin
  have mp_monic := minimal_polynomial.monic (primitive_element_is_integral alg),
  have mp_ne_zero := minimal_polynomial.ne_zero (primitive_element_is_integral alg),

  obtain ⟨f, rfl⟩ := exists_eq_aeval_primitive_element K L x,
  change (eval₂ (algebra_map K L) (primitive_element K L)) f ∈
    submodule.span K (set.range (power_basis alg)),
  rw [← polynomial.eval₂_mod_by_monic_eq_self_of_root mp_monic (minimal_polynomial.aeval _),
    eval₂_eq_sum, finsupp.sum],
  refine submodule.sum_mem _ (λ i i_mem, _),
  rw ← algebra.smul_def,
  by_cases hi : i < simple_degree alg,
  { exact submodule.smul_mem _ _ (submodule.subset_span ⟨⟨i, hi⟩, rfl⟩) },
  convert submodule.zero_mem _,
  convert zero_smul _ _,
  refine coeff_eq_zero_of_degree_lt _,
  calc (f %ₘ minimal_polynomial _).degree
      < (minimal_polynomial _).degree : degree_mod_by_monic_lt _ mp_monic mp_ne_zero
  ... ≤ (minimal_polynomial _).nat_degree : degree_le_nat_degree
  ... ≤ i : with_bot.some_le_some.mpr (le_of_not_gt hi),
end

lemma power_basis_is_basis : is_basis K (power_basis alg) :=
⟨linear_independent_power_basis alg, eq_top_iff.mpr (λ x _, mem_span_power_basis alg x)⟩

lemma findim_eq_simple_degree : findim K L = simple_degree alg :=
trans (findim_eq_card_basis (power_basis_is_basis alg)) (fintype.card_fin _)

end is_algebraic

section finite_dimensional

@[simp] lemma adjoin_idem (s : set L) :
  algebra.adjoin K (algebra.adjoin K s : set L) = algebra.adjoin K s :=
le_antisymm
  (algebra.adjoin_le (algebra.adjoin_le algebra.subset_adjoin))
  (algebra.adjoin_mono algebra.subset_adjoin)

@[simp] lemma adjoin_insert_adjoin (x : L) (s : set L) :
  algebra.adjoin K (insert x (algebra.adjoin K s : set L)) = algebra.adjoin K (insert x s) :=
le_antisymm
  (algebra.adjoin_le (set.insert_subset.mpr
    ⟨algebra.subset_adjoin (set.mem_insert _ _),
     algebra.adjoin_mono (set.subset_insert _ _)⟩))
  (algebra.adjoin_mono (set.insert_subset_insert algebra.subset_adjoin))

/-- Induction principle for finite dimensional fields: adjoin extra elements until finished. -/
lemma induction_on_adjoin [fd : finite_dimensional K L] {P : subalgebra K L → Prop}
  (base : P ⊥) (ih : ∀ (F : subalgebra K L) (x : L), P F → P (algebra.adjoin K (insert x F)))
  (F : subalgebra K L) : P F :=
begin
  haveI := classical.prop_decidable,
  obtain ⟨t, rfl⟩ : F.fg := F.fg_of_noetherian,
  refine finset.induction_on t _ _,
  { simpa using base },
  intros x t hxt h,
  convert ih _ x h using 1,
  rw [finset.coe_insert, adjoin_insert_adjoin],
end

lemma is_simple_of_extension_eq (x y : L) (a₁ a₂ : K) (ne : a₁ ≠ a₂)
  (extension_eq : algebra.adjoin K {a₁ • x + y} = algebra.adjoin K ({a₂ • x + y} : set L)) :
  is_simple_extension K (algebra.adjoin K ({x, y} : set L)) :=
begin
  rw is_simple_subalgebra_iff,
  have z_mem : a₁ • x + y ∈ algebra.adjoin K {x, y},
  { exact subalgebra.add_mem _
    (subalgebra.smul_mem _ (algebra.subset_adjoin (set.mem_insert _ _)) _)
    (algebra.subset_adjoin (set.subset_insert _ _ (set.mem_singleton _))) },
  have x_mem : x ∈ algebra.adjoin K {a₁ • x + y},
  { rw [← subalgebra.mem_to_submodule, ← submodule.smul_mem_iff _ (sub_ne_zero.mpr ne)],
    have : (a₁ - a₂) • x = (a₁ • x + y) - (a₂ • x + y) := by { rw sub_smul, ring },
    rw this,
    refine submodule.sub_mem _ (algebra.subset_adjoin (set.mem_singleton _)) _,
    rw extension_eq,
    exact algebra.subset_adjoin (set.mem_singleton _) },
  refine ⟨a₁ • x + y, z_mem,
    le_antisymm (algebra.adjoin_le (set.singleton_subset_iff.mpr z_mem))
      (algebra.adjoin_le (set.insert_subset.mpr ⟨x_mem, set.singleton_subset_iff.mpr _⟩))⟩,
  conv_lhs { rw [← add_sub_cancel y (a₁ • x), add_comm] },
  refine submodule.sub_mem _ (algebra.subset_adjoin (set.mem_singleton _)) _,
  exact submodule.smul_mem _ _ x_mem
end

lemma is_simple_of_is_simple_adjoin_insert_singleton [finite_dimensional K L]
  (h : ∀ (x ≠ (0 : L)) y, is_simple_extension K (algebra.adjoin K ({x, y} : set L))) :
  is_simple_extension K L :=
begin
  rw ← is_simple_top_iff,
  generalize : ⊤ = F,
  revert F,

  refine induction_on_adjoin _ _ _ _,
  { intros, exact is_simple_extension.is_simple_bot _ _ },

  rintros F x hF,
  rw [is_simple_subalgebra_iff] at hF,
  obtain ⟨y, hy, hF⟩ := hF,

  by_cases hx : x = 0,
  { have : (0 : L) ∈ (F : set L) := F.zero_mem,
    rw [hx, set.insert_eq_of_mem this, ←hF, adjoin_idem, is_simple_subalgebra_iff],
    exact ⟨y, algebra.subset_adjoin (set.mem_singleton _), rfl⟩ },

  rw [← hF, adjoin_insert_adjoin],
  exact h x hx y
end

open_locale classical

noncomputable instance finsupp.fintype {α β : Type*} [fintype α] [has_zero β] [fintype β] :
  fintype (α →₀ β) :=
fintype.of_injective (λ f x, f x) (λ f g h, finsupp.ext (congr_fun h))

/-- Not an instance because `finite_dimensional K K` will make it loop. -/
noncomputable def fintype_of_finite_dimensional
  [finite_dimensional K L] [fintype K] : fintype L :=
nonempty.some begin
  haveI := classical.prop_decidable,
  obtain ⟨b, hb, fin⟩ := finite_dimensional.exists_is_basis_finite K L,
  haveI : fintype b := nonempty.some fin,
  refine ⟨fintype.of_surjective (λ (f : b →₀ K), finsupp.total b L K coe f) _⟩,
  intro x,
  use is_basis.repr hb x,
  simp [is_basis.total_repr]
end

-- Not an instance because `finite_dimensional K K` will make it loop.
lemma infinite_of_finite_dimensional_infinite [finite_dimensional K L] [infinite L] : infinite K :=
⟨λ h, infinite.not_fintype (show fintype L, by { haveI := h, apply fintype_of_finite_dimensional K L })⟩

/-- Artin's primitive element theorem: if `L / K` is a finite extension
with finitely many intermediate fields `L / F / K`, then `L / K` is a simple extension. -/
lemma is_simple_of_finite_intermediates [finite_dimensional K L]
  [fintype (subalgebra K L)] : is_simple_extension K L :=
begin
  by_cases h : nonempty (fintype L),
  { haveI : fintype L := h.some,
    apply finite_field.is_simple_extension },
  haveI : infinite L := not_nonempty_fintype.mp h,
  apply is_simple_of_is_simple_adjoin_insert_singleton,
  intros x hx y,

  -- We claim that there are `a₁ ≠ a₂ : K` such that adjoining `z₁ := x + a₁ • y`
  -- gives the same field als `z₂ := x + a₂ • y`.
  -- This is the case because there are infinitely many `a₁`, `a₂` and finitely many
  -- fields in between `K` and `L`.
  set zs := { (a • x + y) | a : K },
  set Fs := { (algebra.adjoin K ({z} : set L)) | z : zs },
  set f : zs → Fs := λ z, ⟨_, z, rfl⟩ with f_def,
  haveI := infinite_of_finite_dimensional_infinite K L,
  haveI inf_zs : infinite zs := infinite.of_injective (λ a, ⟨_, a, rfl⟩) (λ a₁ a₂ ha, begin
      simp only [algebra.smul_def, subtype.ext_iff, subtype.coe_mk,
                 add_left_inj, mul_left_inj' hx] at ha,
      exact (algebra_map K L).injective ha
    end),
  haveI fin_Fs : fintype Fs := set.finite.fintype (set.finite.of_fintype _),
  obtain ⟨⟨_, ⟨a₁, rfl⟩⟩, hz⟩ := not_forall.mp (not_injective_infinite_fintype f),
  obtain ⟨⟨_, ⟨a₂, rfl⟩⟩, hz⟩ := not_forall.mp hz,
  obtain ⟨Fz₁_eq_Fz₂, z₁_ne_z₂⟩ := not_imp.mp hz,

  -- The field `K[z₁] = K[z₂]` contains both `x` and `y`, so it must be `K[x, y]`.
  refine is_simple_of_extension_eq K L x y a₁ a₂
    (λ h, z₁_ne_z₂ (by rw [subtype.ext_iff, subtype.coe_mk, subtype.coe_mk, h])) _,
  simpa only [f_def, subtype.ext_iff, subtype.coe_mk] using Fz₁_eq_Fz₂
end

-- TODO: prove the next theorem using the previous and a bunch of Galois theory

section is_separable

variables {L} [is_separable K L] [finite_dimensional K L]
variables (M : Type*) [field M] [algebra K M] [algebra L M] [is_scalar_tower K L M]
variables (x y : L)
variables (splits : splits (algebra_map K M) (is_separable.minimal_polynomial K y))

noncomputable def conjugates : finset M :=
((is_separable.minimal_polynomial K x).map (algebra_map K M)).roots

lemma mem_conjugates_of_eval_eq_zero (z : M)
  (hz : eval₂ (algebra_map K M) z (is_separable.minimal_polynomial K x) = 0) :
  z ∈ conjugates K M x :=
begin
  rwa [conjugates, mem_roots, is_root.def, eval_map],
  exact map_ne_zero (minimal_polynomial.ne_zero _)
end

lemma mem_conjugates_self : (algebra_map _ _ x) ∈ conjugates K M x :=
begin
  apply mem_conjugates_of_eval_eq_zero,
  rw [is_scalar_tower.algebra_map_eq K L, ←hom_eval₂, (algebra_map L M).map_eq_zero],
  apply minimal_polynomial.aeval
end

attribute [irreducible] conjugates

noncomputable def bad_cs : finset K :=
((conjugates K M x).bind (λ x', (conjugates K M y).image
  (λ y', (x' - algebra_map L _ x) / (algebra_map L _ y - y')))).preimage
  _
  (λ x _ y _ h, (algebra_map K _).injective h)

lemma zero_mem_bad_cs : (0 : K) ∈ bad_cs K M x y :=
finset.mem_preimage.mpr (finset.mem_bind.mpr ⟨algebra_map _ _ x, mem_conjugates_self K M x,
  finset.mem_image.mpr ⟨algebra_map _ _ y, mem_conjugates_self K M y, by simp⟩⟩)

@[simp] lemma algebra_map_mk (A : subalgebra R S) (x : S) (h : x ∈ A) : algebra_map A S ⟨x, h⟩ = x :=
rfl

variables [inf_K : infinite K]
include inf_K

noncomputable def c : K :=
classical.some (infinite.exists_not_mem_finset (bad_cs K M x y))

lemma c_spec : c K M x y ∉ bad_cs K M x y :=
classical.some_spec (infinite.exists_not_mem_finset (bad_cs K M x y))

instance adjoin_field (x : L) : field (algebra.adjoin K ({x} : set L)) :=
subalgebra.field_of_algebraic _ algebra.is_algebraic_of_finite

lemma c_ne_zero : c K L x y ≠ 0 :=
λ h, c_spec K L x y (by simpa [h] using zero_mem_bad_cs K L x y)

lemma z_inj {x' y' : M}
  (hx' : x' ∈ conjugates K M x) (hy' : y' ∈ conjugates K M y)
  (h : x' + c K M x y • y' = algebra_map _ _ x + c K M x y • algebra_map _ _ y) :
  x' = algebra_map _ _ x ∧ y' = algebra_map _ _ y :=
begin
  have sub_eq : (x' - algebra_map _ _ x) + c K M x y • (y' - algebra_map _ _ y) = 0,
  { refine trans _ (sub_eq_zero.mpr h),
    rw smul_sub,
    abel },
  have c_spec := c_spec K M x y,
  simp only [bad_cs, not_exists, exists_prop, not_and, finset.mem_preimage,
             finset.mem_bind, finset.mem_image] at c_spec,
  specialize c_spec x' hx' y' hy',
  by_cases y'_eq : (algebra_map L M) y = y',
  { refine ⟨_, y'_eq.symm⟩,
    rw y'_eq at h,
    exact add_right_cancel h },
  exfalso,
  apply c_spec,
  have y'_sub_y_ne_zero := mt sub_eq_zero.mp y'_eq,
  apply div_eq_of_eq_mul y'_sub_y_ne_zero,
  rw [← algebra.smul_def, ← sub_eq_zero, sub_eq_add_neg, ← smul_neg, neg_sub],
  exact sub_eq
end

lemma z_mem : x + c K M x y • y ∈ algebra.adjoin K ({x, y} : set L) :=
subalgebra.add_mem _
  (algebra.subset_adjoin (set.mem_insert _ _))
  (subalgebra.smul_mem _ (algebra.subset_adjoin (set.subset_insert _ _ (set.mem_singleton _))) _)

lemma z_mem' : x + c K M x y • y ∈ algebra.adjoin K ({x + c K M x y • y} : set L) :=
subalgebra.mem_coe.mp (algebra.subset_adjoin (set.mem_singleton _))

noncomputable def f_z : polynomial (algebra.adjoin K ({x + c K M x y • y} : set L)) :=
((is_separable.minimal_polynomial K x).map (algebra_map _ _)).comp
  (C (⟨x + c K M x y • y, z_mem' K M x y⟩ : algebra.adjoin K _) - c K M x y • X)

lemma eval₂_f_z (f : algebra.adjoin K ({x + c K M x y • y} : set L) →+* R) (y' : R) :
  eval₂ f y' (f_z K M x y) =
    eval₂ (f.comp (algebra_map K _))
      (f ⟨x + c K M x y • y, z_mem' K M x y⟩ - f (algebra_map _ _ (c K M x y)) * y')
      (is_separable.minimal_polynomial K x) :=
begin
  rw [f_z, eval₂_comp, eval₂_map, eval₂_sub, eval₂_C, algebra.smul_def (c K M x y) X,
      eval₂_mul, algebra_map_apply, eval₂_C, eval₂_X],
end

lemma aeval_f_z_y : aeval y (f_z K M x y) = 0 :=
show eval₂ (algebra_map _ _) y (f_z K M x y) = 0,
by { rw [eval₂_f_z, algebra_map_mk, ← is_scalar_tower.algebra_map_eq, ← algebra.smul_def,
         is_scalar_tower.algebra_map_smul, add_sub_cancel],
     apply minimal_polynomial.aeval }

lemma mem_conjugates_x_of_root_f_z {y' : M}
  (h : (f_z K M x y).eval₂ ((algebra_map _ M).comp (algebra_map _ L)) y' = 0) :
  algebra_map _ _ (x + c K M x y • y) - c K M x y • y' ∈ conjugates K M x :=
begin
  apply mem_conjugates_of_eval_eq_zero,
  rw eval₂_f_z at h,
  convert h,
  { rw [ring_hom.comp_assoc, is_scalar_tower.algebra_map_eq K L M,
        is_scalar_tower.algebra_map_eq K (algebra.adjoin K ({x + c K M x y • y} : set L)) L] },
  { refine trans (algebra.smul_def _ _) _,
    rw [← ring_hom.comp_apply, ring_hom.comp_assoc, is_scalar_tower.algebra_map_eq K L M,
        is_scalar_tower.algebra_map_eq K (algebra.adjoin K ({x + c K M x y • y} : set L)) L] },
end

noncomputable def g_z : polynomial (algebra.adjoin K ({x + c K M x y • y} : set L)) :=
(is_separable.minimal_polynomial K y).map (algebra_map K (algebra.adjoin K {x + c K M x y • y}))

lemma mem_conjugates_y_of_root_g_z {y' : M}
  (h : (g_z K M x y).eval₂ ((algebra_map _ M).comp (algebra_map _ L)) y' = 0) :
  y' ∈ conjugates K M y :=
begin
  apply mem_conjugates_of_eval_eq_zero,
  rw [g_z, eval₂_map] at h,
  convert h,
  rw [ring_hom.comp_assoc, is_scalar_tower.algebra_map_eq K L M,
      is_scalar_tower.algebra_map_eq K (algebra.adjoin K ({x + c K M x y • y} : set L)) L],
end

lemma eq_y_of_root_f_z_of_root_g_z {y' : M}
  (hf : (f_z K M x y).eval₂ ((algebra_map _ M).comp (algebra_map _ L)) y' = 0)
  (hg : (g_z K M x y).eval₂ ((algebra_map _ M).comp (algebra_map _ L)) y' = 0) :
  y' = algebra_map L M y :=
begin
  have mem_x := mem_conjugates_x_of_root_f_z _ _ _ _ hf,
  have mem_y := mem_conjugates_y_of_root_g_z _ _ _ _ hg,
  refine (z_inj K M x y mem_x mem_y _).2,
  rw [sub_add_cancel, algebra.smul_def, ring_hom.map_add, algebra.smul_def, ring_hom.map_mul,
      ← is_scalar_tower.algebra_map_apply]
end

omit inf_K
lemma right_is_separable_of_is_scalar_tower (K L F : Type*) [field K] [field L] [field F]
  [algebra K F] [algebra F L] [algebra K L] [is_scalar_tower K F L] [is_separable K L] : is_separable F L :=
begin
  intro x,
  have Hx : is_integral F x := is_integral_tower_top_of_is_integral (is_separable.is_integral K x),
  use Hx,
  exact separable.of_dvd
    ((separable_map _).mpr (is_separable.minimal_polynomial_separable K x))
    (minimal_polynomial.dvd_minimal_polynomial_map (is_separable.is_integral K x) Hx)
end

include inf_K
instance adjoin.is_separable :
  is_separable (algebra.adjoin K ({x + c K M x y • y} : set L)) L :=
right_is_separable_of_is_scalar_tower K L (algebra.adjoin K ({x + c K M x y • y} : set L))

noncomputable def minpoly_y :=
is_separable.minimal_polynomial (algebra.adjoin K ({x + c K M x y • y} : set L)) y

lemma minpoly_y_dvd_f_z :
  minpoly_y K M x y ∣ f_z K M x y :=
minimal_polynomial.dvd _ (aeval_f_z_y K M x y)

lemma minpoly_y_dvd_g_z :
  minpoly_y K M x y ∣ g_z K M x y :=
minimal_polynomial.dvd_minimal_polynomial_map (is_separable.is_integral K y) _

include splits
lemma minpoly_y_splits :
  (minpoly_y K M x y).splits
    ((algebra_map L M).comp
      (algebra_map (algebra.adjoin K ({x + c K M x y • y} : set L)) L)) :=
splits_of_splits_of_dvd _
  (map_ne_zero (minimal_polynomial.ne_zero _))
  ((splits_map_iff _ _).mpr (by { rw [ring_hom.comp_assoc, ← is_scalar_tower.algebra_map_eq,
                                      ← is_scalar_tower.algebra_map_eq],
                                  exact splits }))
  (minpoly_y_dvd_g_z K M x y)
omit splits

omit inf_K
lemma eval₂_eq_zero_of_dvd_of_eval₂_eq_zero {f : R →+* S} {p q : polynomial R} {x : S}
  (hpq : p ∣ q) (hxp : eval₂ f x p = 0) : eval₂ f x q = 0 :=
begin
  rcases hpq with ⟨q, rfl⟩,
  rw [eval₂_mul, hxp, zero_mul]
end
include inf_K

lemma roots_minpoly_y :
  roots ((minpoly_y K M x y).map ((algebra_map L M).comp
      (algebra_map (algebra.adjoin K ({x + c K M x y • y} : set L)) L)))
    ≤ ({algebra_map L M y} : finset M) :=
begin
  intros y' hy',
  rw [mem_roots, is_root.def, eval_map] at hy',
  refine finset.mem_singleton.mpr (eq_y_of_root_f_z_of_root_g_z K M x y _ _),
  { exact eval₂_eq_zero_of_dvd_of_eval₂_eq_zero _ _ (minpoly_y_dvd_f_z K M _ _) hy' },
  { exact eval₂_eq_zero_of_dvd_of_eval₂_eq_zero _ _ (minpoly_y_dvd_g_z K M _ _) hy' },
  { exact map_ne_zero (minimal_polynomial.ne_zero _) },
end

include M splits
lemma nat_degree_minpoly_y :
  nat_degree (minpoly_y K M x y) ≤ 1 :=
begin
  erw [nat_degree_separable_eq_card_roots (is_separable.minimal_polynomial_separable _ _) (minpoly_y_splits K M x y splits),
      ← finset.card_singleton _],
  exact finset.card_le_of_subset (roots_minpoly_y K M x y),
end

lemma degree_minpoly_y :
  degree (minpoly_y K M x y) ≤ 1 :=
begin
  erw degree_eq_nat_degree (minimal_polynomial.ne_zero _),
  apply with_bot.some_le_some.mpr,
  exact nat_degree_minpoly_y K M x y splits
end
omit M splits inf_K

-- TODO: good name!
def splitting_field :=
splitting_field ((is_separable.minimal_polynomial K y).map (algebra_map K L))

noncomputable instance : field (splitting_field K y) := splitting_field.field _

noncomputable instance algebra_L : algebra L (splitting_field K y) :=
splitting_field.algebra _

noncomputable instance algebra_K : algebra K (splitting_field K y) :=
ring_hom.to_algebra ((algebra_map L _).comp (algebra_map K L))

instance K_L_splitting_field :
  is_scalar_tower K L (splitting_field K y) :=
is_scalar_tower.of_algebra_map_eq (λ x, rfl)

lemma splitting_field_splits :
  (is_separable.minimal_polynomial K y).splits (algebra_map K (splitting_field K y)) :=
begin
  have := splitting_field.splits
    ((is_separable.minimal_polynomial K y).map (algebra_map K L)),
  rwa splits_map_iff at this,
end

/-- The primitive element theorem: if `L / K` is a separable finite extension,
it is a simple extension. -/
instance is_simple_of_is_separable : is_simple_extension K L :=
begin
  by_cases h : nonempty (fintype L),
  { haveI : fintype L := h.some,
    apply finite_field.is_simple_extension },
  haveI : infinite L := not_nonempty_fintype.mp h,
  haveI := infinite_of_finite_dimensional_infinite K L,
  apply is_simple_of_is_simple_adjoin_insert_singleton,
  intros x hx y,
  rw is_simple_subalgebra_iff,

  use x + c K (splitting_field K y) x y • y,
  use z_mem K _ x y,

  have y_mem : y ∈ algebra.adjoin K {x + c K (splitting_field K y) x y • y},
  { have := degree_minpoly_y K _ x y (splitting_field_splits K y),
    conv_lhs { rw minimal_polynomial.root_eq_algebra_map_of_degree_le_one _ this },
    apply subalgebra.neg_mem,
    exact ((minpoly_y K _ x y).coeff 0).2 },
  have x_mem : x ∈ algebra.adjoin K {x + c K (splitting_field K y) x y • y},
  { rw [← subalgebra.mem_to_submodule, ← submodule.add_mem_iff_left _ (submodule.smul_mem _ _ _)],
    { exact z_mem' K _ x y },
    { exact y_mem } },
  exact le_antisymm
    (algebra.adjoin_le (set.singleton_subset_iff.mpr (z_mem K _ x y)))
    (algebra.adjoin_le (set.insert_subset.mpr
      ⟨subalgebra.mem_coe.mpr x_mem, set.singleton_subset_iff.mpr (subalgebra.mem_coe.mpr y_mem)⟩))
end

end is_separable

end finite_dimensional

end is_simple_extension