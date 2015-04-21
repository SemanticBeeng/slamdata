module View.File.Modal where

import Control.Alternative (Alternative)
import Control.Functor (($>))
import Data.Maybe (Maybe(..), maybe)
import Model.File
import qualified Halogen.HTML as H
import qualified Halogen.HTML.Attributes as A
import qualified Halogen.HTML.Events as E
import qualified Halogen.HTML.Events.Handler as E
import qualified Halogen.HTML.Events.Monad as E
import qualified Halogen.Themes.Bootstrap3 as B
import View.File.Modal.ShareDialog

modal :: forall p m. (Alternative m) => (Request -> m Input) -> State -> H.HTML p (m Input)
modal handler state =
  H.div [ A.classes ([B.modal, B.fade] <> maybe [] (const [B.in_]) state.dialog)
        , E.onClick (E.input_ $ SetDialog Nothing)
        ]
        [ H.div [ A.classes [B.modalDialog] ]
                [ H.div [ E.onClick (\_ -> E.stopPropagation $> pure Resort)
                        , A.classes [B.modalContent]
                        ]
                        (modalContent state.dialog)
                ]
        ]

    where

    h4 :: forall i. String -> [H.HTML p i]
    h4 str = [ H.h4_ [H.text str] ]

    section :: forall i. [A.ClassName] -> [H.HTML p i] -> H.HTML p i
    section clss = H.div [A.classes clss]

    header :: forall i. [H.HTML p i] -> H.HTML p i
    header = section [B.modalHeader]

    body :: forall i. [H.HTML p i] -> H.HTML p i
    body = section [B.modalBody]

    footer :: forall i. [H.HTML p i] -> H.HTML p i
    footer = section [B.modalFooter]

    modalContent :: Maybe DialogResume -> [H.HTML p (m Input)]
    modalContent Nothing = []
    modalContent (Just dialog) = dialogContent dialog

    dialogContent :: DialogResume -> [H.HTML p (m Input)]
    dialogContent (ShareDialog url) = shareDialog handler url
    dialogContent MountDialog = emptyDialog "Mount"
    dialogContent RenameDialog = emptyDialog "Rename"
    dialogContent ConfigureDialog = emptyDialog "Configure"

    emptyDialog :: forall i. String -> [H.HTML p i]
    emptyDialog title = [ header $ h4 title
                        , body []
                        , footer []
                        ]
