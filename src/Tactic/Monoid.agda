
module Tactic.Monoid where

open import Prelude
open import Tactic.Reflection
open import Tactic.Reflection.Quote

open import Structure.Monoid.Laws

open import Tactic.Monoid.Exp
open import Tactic.Monoid.Reflect
open import Tactic.Monoid.Proofs

monoidTactic : ∀ {a} {A : Set a} {MonA : Monoid A} {{_ : MonoidLaws A {{MonA}}}} → Tactic
monoidTactic {A = A} {dict} {{laws}} hole = do
  goal   ← inferNormalisedType hole
  `A     ← quoteTC A
  unify goal (def (quote _≡_) (hArg unknown ∷ hArg `A ∷ vArg unknown ∷ vArg unknown ∷ []))
    <|> do typeError $ strErr "Goal is not an equality" ∷ termErr goal ∷ []
  goal   ← normalise goal
  ensureNoMetas goal
  match  ← monoidMatcher dict
  `dict  ← quoteTC dict
  `laws  ← quoteTC laws
  ensureNoMetas `dict
  debugPrint "tactic.monoid" 20 $ strErr "monoidTactic" ∷ termErr goal ∷ strErr "dict =" ∷ termErr `dict ∷ []
  (lhs , rhs) , env ← parseGoal match goal
  unify hole (def (quote proof) (iArg `dict ∷ iArg `laws ∷ vArg (` lhs) ∷ vArg (` rhs) ∷
                                 vArg (quoteEnv `dict env) ∷ vArg (con (quote refl) []) ∷ []))
    <|> do typeError $ strErr "Can't prove" ∷ termErr (` lhs) ∷ strErr "==" ∷ termErr (` rhs)
                     ∷ strErr "because" ∷ termErr (` (flatten lhs)) ∷ strErr "/=" ∷ termErr (` (flatten rhs))
                     ∷ []

macro
  auto-monoid : ∀ {a} {A : Set a} {Mon : Monoid A} {{Laws : MonoidLaws A {{Mon}}}} → Tactic
  auto-monoid {{Laws}} = monoidTactic {{Laws}}
