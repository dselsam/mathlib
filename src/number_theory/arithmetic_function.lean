/-
Copyright (c) 2020 Aaron Anderson. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Aaron Anderson
-/
import algebra.big_operators.ring
import number_theory.divisors

/-!
# Arithmetic Functions and Dirichlet Convolution

This file defines arithmetic functions, which are functions from `ℕ` to a specified type that map 0
to 0. In the literature, they are often instead defined as functions from `ℕ+`. These arithmetic
functions are endowed with a multiplication, given by Dirichlet convolution, and pointwise addition,
to form the Dirichlet ring.

## Main Definitions
 * `arithmetic_function α` consists of functions `f : ℕ → α` such that `f 0 = 0`.

## Tags
arithmetic functions, dirichlet convolution, divisors

-/

open finset
open_locale big_operators

namespace nat
variable (α : Type*)

/-- An arithmetic function is a function from `ℕ` that maps 0 to 0. In the literature, they are
  often instead defined as functions from `ℕ+`. Multiplication on `arithmetic_functions` is by
  Dirichlet convolution. -/
structure arithmetic_function [has_zero α] :=
(to_fun : ℕ → α)
(map_zero' : to_fun 0 = 0)

variable {α}

namespace arithmetic_function

section has_zero
variable [has_zero α]

instance : has_zero (arithmetic_function α) := ⟨⟨λ _, 0, rfl⟩⟩

instance : inhabited (arithmetic_function α) := ⟨0⟩

instance : has_coe_to_fun (arithmetic_function α) := ⟨λ _, ℕ → α, to_fun⟩

theorem coe_inj ⦃f g : arithmetic_function α⦄ (h : (f : ℕ → α) = g) : f = g :=
by cases f; cases g; cases h; refl

@[ext] theorem ext ⦃f g : arithmetic_function α⦄ (h : ∀ x, f x = g x) : f = g :=
coe_inj (funext h)

theorem ext_iff {f g : arithmetic_function α} : f = g ↔ ∀ x, f x = g x :=
⟨λ h x, h ▸ rfl, λ h, ext h⟩

@[simp]
lemma map_zero {f : arithmetic_function α} : f 0 = 0 := f.map_zero'

@[simp]
lemma zero_apply {x : ℕ} : (0 : arithmetic_function α) x = 0 := rfl

section has_one
variable [has_one α]

instance : has_one (arithmetic_function α) := ⟨⟨λ x, ite (x = 1) 1 0, rfl⟩⟩

@[simp]
lemma one_one : (1 : arithmetic_function α) 1 = 1 := rfl

@[simp]
lemma one_apply_of_ne_one {x : ℕ} (h : x ≠ 1) : (1 : arithmetic_function α) x = 0 := if_neg h

end has_one
end has_zero

instance nat_coe [semiring α] : has_coe (arithmetic_function ℕ) (arithmetic_function α) :=
⟨λ f, ⟨↑(f : ℕ → ℕ), by { transitivity ↑(f 0), refl, simp }⟩⟩

@[simp]
lemma nat_coe_apply [semiring α] {f : arithmetic_function ℕ} {x : ℕ} :
  (f : arithmetic_function α) x = f x := rfl

instance int_coe [ring α] : has_coe (arithmetic_function ℤ) (arithmetic_function α) :=
⟨λ f, ⟨↑(f : ℕ → ℤ), by { transitivity ↑(f 0), refl, simp }⟩⟩

@[simp]
lemma int_coe_apply [ring α] {f : arithmetic_function ℤ} {x : ℕ} :
  (f : arithmetic_function α) x = f x := rfl

@[simp]
lemma coe_coe [ring α] {f : arithmetic_function ℕ} :
  ((f : arithmetic_function ℤ) : arithmetic_function α) = f :=
by { ext, simp, }

section add_monoid

variable [add_monoid α]

instance : has_add (arithmetic_function α) := ⟨λ x y, ⟨λ n, x n + y n, by simp⟩⟩

@[simp]
lemma add_apply {f g : arithmetic_function α} {n : ℕ} : (f + g) n = f n + g n := rfl

instance : add_monoid (arithmetic_function α) :=
{ add_assoc := λ _ _ _, ext (λ _, add_assoc _ _ _),
  zero_add := λ _, ext (λ _, zero_add _),
  add_zero := λ _, ext (λ _, add_zero _),
  .. (infer_instance : has_zero (arithmetic_function α)),
  .. (infer_instance : has_add (arithmetic_function α)) }

end add_monoid

instance [add_comm_monoid α] : add_comm_monoid (arithmetic_function α) :=
{ add_comm := λ _ _, ext (λ _, add_comm _ _),
  .. (infer_instance : add_monoid (arithmetic_function α)) }

instance [add_group α] : add_group (arithmetic_function α) :=
{ neg := λ f, ⟨λ n, - f n, by simp⟩,
  add_left_neg := λ _, ext (λ _, add_left_neg _),
  .. (infer_instance : add_monoid (arithmetic_function α)) }

instance [add_comm_group α] : add_comm_group (arithmetic_function α) :=
{ .. (infer_instance : add_comm_monoid (arithmetic_function α)),
  .. (infer_instance : add_group (arithmetic_function α)) }

section dirichlet_ring
variable [semiring α]

/-- The Dirichlet convolution of two arithmetic functions `f` and `g` is another arithmetic function
  such that `(f * g) n` is the sum of `f x * g y` over all `(x,y)` such that `x * y = n`. -/
def convolve (f g : arithmetic_function α) : arithmetic_function α :=
⟨λ n, ∑ x in divisors_antidiagonal n, f x.fst * g x.snd, by simp⟩

@[simp]
lemma convolve_apply {f g : arithmetic_function α} {n : ℕ} :
  (convolve f g) n = ∑ x in divisors_antidiagonal n, f x.fst * g x.snd := rfl

@[simp]
lemma one_convolve (f : arithmetic_function α) : convolve 1 f = f :=
begin
  ext,
  rw convolve_apply,
  by_cases x0 : x = 0, {simp [x0]},
  have h : {(1,x)} ⊆ divisors_antidiagonal x := by simp [x0],
  rw ← sum_subset h, {simp},
  intros y ymem ynmem,
  have y1ne : y.fst ≠ 1,
  { intro con,
    simp only [con, mem_divisors_antidiagonal, one_mul, ne.def] at ymem,
    simp only [mem_singleton, prod.ext_iff] at ynmem,
    tauto },
  simp [y1ne],
end

@[simp]
lemma convolve_one (f : arithmetic_function α) : convolve f 1 = f :=
begin
  ext,
  rw convolve_apply,
  by_cases x0 : x = 0, {simp [x0]},
  have h : {(x,1)} ⊆ divisors_antidiagonal x := by simp [x0],
  rw ← sum_subset h, {simp},
  intros y ymem ynmem,
  have y2ne : y.snd ≠ 1,
  { intro con,
    simp only [con, mem_divisors_antidiagonal, mul_one, ne.def] at ymem,
    simp only [mem_singleton, prod.ext_iff] at ynmem,
    tauto },
  simp [y2ne],
end

@[simp]
lemma zero_convolve (f : arithmetic_function α) : convolve 0 f = 0 :=
by { ext, simp }

@[simp]
lemma convolve_zero (f : arithmetic_function α) : convolve f 0 = 0 :=
by { ext, simp }

lemma convolve_assoc (f g h : arithmetic_function α) :
  convolve (convolve f g) h = convolve f (convolve g h) :=
begin
  ext n,
  simp only [convolve_apply],
  have := @finset.sum_sigma (ℕ × ℕ) α _ _ (divisors_antidiagonal n)
    (λ p, (divisors_antidiagonal p.1)) (λ x, f x.2.1 * g x.2.2 * h x.1.2),
  convert this.symm using 1; clear this,
  { apply finset.sum_congr rfl,
    intros p hp, exact finset.sum_mul },
  have := @finset.sum_sigma (ℕ × ℕ) α _ _ (divisors_antidiagonal n)
    (λ p, (divisors_antidiagonal p.2)) (λ x, f x.1.1 * (g x.2.1 * h x.2.2)),
  convert this.symm using 1; clear this,
  { apply finset.sum_congr rfl, intros p hp, rw finset.mul_sum },
  apply finset.sum_bij,
  swap 5,
  { rintros ⟨⟨i,j⟩, ⟨k,l⟩⟩ H, exact ⟨(k, l*j), (l, j)⟩ },
  { rintros ⟨⟨i,j⟩, ⟨k,l⟩⟩ H,
    simp only [finset.mem_sigma, mem_divisors_antidiagonal] at H ⊢, finish },
  { rintros ⟨⟨i,j⟩, ⟨k,l⟩⟩ H, simp only [mul_assoc] },
  { rintros ⟨⟨a,b⟩, ⟨c,d⟩⟩ ⟨⟨i,j⟩, ⟨k,l⟩⟩ H₁ H₂,
    simp only [finset.mem_sigma, mem_divisors_antidiagonal,
      and_imp, prod.mk.inj_iff, add_comm, heq_iff_eq] at H₁ H₂ ⊢,
    finish },
  { rintros ⟨⟨i,j⟩, ⟨k,l⟩⟩ H, refine ⟨⟨(i*k, l), (i, k)⟩, _, _⟩;
    { simp only [finset.mem_sigma, mem_divisors_antidiagonal] at H ⊢, finish } }
end

lemma convolve_add (a b c : arithmetic_function α) :
  convolve a (b + c) = convolve a b + convolve a c :=
by { ext, simp [← sum_add_distrib, mul_add] }

lemma add_convolve (a b c : arithmetic_function α) :
  convolve (a + b) c = convolve a c + convolve b c :=
by { ext, simp [← sum_add_distrib, add_mul] }

instance : has_mul (arithmetic_function α) := ⟨convolve⟩

@[simp]
lemma mul_apply {f g : arithmetic_function α} {n : ℕ} :
  (f * g) n = ∑ x in divisors_antidiagonal n, f x.fst * g x.snd := rfl

instance : semiring (arithmetic_function α) :=
{ one_mul := one_convolve,
  mul_one := convolve_one,
  zero_mul := zero_convolve,
  mul_zero := convolve_zero,
  mul_assoc := convolve_assoc,
  left_distrib := convolve_add,
  right_distrib := add_convolve,
  .. (infer_instance : has_one (arithmetic_function α)),
  .. (infer_instance : has_mul (arithmetic_function α)),
  .. (infer_instance : add_comm_monoid (arithmetic_function α)) }

end dirichlet_ring

lemma convolve_comm [comm_semiring α] (f g : arithmetic_function α) : convolve f g = convolve g f :=
begin
  ext,
  rw [convolve_apply, ← map_swap_divisors_antidiagonal, sum_map],
  simp [mul_comm],
end

instance [comm_semiring α] : comm_semiring (arithmetic_function α) :=
{ mul_comm := convolve_comm,
  .. (infer_instance : semiring (arithmetic_function α)) }

instance [comm_ring α] : comm_ring (arithmetic_function α) :=
{ .. (infer_instance : add_comm_group (arithmetic_function α)),
  .. (infer_instance : comm_semiring (arithmetic_function α)) }

end arithmetic_function
end nat
