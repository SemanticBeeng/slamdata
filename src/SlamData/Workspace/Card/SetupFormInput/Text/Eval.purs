module SlamData.Workspace.Card.SetupFormInput.Text.Eval
  ( eval
  , module SlamData.Workspace.Card.SetupFormInput.Text.Model
  ) where

import SlamData.Prelude

import Quasar.Types (FilePath)

import SlamData.Quasar.Class (class QuasarDSL)
import SlamData.Quasar.Error as QE
import SlamData.Workspace.Card.CardType.FormInputType (FormInputType(Text))
import SlamData.Workspace.Card.Port as Port
import SlamData.Workspace.Card.Eval.CardEvalT as CET
import SlamData.Workspace.Card.BuildChart.Axis (Axes)
import SlamData.Workspace.Card.SetupFormInput.Text.Model (Model)

eval
  ∷ ∀ m
  . (Monad m, QuasarDSL m)
  ⇒ Model
  → FilePath
  → Axes
  → CET.CardEvalT m Port.Port
eval Nothing _ _ =
  QE.throw "Please select value"
eval (Just conf) resource axes = do
  let
    fiPort =
      { formInputType: Text
      , name: conf.name
      , value: Just conf.value
      , label: conf.label
      , selected: Nothing
      }
  pure $ Port.FormInputParams fiPort
