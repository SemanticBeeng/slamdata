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

module SlamData.Workspace.Card.Setups.Chart.Metric.Component.Query where

import Data.Argonaut (JCursor)

import SlamData.Workspace.Card.Setups.Transform.Aggregation (Aggregation)
import SlamData.Workspace.Card.Setups.Inputs (SelectAction)
import SlamData.Workspace.Card.Setups.DimensionPicker.Component (Message)
import SlamData.Workspace.Card.Setups.DimensionPicker.JCursor (JCursorNode)
import Utils.DOM as DOM

data Selection f
  = Value (f JCursor)
  | ValueAgg (f Aggregation)

data Query a
  = SetFormatter String a
  | SetLabel String a
  | Select (Selection SelectAction) a
  | HandleDPMessage (Message JCursorNode) a
  | PreventDefault DOM.Event a
