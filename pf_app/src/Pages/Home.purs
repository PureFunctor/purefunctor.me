module Website.Pages.Home where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Symbol (SProxy(..))
import Effect.Aff.Class (class MonadAff)
import Effect.Class.Console (log)
import Halogen as H
import Halogen.HTML as HH
import Website.Capability.Resources (class ManageRepository, getRepositories)
import Website.Component.RepoCard as RepoCard
import Website.Component.Utils (css, css')


type State = Unit
data Action = Initialize
type ChildSlots =
  ( projects :: RepoCard.Slot )


component
  :: forall query input output m.
     MonadAff m
  => ManageRepository m
  => H.Component HH.HTML query input output m
component =
  H.mkComponent
  { initialState
  , render
  , eval: H.mkEval $ H.defaultEval
    { handleAction = handleAction
    , initialize = Just Initialize
    }
  }


initialState :: forall input. input -> Unit
initialState _ = unit


render
  :: forall m.
     MonadAff m
  => ManageRepository m
  => State
  -> H.ComponentHTML Action ChildSlots m
render _ =
  HH.div [ css "bg-gray-100 h-screen overflow-auto scroll-snap-y-proximity"  ]
  [ HH.div [ css "h-auto w-full lg:w-11/12 mx-auto" ]
    [ HH.div [ css "h-screen flex flex-col justify-center items-center space-y-5 scroll-snap-align-start" ]
      [ HH.div [ css "h-56 w-56 bg-green-200 rounded-full shadow-xl" ]
        [
        ]
      , HH.div [ css "text-4xl text-center" ]
        [ HH.text "PureFunctor"
        ]
      , HH.div [ css "text-4xl font-thin text-center" ]
        [ HH.text "Student, Python, FP"
        ]
      ]
    , subsection "h-screen" "About"
      [ HH.div [ css "text-lg p-5" ]
        [ HH.text "Text"
        ]
      ]
    , subsection "min-h-screen" "Projects"
      [ RepoCard.make ( SProxy :: SProxy "projects" ) exampleRepositories
      ]
    , subsection "h-screen" "Contact"
      [ HH.div [ css "text-lg p-5" ]
        [ HH.text "Text"
        ]
      ]
    ]
  ]
  where
    subsection extra title child =
      HH.div [ css' [ extra, "flex flex-col scroll-snap-align-start divide-y-2" ] ] $
      [ HH.div [ css "text-4xl p-5" ]
        [ HH.text title
        ]
      ] <> child

    exampleRepositories =
      [ { name: "amalgam-lisp"
        , owner: "PureFunctor"
        , commits: 453
        , stars: 3
        , description: "LISP-like interpreted language implemented in Python."
        , url: "https://github.com/PureFunctor/amalgam-lisp"
        }
      , { name: "purefunctor.me"
        , owner: "PureFunctor"
        , commits: 333
        , stars: 1
        , description: "My personal portfolio website written in PureScript and Haskell"
        , url: "https://github.com/PureFunctor/purefunctor.me"
        }
      , { name: "dotfiles"
        , owner: "PureFunctor"
        , commits: 28
        , stars: 0
        , description: "Personal dotfiles."
        , url: "https://github.com/PureFunctor/dotfiles"
        }
      , { name: "purefunctor.me"
        , owner: "PureFunctor"
        , commits: 333
        , stars: 1
        , description: "My personal portfolio website written in PureScript and Haskell"
        , url: "https://github.com/PureFunctor/purefunctor.me"
        }
      ]


handleAction
  :: forall output m.
     MonadAff m
  => ManageRepository m
  => Action
  -> H.HalogenM State Action ChildSlots output m Unit
handleAction = case _ of
  Initialize -> do
    mRepositories <- getRepositories
    case mRepositories of
      Just repositories -> log $ show repositories
      Nothing -> log "parsing exception"
