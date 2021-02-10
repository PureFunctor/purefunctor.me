module Website.API.Repo where

import Control.Applicative

import Control.Lens

import Control.Monad ( void )
import Control.Monad.IO.Class ( liftIO )
import Control.Monad.Reader ( ask, asks )

import Data.Maybe ( fromMaybe, isJust )

import           Data.Text ( Text )
import qualified Data.Text as Text

import Database.Persist.Sqlite

import Servant
import Servant.Auth.Server

import Website.API.Auth
import Website.API.Common
import Website.Config
import Website.Models
import Website.Utils
import Website.Tasks
import Website.WebsiteM


type RepositoryAPI =
  "repo" :>

    ( Get '[JSON] [Repository] :<|>

      Capture "name" Text :> Get '[JSON] Repository :<|>

      RequiresAuth
        :> ReqBody '[JSON] MutableRepositoryData
          :> Post '[JSON] MutableEndpointResult :<|>

      RequiresAuth
        :> Capture "name" Text
          :> ReqBody '[JSON] MutableRepositoryData
            :> Put '[JSON] MutableEndpointResult :<|>

      RequiresAuth
        :> Capture "name" Text
          :> Delete '[JSON] MutableEndpointResult
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
repositoryServer =
  getRepositories :<|> getRepository :<|>
  createRepository :<|> updateRepository :<|> deleteRepository
  where
    getRepositories :: WebsiteM [Repository]
    getRepositories = do
      pool' <- asks $ view pool

      repositories <- liftIO $ flip runSqlPersistMPool pool' $
        selectList [ ] [ ]

      return $ entityVal <$> repositories

    getRepository :: Text -> WebsiteM Repository
    getRepository n = do
      pool' <- asks $ view pool

      repository <- liftIO $ flip runSqlPersistMPool pool' $
        selectFirst [ RepositoryName ==. n ] [ ]

      case repository of
        (Just repository') -> return $ entityVal repository'
        Nothing            -> throwError err404

    createRepository
      :: AuthResult LoginPayload
      -> MutableRepositoryData
      -> WebsiteM MutableEndpointResult
    createRepository (Authenticated _) payload = do
      env <- ask

      let autoUrl o n = Text.concat [ "https://github.com" , o , "/" , n ]

      let mRepo = Repository
            <$> payload^.name
            <*> payload^.owner
            <*> ( payload^.url <|>
                  autoUrl
                    <$> payload^.owner
                    <*> payload^.name
                )
            <*> Just 0
            <*> Just 0

      case mRepo of
        Just repo -> do
          mStats <- liftIO $ getRepositoryStats env repo

          repoKey <- liftIO $ flip runSqlPersistMPool (env^.pool) $
            insert $ case mStats of
              Just (ghStars, ghCommits) ->
                repo { repositoryStars = fromMaybe ghStars $ payload^.stars
                     , repositoryCommits = fromMaybe ghCommits $ payload^.commits
                     }
              Nothing -> repo

          return $
            MutableEndpointResult 200 $
              "Repository created: " <> unRepositoryKey repoKey

        Nothing -> throwError err400

    createRepository _ _ = throwError err401

    updateRepository
      :: AuthResult LoginPayload
      -> Text
      -> MutableRepositoryData
      -> WebsiteM MutableEndpointResult
    updateRepository (Authenticated _) rName payload = do
      pool' <- asks $ view pool

      let mUpdates = filter isJust
            [ (RepositoryName    =.) <$> payload ^. name
            , (RepositoryOwner   =.) <$> payload ^. owner
            , (RepositoryUrl     =.) <$> payload ^. url
            , (RepositoryStars   =.) <$> payload ^. stars
            , (RepositoryCommits =.) <$> payload ^. commits
            ]

      case mUpdates of

        [] -> throwError err400

        mUpdates' -> do
          case sequenceA mUpdates' of

            Just updates -> do
              void $ liftIO $ flip runSqlPersistMPool pool' $
                update (RepositoryKey rName) updates
              return $ MutableEndpointResult 200 "Repository updated."

            Nothing -> throwError err400

    updateRepository _ _ _ = throwError err401

    deleteRepository
      :: AuthResult LoginPayload
      -> Text
      -> WebsiteM MutableEndpointResult
    deleteRepository (Authenticated _) rName = do
      pool' <- asks $ view pool

      inDatabase <- liftIO $ flip runSqlPersistMPool pool' $
        exists [ RepositoryName ==. rName ]

      if inDatabase
        then do
          liftIO $ flip runSqlPersistMPool pool' $ delete $ RepositoryKey rName
          return $ MutableEndpointResult 200 "Repository deleted."
        else
          throwError err404

    deleteRepository _ _ = throwError err401
