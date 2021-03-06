module Website.Pages.Home where

import Prelude

import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Type.Proxy (Proxy(..))
import Website.Capability.OpenUrl (class OpenUrl)
import Website.Capability.Resources (class ManageRepository)
import Website.Component.Utils (css, css')
import Website.Pages.Home.AboutCard as AboutCard
import Website.Pages.Home.ContactCards as ContactCards
import Website.Pages.Home.ProjectCards as ProjectCards


type State = Unit
type ChildSlots =
  ( projects :: ProjectCards.Slot
  , contacts :: ContactCards.Slot
  )


component
  :: forall query input output m.
     MonadAff m
  => ManageRepository m
  => OpenUrl m
  => H.Component query input output m
component =
  H.mkComponent
  { initialState
  , render
  , eval: H.mkEval $ H.defaultEval
  }


initialState :: forall input. input -> State
initialState _ = unit


render
  :: forall action m.
     MonadAff m
  => ManageRepository m
  => OpenUrl m
  => State
  -> H.ComponentHTML action ChildSlots m
render _ =
  HH.div
  [ css'
    [ "bg-faint h-screen overflow-auto"
    , "lg:scroll-snap-y-proximity no-scroll-snap-type"
    ]
  ]
  [ HH.div [ css "h-auto w-full lg:w-11/12 mx-auto" ]
    [ HH.section
      [ css'
        [ "h-screen flex flex-col"
        , "justify-center items-center space-y-5"
        , "lg:scroll-snap-align-start no-scroll-snap-align"
        ]
      ]
      [ HH.img
        [ css "h-56 w-56 rounded-full shadow-xl ring-2 ring-black"
        , HP.src "https://avatars.githubusercontent.com/u/66708316?v=4"
        , HP.width 256
        , HP.height 256
        , HP.alt "GitHub Profile Picture"
        ]
      , HH.div [ css "text-4xl font-extralight text-center" ]
        [ HH.text "PureFunctor"
        ]
      , HH.div [ css "text-4xl font-thin text-center" ]
        [ HH.text "Student, Python, FP"
        ]
      ]
    , subsection "min-h-screen" "About"
      [ AboutCard.element
      ]
    , subsection "min-h-screen" "Projects"
      [ ProjectCards.make ( Proxy :: Proxy "projects" )
      ]
    , subsection "min-h-screen" "Contact"
      [ ContactCards.make ( Proxy :: Proxy "contacts" )
      ]
    ]
  ]
  where
    subsection extra title child =
      HH.section
      [ css'
        [ extra
        , "flex flex-col"
        , "lg:scroll-snap-align-start no-scroll-snap-align"
        , "divide-y divide-faint-200"
        ]
      ] $
      [ HH.header [ css "font-extralight text-4xl p-5 mx-auto" ]
        [ HH.h1_ [ HH.text title ]
        ]
      ] <> child
