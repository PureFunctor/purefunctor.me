module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Routing.Duplex (parse)
import Routing.Hash (matchesWith)
import Routing.PushState (makeInterface)
import Website.AppM (runAppM)
import Website.Component.Router as Router
import Website.Data.Routes as Routes


main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody

  pushInterface <- liftEffect makeInterface

  let
    rootComponent ∷ H.Component HH.HTML Router.Query Unit Void Aff
    rootComponent = H.hoist (runAppM { pushInterface }) Router.component

  halogenIO <- runUI rootComponent unit body

  void $ liftEffect $ matchesWith (parse Routes.routeCodec) \old new ->
    when (old /= Just new) do
      launchAff_ $ halogenIO.query $ H.tell $ Router.Navigate new
