/-
Copyright (c) 2020 Eric Wieser. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Wieser
-/
import group_theory.perm.basic
import data.fintype.basic
import group_theory.subgroup
/-!
# Lemmas about subgroups within the permutations (self-equivalences) of a type `α`

This file provides extra lemmas about some `subgroup`s that exist within `equiv.perm α`.
`group_theory.subgroup` depends on `group_theory.perm.basic`, so these need to be in a separate
file.
-/

namespace equiv
namespace perm

universes u

@[simp]
lemma sum_congr_hom.card_range {α β : Type*}
  [fintype (sum_congr_hom α β).range] [fintype (perm α × perm β)] :
  fintype.card (sum_congr_hom α β).range = fintype.card (perm α × perm β) :=
fintype.card_eq.mpr ⟨(set.range (sum_congr_hom α β) sum_congr_hom_injective).symm⟩

@[simp]
lemma sigma_congr_right_hom.card_range {α : Type*} {β : α → Type*}
  [fintype (sigma_congr_right_hom β).range] [fintype (Π a, perm (β a))] :
  fintype.card (sigma_congr_right_hom β).range = fintype.card (Π a, perm (β a)) :=
fintype.card_eq.mpr ⟨(set.range (sigma_congr_right_hom β) sigma_congr_right_hom_injective).symm⟩

@[simp]
lemma subtype_congr_hom.card_range {α : Type*} (p : α → Prop) [decidable_pred p]
  [fintype (subtype_congr_hom p).range] [fintype (perm {a // p a} × perm {a // ¬ p a})] :
  fintype.card (subtype_congr_hom p).range = fintype.card (perm {a // p a} × perm {a // ¬ p a}) :=
fintype.card_eq.mpr ⟨(set.range (subtype_congr_hom p) (subtype_congr_hom_injective p)).symm⟩


end perm
end equiv
