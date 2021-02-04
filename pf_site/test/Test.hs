module Main (main) where

import Test.Auth
import Test.Blog
import Test.Data
import Test.Hspec

import Website.Config
import Website.Debug


main :: IO ()
main = do
  (config, app) <- mkDebug posts repos

  hspec $ do
    testAuth config app
    testBlog config app
