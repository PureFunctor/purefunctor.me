{-# LANGUAGE DataKinds              #-}
{-# LANGUAGE DeriveAnyClass         #-}
{-# LANGUAGE DeriveGeneric          #-}
{-# LANGUAGE DuplicateRecordFields  #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE OverloadedStrings      #-}
{-# LANGUAGE TemplateHaskell        #-}
{-# LANGUAGE TypeOperators          #-}
module Website.API.Repo where

import Control.Lens

import Control.Monad ( void )
import Control.Monad.IO.Class ( liftIO )
import Control.Monad.Reader ( asks )

import Data.Aeson ( FromJSON, ToJSON )

import Data.Maybe ( fromMaybe )

import           Data.Text ( Text )
import qualified Data.Text as Text

import Data.Time ( getCurrentTime )

import Database.Persist.Sqlite

import GHC.Generics ( Generic )

import Servant
import Servant.Auth
import Servant.Auth.Server

import Control.Applicative
import Website.API.Auth
import Website.API.Common
import Website.Config
import Website.Models
import Website.Utils
import Website.WebsiteM


type RepositoryAPI =
  "repo" :>

    ( Get '[JSON] [Repository] :<|>

      Capture "name" Text :> Get '[JSON] Repository :<|>

      ( Auth '[JWT, Cookie] LoginPayload :>
        ( ReqBody '[JSON] MutableRepositoryData :> Post '[JSON] MutableEndpointResult
        )
      )

    )


data MutableRepositoryData
  = MutableRepositoryData
      { _name    :: Maybe Text
      , _owner   :: Maybe Text
      , _url     :: Maybe Text
      , _stars   :: Maybe Int
      , _commits :: Maybe Int
      }

deriveJSON' ''MutableRepositoryData
makeLenses ''MutableRepositoryData


repositoryServer :: ServerT RepositoryAPI WebsiteM
repositoryServer = getRepositories :<|> getRepository :<|> mkRepository
  where
    getRepositories :: WebsiteM [Repository]
    getRepositories = do
      pool <- asks connPool

      repositories <- liftIO $ flip runSqlPersistMPool pool $
        selectList [ ] [ ]

      return $ entityVal <$> repositories

    getRepository :: Text -> WebsiteM Repository
    getRepository n = do
      pool <- asks connPool

      repository <- liftIO $ flip runSqlPersistMPool pool $
        selectFirst [ RepositoryName ==. n ] [ ]

      case repository of
        (Just repository') -> return $ entityVal repository'
        Nothing            -> throwError err404

    mkRepository :: AuthResult LoginPayload -> MutableRepositoryData -> WebsiteM MutableEndpointResult
    mkRepository (Authenticated login) payload = do
      pool <- asks connPool

      let autoUrl owner name = Text.concat [ "https://github.com" , owner , "/" , name ]

      let mRepo = Repository
            <$> payload ^. name
            <*> payload ^. owner
            <*> ( payload ^. url <|>
                  autoUrl
                    <$> payload ^. owner
                    <*> payload ^. name
                )
            <*> payload ^. stars
            <*> payload ^. commits

      case mRepo of

        Just repo -> do
          void $ liftIO $ flip runSqlPersistMPool pool $ insert repo
          return $ MutableEndpointResult 200 $ "Repository created: " <> repositoryName repo

        Nothing -> throwError err400

    mkRepository _ _ = throwError err401
