module Website.Capability.Resources where

import Prelude

import Data.Argonaut.Core (Json)
import Data.Codec.Argonaut (JsonCodec, printJsonDecodeError)
import Data.Codec.Argonaut as CA
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Effect.Class.Console (log)
import Halogen (HalogenM, lift)
import Website.Data.Resources (BlogPost, LoginCreds, Repository)


class MonadAff m <= ManageBlogPost m where
  getBlogPosts :: m (Maybe (Array BlogPost))


instance manageBlogPostHalogenM
  :: ManageBlogPost m
  => ManageBlogPost (HalogenM state action slots output m) where
  getBlogPosts = lift $ getBlogPosts


class MonadAff m <= ManageRepository m where
  getRepositories :: m (Maybe (Array Repository))


instance manageRepositoryHalogenM
  :: ManageRepository m
  => ManageRepository (HalogenM state action slots output m) where
  getRepositories = lift $ getRepositories


class MonadAff m <= ManageLogin m where
  login :: LoginCreds -> m Boolean


instance manageLoginHalogenM
  :: ManageLogin m
  => ManageLogin (HalogenM state action slots output m) where
  login = lift <<< login



decode :: forall m r. MonadAff m => JsonCodec r -> Maybe Json -> m (Maybe r)
decode _ Nothing = log "Error in obtaining response" *> pure Nothing
decode codec (Just json) =
  case CA.decode codec json of
    Left err -> log (printJsonDecodeError err) *> pure Nothing
    Right result -> pure (Just result)
