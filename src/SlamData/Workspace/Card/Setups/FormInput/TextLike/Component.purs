{-
Copyright 2016 SlamData, Inc.

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

module SlamData.Workspace.Card.Setups.FormInput.TextLike.Component
  ( textLikeSetupComponent
  ) where

import SlamData.Prelude

import Data.Argonaut (JCursor)
import Data.Lens ((^?), (?~), (.~), preview)

import DOM.Event.Event as DEE

import Halogen as H
import Halogen.HTML.Events as HE
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as ARIA
import Halogen.Themes.Bootstrap3 as B

import SlamData.Workspace.Card.Model as Card
import SlamData.Form.Select as S
import SlamData.Workspace.LevelOfDetails (LevelOfDetails(..))
import SlamData.Workspace.Card.Component as CC
import SlamData.Workspace.Card.CardType as CT
import SlamData.Workspace.Card.CardType.FormInputType as FIT
import SlamData.Workspace.Card.Eval.State (_Axes)
import SlamData.Workspace.Card.Setups.Axis as Ax
import SlamData.Workspace.Card.Setups.CSS as CSS
import SlamData.Workspace.Card.Setups.DimensionPicker.Component as DPC
import SlamData.Workspace.Card.Setups.DimensionPicker.JCursor (flattenJCursors)
import SlamData.Workspace.Card.Setups.Inputs as BCI
import SlamData.Workspace.Card.Setups.FormInput.TextLike.Component.ChildSlot as CS
import SlamData.Workspace.Card.Setups.FormInput.TextLike.Component.State as ST
import SlamData.Workspace.Card.Setups.FormInput.TextLike.Component.Query as Q
import SlamData.Workspace.Card.Setups.FormInput.TextLike.Model as M

type DSL = CC.InnerCardParentDSL ST.State Q.Query CS.ChildQuery Unit
type HTML = CC.InnerCardParentHTML Q.Query CS.ChildQuery Unit


textLikeSetupComponent
  ∷ FIT.FormInputType
  → (Ax.Axes → Array JCursor)
  → CC.CardOptions
  → CC.CardComponent
textLikeSetupComponent fit projection =
  CC.makeCardComponent (CT.SetupFormInput fit) $ H.parentComponent
    { render
    , eval: (cardEval fit projection) ⨁ (setupEval projection)
    , receiver: const Nothing
    , initialState: const ST.initialState
    }

render ∷ ST.State → HTML
render state =
  HH.div
    [ HP.classes [ CSS.chartEditor ]
    ]
    [ renderName state
    , HH.hr_
    , renderValue state
    , renderPicker state
    ]

selecting ∷ ∀ a f. (a → Q.Selection BCI.SelectAction) → a → H.Action (f ⨁ Q.Query)
selecting f q a = right (Q.Select (f q) a)

renderPicker ∷ ST.State → HTML
renderPicker state = case state.picker of
  Nothing → HH.text ""
  Just r →
    let
      conf =
        BCI.dimensionPicker r.options
          case r.select of
            Q.Value _ → "Choose value"
    in HH.slot unit (DPC.picker conf) unit (Just ∘ right ∘ H.action ∘ Q.HandleDPMessage)

renderName ∷ ST.State → HTML
renderName state =
  HH.form
    [ HP.classes [ HH.ClassName "chart-configure-input" ]
    , HE.onSubmit $ HE.input \e → right ∘ Q.PreventDefault e
    ]
    [ HH.label [ HP.classes [ B.controlLabel ] ] [ HH.text "Name" ]
    , HH.input
        [ HP.type_ HP.InputText
        , HP.classes [ B.formControl ]
        , HP.placeholder "Form input label"
        , ARIA.label "Form input label"
        , HE.onValueInput $ HE.input \str → right ∘ Q.UpdateName str
        , HP.value state.name
        ]
    ]

renderValue ∷ ST.State → HTML
renderValue state =
  HH.form
    [ HP.classes [ CSS.chartConfigureForm ]
    , HE.onSubmit $ HE.input \e → right ∘ Q.PreventDefault e
    ]
    [ BCI.pickerInput
        (BCI.primary (Just "Value") (selecting Q.Value))
        state.value
    ]

cardEval ∷ FIT.FormInputType → (Ax.Axes → Array JCursor) → CC.CardEvalQuery ~> DSL
cardEval fit proj = case _ of
  CC.Activate next →
    pure next
  CC.Deactivate next →
    pure next
  CC.Save k → do
    st ← H.get
    pure $ k $ Card.setupTextLikeInput fit $ (M.behaviour proj).save st
  CC.Load m next → do
    H.modify $ (M.behaviour proj).load $ join $ preview Card._SetupTextLikeInput m
    pure next
  CC.ReceiveInput _ _ next →
    pure next
  CC.ReceiveOutput _ _ next →
    pure next
  CC.ReceiveState evalState next → do
    for_ (evalState ^? _Axes) \axes → do
      H.modify _{axes = axes}
      H.modify (M.behaviour proj).synchronize
    pure next
  CC.ReceiveDimensions dims reply → do
    pure $ reply
      if dims.width < 576.0 ∨ dims.height < 416.0
      then Low
      else High


raiseUpdate ∷ (Ax.Axes → Array JCursor) → DSL Unit
raiseUpdate proj = do
  H.modify (M.behaviour proj).synchronize
  H.raise CC.modelUpdate

setupEval ∷ (Ax.Axes → Array JCursor) → Q.Query ~> DSL
setupEval proj = case _ of
  Q.PreventDefault e next → do
    H.liftEff $ DEE.preventDefault e
    pure next
  Q.UpdateName str next → do
    H.modify _ { name = str }
    raiseUpdate proj
    pure next
  Q.Select (Q.Value a) next → do
    updatePicker ST._value Q.Value a
    pure next
  Q.HandleDPMessage m next → case m of
    DPC.Dismiss → do
      H.modify _ { picker = Nothing }
      pure next
    DPC.Confirm value → do
      st ← H.get
      let
        v = flattenJCursors value
      for_ st.picker \r → case r.select of
        Q.Value _ → H.modify $ ST._value ∘ S._value ?~ v
      H.modify _ { picker = Nothing }
      raiseUpdate proj
      pure next
  where
  updatePicker l q = case _ of
    BCI.Open opts → H.modify (ST.showPicker q opts)
    BCI.Choose a → H.modify (l ∘ S._value .~ a) *> raiseUpdate proj
