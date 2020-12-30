module PF.Pages.Home where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Symbol (SProxy(..))
import Halogen as H
import Halogen.Animated as HN
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import PF.Component.Utils (css)


data Tile
  = Info
  | Projects
  | Socials


derive instance eqTile :: Eq Tile
derive instance ordTile :: Ord Tile


type State = Unit


data Action = TileClicked Tile | TileHovered Tile


type ChildSlots =
  ( _tile_cover :: HN.Slot Action Tile
  , _tile_hover :: HN.Slot Action Tile
  )


_tile_cover :: SProxy "_tile_cover"
_tile_cover = SProxy


_tile_hover :: SProxy "_tile_hover"
_tile_hover = SProxy


component :: forall query input output m. H.Component HH.HTML query input output m
component =
  H.mkComponent
  { initialState
  , render
  , eval: H.mkEval $ H.defaultEval
    { handleAction = handleAction
    }
  }


initialState :: forall input. input -> State
initialState _ = unit


render :: forall m. State -> H.ComponentHTML Action ChildSlots m
render state =
  HH.div [ css "page-root" ]
  [ HH.div [ css "tile-grid" ]
    [ mkTile Info
    , mkTile Projects
    , mkTile Socials
    ]
  ]
  where
    -- | Container for each tile
    mkTile tile =
      HH.div border
      [ HH.div [ css "clipper-container garage-clip" ]
        [ cover
        , content
        ]
      ]
      where
        border = case tile of
          Info -> [ css "border-container-info" ]
          _    -> [ css "border-container" ]

        -- Temporary workaround as I've styled this in a very odd
        -- manner; I could fix this upstream but I can also add a
        -- special class just for this use-case; alternatively, I
        -- could also just simplify my current hierarchy.
        cover =
          HH.slot _tile_cover tile HN.component
          { start: "shut cover-container"
          , toFinal: "close-to-open cover-container"
          , final: "open cover-container"
          , toStart: "open-to-close cover-container"
          , render: renderInner
          } Just
          where
            renderInner =
              HH.div tileCover
              [ HH.div coverFlex coverItems
              , HH.div [ css "fas fa-chevron-down animate-bounce mx-auto mb-5" ] [ ]
              ]
              where
                tileCover =
                  [ css "full-flex"
                  , HE.onClick \_ -> Just $ HN.Raise $ TileClicked tile
                  ]

                coverFlex = case tile of
                  Info -> [ css "cover-flex-info" ]
                  _    -> [ css "cover-flex" ]

                coverItems = case tile of
                  Info ->
                    [ HH.div [ css "cover-items-info-image" ] [  ]
                    , HH.div [ css "cover-items-info-name" ] [ HH.text "PureFunctor" ]
                    , HH.div [ css "cover-items-info-sub" ] [ HH.text "Student, Python, FP" ]
                    ]
                  Projects ->
                    [ HH.div [ css "cover-items-projects-socials" ] [ HH.text "Projects" ]
                    ]
                  Socials ->
                    [ HH.div [ css "cover-items-projects-socials" ] [ HH.text "Socials" ]
                    ]

        content = HH.div [ css "content-container" ] inner
          where
            inner = case tile of
              Info ->
                [ HH.div [ css "p-5" ]
                  [ HH.text "PureFunctor"
                  ]
                ]
              Projects ->
                [ HH.div [ css "p-5" ]
                  [ HH.text "Projects"
                  ]
                ]
              Socials ->
                [ HH.div [ css "p-5" ]
                  [ HH.text "Socials"
                  ]
                ]


handleAction :: forall output m. Action -> H.HalogenM State Action ChildSlots output m Unit
handleAction = case _ of
  (TileClicked tile) -> void $ H.query _tile_cover tile $ H.tell HN.ToggleAnimation
  (TileHovered tile) -> void $ H.query _tile_hover tile $ H.tell HN.ToggleAnimation
