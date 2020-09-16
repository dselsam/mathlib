import ring_theory.witt_vector.basic

/-!
# Subtraction of Witt vectors

In Lean, subtraction in a ring is by definition equal to `x + -y`.
For Witt vectors, this means that subtraction is not defined in terms of
the polynomials `witt_sub p`.

In this file we define a family of polynomials `poly_add_comp_neg`,
which is the polynomial composition of `witt_add` and `witt_neg` (in the second entry).
It is straightforward to show that the coefficients of `x - y` are
obtained by evaluating `poly_add_comp_neg` on the coefficients of `x` and `y`.

We then show by a computation that `poly_add_comp_neg p` is equal to `witt_sub p`
to deduce in `witt_vector.sub_coeff` that evaluating `witt_sub p` on the coefficients of `x` and `y`
gives the coefficients of `x - y`.
-/

namespace witt_vector

variables {p : ℕ} {R S σ idx : Type*} [hp : fact p.prime] [comm_ring R] [comm_ring S]

local notation `𝕎` := witt_vector p -- type as `\bbW`

local attribute [semireducible] witt_vector
local attribute [instance] mv_polynomial.invertible_rat_coe_nat

open mv_polynomial
local attribute [-simp] coe_eval₂_hom

include hp
variables (p)

section sub_coeff

lemma sub_def (x y : 𝕎 R) : x - y =
  eval (witt_add p) ![x, eval (witt_neg p) ![y]] :=
rfl

/-- The composition of `witt_add` and `witt_neg` (in the second entry).
This gives a polynomial description of the coefficients of `x - y`,
for Witt vectors `x` and `y`.

In `poly_add_comp_neg_eq` we show that this polynomial is equal to `witt_sub`. -/
noncomputable def poly_add_comp_neg : ℕ → mv_polynomial (fin 2 × ℕ) ℤ :=
λ n, bind₁ (function.uncurry $
  ![λ k, X ((0 : fin 2), k),
    λ k, rename (prod.map fin.succ id) (witt_neg p k)])
  (witt_add p n)

lemma sub_eq (x y : 𝕎 R) :
  x - y = eval (poly_add_comp_neg p) ![x, y] :=
begin
  apply ext, intro n,
  dsimp [poly_add_comp_neg, sub_def],
  conv_rhs { rw [eval, coeff_mk, peval, aeval_bind₁] },
  apply eval₂_hom_congr (ring_hom.ext_int _ _) _ rfl,
  ext ⟨b, k⟩, fin_cases b; dsimp [function.uncurry],
  { simp only [aeval_X, matrix.cons_val_zero], },
  { simp only [matrix.head_cons, matrix.cons_val_one, aeval_eq_eval₂_hom, eval₂_hom_rename],
    apply eval₂_hom_congr (ring_hom.ext_int _ _) _ rfl,
    ext ⟨b, i⟩, fin_cases b,
    simp only [function.uncurry, matrix.head_cons, matrix.cons_val_fin_one, function.comp_app,
      matrix.cons_val_one, id.def, fin.succ_zero_eq_one, prod.map_mk], }
end

lemma poly_add_comp_neg_eq : poly_add_comp_neg p = witt_sub p :=
begin
  apply eq_witt_structure_int,
  intro n,
  rw [poly_add_comp_neg, ← bind₁_bind₁, witt_add, witt_structure_int_prop p _ n, bind₁_bind₁,
      alg_hom.map_add, alg_hom.map_sub, sub_eq_add_neg, ← alg_hom.map_neg],
  apply congr₂,
  { rw [bind₁_X_right, bind₁_X_right, bind₁_rename],
    apply eval₂_hom_congr (ring_hom.ext_int _ _) _ rfl,
    ext1 i,
    refl },
  { rw [← witt_structure_int_prop p (- X (1 : fin 2)), bind₁_X_right, bind₁_rename],
    apply eval₂_hom_congr (ring_hom.ext_int _ _) _ rfl,
    ext1 i,
    simp only [function.uncurry, matrix.head_cons, function.comp_app, matrix.cons_val_one],
    rw [witt_neg, ← witt_structure_int_rename, ring_hom.map_neg, rename_X, fin.succ_zero_eq_one] }
end

lemma sub_coeff (x y : 𝕎 R) (n : ℕ) :
  (x - y).coeff n = peval (witt_sub p n) ![x.coeff, y.coeff] :=
by { rw [sub_eq, poly_add_comp_neg_eq, eval, coeff_mk], refl }

end sub_coeff

end witt_vector