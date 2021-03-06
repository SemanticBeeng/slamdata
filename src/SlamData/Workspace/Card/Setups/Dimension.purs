{-
Copyright 2017 SlamData, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-}

module SlamData.Workspace.Card.Setups.Dimension where

import SlamData.Prelude

import Data.Argonaut (JCursor, class EncodeJson, class DecodeJson, decodeJson, (~>), (:=), (.?), jsonEmptyObject)
import Data.Lens (Lens', lens, Traversal', wander)
import Data.Newtype (un)

import SlamData.Workspace.Card.Setups.Transform (Transform(..))
import SlamData.Workspace.Card.Setups.Transform.Aggregation as Ag

import Test.StrongCheck.Arbitrary (class Arbitrary, arbitrary)
import Test.StrongCheck.Gen as Gen

type JCursorDimension = Dimension JCursor JCursor

data Dimension a b
  = Dimension (Maybe (Category a)) (Category b)

data Category p
  = Static String
  | Projection (Maybe Transform) p

projection ∷ ∀ a b. b → Dimension a b
projection = Dimension Nothing <<< Projection Nothing

projectionWithCategory ∷ ∀ a b. Category a → b → Dimension a b
projectionWithCategory c = Dimension (Just c) <<< Projection Nothing

projectionWithAggregation ∷ ∀ a b. Maybe Ag.Aggregation → b → Dimension a b
projectionWithAggregation t = Dimension Nothing <<< Projection (Aggregation <$> t)

_value ∷ ∀ a b. Lens' (Dimension a b) (Category b)
_value = lens
  (\(Dimension _ b) → b)
  (\(Dimension a _) b → Dimension a b)

_category ∷ ∀ a b. Lens' (Dimension a b) (Maybe (Category a))
_category = lens
  (\(Dimension a _) → a)
  (\(Dimension _ b) a → Dimension a b)

_transform ∷ ∀ p. Traversal' (Category p) (Maybe Transform)
_transform = wander \f → case _ of
  Projection t p → flip Projection p <$> f t
  c → pure c

_projection ∷ ∀ p. Traversal' (Category p) p
_projection = wander \f → case _ of
  Projection t p → Projection t <$> f p
  c → pure c

printCategory ∷ ∀ p. (p → String) → Category p → String
printCategory f = case _ of
  Static str → str
  Projection _ p → f p

isStatic ∷ ∀ p. Category p → Boolean
isStatic = case _ of
  Static _ → true
  _ → false

derive instance eqDimension ∷ (Eq a, Eq b) ⇒ Eq (Dimension a b)
derive instance eqCategory ∷ Eq p ⇒ Eq (Category p)

derive instance ordDimension ∷ (Ord a, Ord b) ⇒ Ord (Dimension a b)
derive instance ordCategory ∷ Ord p ⇒ Ord (Category p)

derive instance functorDimension ∷ Functor (Dimension a)
derive instance functorCategory ∷ Functor Category

instance bifunctorDimension ∷ Bifunctor Dimension where
  bimap f g (Dimension a b) = Dimension (map f <$> a) (g <$> b)

instance encodeJsonDimension ∷ (EncodeJson a, EncodeJson b) ⇒ EncodeJson (Dimension a b) where
  encodeJson (Dimension category value) = "value" := value ~> "category" := category ~> jsonEmptyObject

instance encodeJsonCategory ∷ EncodeJson p ⇒ EncodeJson (Category p) where
  encodeJson = case _ of
    Static value → "type" := "static" ~> "value" := value ~> jsonEmptyObject
    Projection transform value → "type" := "projection" ~> "value" := value ~> "transform" := transform ~> jsonEmptyObject

instance decodeJsonDimension ∷ (DecodeJson a, DecodeJson b) ⇒ DecodeJson (Dimension a b) where
  decodeJson json = do
    obj ← decodeJson json
    Dimension <$> obj .? "category" <*> obj .? "value"

instance decodeJsonCategory ∷ DecodeJson p ⇒ DecodeJson (Category p) where
  decodeJson json = do
    obj ← decodeJson json
    obj .? "type" >>= case _ of
      "static" → Static <$> obj .? "value"
      "projection" → Projection <$> obj .? "transform" <*> obj .? "value"
      ty → throwError $ "Invalid category type: " <> ty

instance arbitraryDimension ∷ (Arbitrary a, Arbitrary b) ⇒ Arbitrary (Dimension a b) where
  arbitrary = Dimension <$> arbitrary <*> arbitrary

instance arbitraryCategory ∷ Arbitrary p ⇒ Arbitrary (Category p) where
  arbitrary = Gen.chooseInt 1 2 >>= case _ of
    1 → Static <$> arbitrary
    _ → Projection <$> arbitrary <*> arbitrary

newtype DimensionWithStaticCategory a = DimensionWithStaticCategory (Dimension Void a)

newtype StaticCategory = StaticCategory (Category Void)

derive instance functorDimensionWithStaticCategory ∷ Functor DimensionWithStaticCategory
derive instance newtypeDimensionWithStaticCategory ∷ Newtype (DimensionWithStaticCategory a) _
derive instance newtypeStaticCategory ∷ Newtype StaticCategory _

instance arbitraryDimensionWithStaticCategory ∷ Arbitrary a ⇒ Arbitrary (DimensionWithStaticCategory a) where
  arbitrary = DimensionWithStaticCategory
    <$> (Dimension <$> (map (un StaticCategory) <$> arbitrary) <*> arbitrary)

instance arbitraryStaticCategory ∷ Arbitrary StaticCategory where
  arbitrary = StaticCategory ∘ Static <$> arbitrary
