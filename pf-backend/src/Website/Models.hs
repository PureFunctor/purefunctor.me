{-# LANGUAGE FlexibleContexts #-}
module Website.Models where

import Control.Lens ( (^.) )

import Control.Monad.IO.Class ( MonadIO(liftIO) )

import Data.Text ( Text )
import Data.Time ( UTCTime )

import Database.Persist.Sqlite ( SqlPersistM, runSqlPersistMPool )

import qualified Database.Persist.TH as PTH

import Website.Config ( Environment, HasPool(pool) )


PTH.share [PTH.mkPersist PTH.sqlSettings, PTH.mkMigrate "migrateAll"] [PTH.persistLowerCase|
  BlogPost json sql=post
    title Text
    short Text
    contents Text
    published UTCTime
    updated UTCTime
    Primary short
    deriving Eq Show
  Repository json sql=repo
    name Text
    owner Text
    url Text
    description Text
    stars Int
    commits Int
    Primary name
    deriving Eq Show
|]


runDb :: MonadIO m => Environment -> SqlPersistM r -> m r
runDb env sql = liftIO $ runSqlPersistMPool sql (env^.pool)