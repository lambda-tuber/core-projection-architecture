{-# LANGUAGE OverloadedStrings #-}

module CPA.Request.Boot.BootstrapSpec (spec) where

import Test.Hspec
import Control.Concurrent.Async        (async, wait)
import Control.Concurrent.STM
import Control.Concurrent              (threadDelay)
import Control.Monad.Logger

import CPA.Multiverse.CoreModel.Type
import CPA.Request.ApplicationBase.Control  (run)
import CPA.Request.ApplicationBase.State.Run (parseRequest)
import qualified Data.Text as T

--------------------------------------------------------------------------------
-- テスト用ヘルパー
--------------------------------------------------------------------------------

makeTestContext :: IO GlobalContext
makeTestContext = do
  reqQ <- newTQueueIO
  semQ <- newTQueueIO
  ontQ <- newTQueueIO
  resQ <- newTQueueIO
  return GlobalContext
    { _requestQueueGlobalContext     = reqQ
    , _semanticQueueGlobalContext    = semQ
    , _ontologicalQueueGlobalContext = ontQ
    , _responseQueueGlobalContext    = resQ
    , _logLevelGlobalContext         = LevelDebug
    , _logDirGlobalContext           = ""
    }

-- | テスト用モック readLine：TQueue (Maybe T.Text) から読む
mockReadLine :: TQueue (Maybe T.Text) -> IO (Maybe T.Text)
mockReadLine q = atomically $ readTQueue q

-- | requestQueue から全件取り出す（run が停止した後に呼ぶ）
drainRequestQueue :: GlobalContext -> IO [Request]
drainRequestQueue ctx = atomically $ flushTQueue (_requestQueueGlobalContext ctx)

-- | run をモック readLine で非同期起動し、テストアクションを実行して wait する
withMockRun :: TQueue (Maybe T.Text) -> GlobalContext -> IO () -> IO ()
withMockRun lineQ ctx testAction = do
  a <- async (run (mockReadLine lineQ) ctx)
  threadDelay 30000
  testAction
  wait a

--------------------------------------------------------------------------------
-- Spec
--------------------------------------------------------------------------------

spec :: Spec
spec = do

  -- -------------------------------------------------------------------------
  -- parseRequest 単体テスト
  -- -------------------------------------------------------------------------
  describe "parseRequest" $ do

    it "heal → Just Heal" $
      parseRequest "heal" `shouldBe` Just Heal

    it "magical-calamity → Just MagicalCalamity" $
      parseRequest "magical-calamity" `shouldBe` Just MagicalCalamity

    it "quit → Just Quit" $
      parseRequest "quit" `shouldBe` Just Quit

    it "attacked 42 → Just (Attacked 42)" $
      parseRequest "attacked 42" `shouldBe` Just (Attacked 42)

    it "attacked -5 → Just (Attacked (-5))" $
      parseRequest "attacked -5" `shouldBe` Just (Attacked (-5))

    it "attacked （引数なし）→ Nothing" $
      parseRequest "attacked " `shouldBe` Nothing

    it "attacked abc → Nothing" $
      parseRequest "attacked abc" `shouldBe` Nothing

    it "unknown → Nothing" $
      parseRequest "unknown" `shouldBe` Nothing

    it "空文字列 → Nothing" $
      parseRequest "" `shouldBe` Nothing

  -- -------------------------------------------------------------------------
  -- pipeline 統合テスト
  -- -------------------------------------------------------------------------
  describe "pipeline 統合テスト" $ do

    it "heal → quit を送ったとき requestQueue に [Heal, Quit] が届くこと" $ do
      ctx   <- makeTestContext
      lineQ <- newTQueueIO
      withMockRun lineQ ctx $ do
        atomically $ do
          writeTQueue lineQ (Just "heal")
          writeTQueue lineQ (Just "quit")
      reqs <- drainRequestQueue ctx
      reqs `shouldBe` [Heal, Quit]

    it "attacked 10 → quit を送ったとき requestQueue に [Attacked 10, Quit] が届くこと" $ do
      ctx   <- makeTestContext
      lineQ <- newTQueueIO
      withMockRun lineQ ctx $ do
        atomically $ do
          writeTQueue lineQ (Just "attacked 10")
          writeTQueue lineQ (Just "quit")
      reqs <- drainRequestQueue ctx
      reqs `shouldBe` [Attacked 10, Quit]

    it "不正入力はスキップされること（unknown → heal → quit）" $ do
      ctx   <- makeTestContext
      lineQ <- newTQueueIO
      withMockRun lineQ ctx $ do
        atomically $ do
          writeTQueue lineQ (Just "unknown")
          writeTQueue lineQ (Just "heal")
          writeTQueue lineQ (Just "quit")
      reqs <- drainRequestQueue ctx
      reqs `shouldBe` [Heal, Quit]

    it "magical-calamity → quit を送ったとき requestQueue に [MagicalCalamity, Quit] が届くこと" $ do
      ctx   <- makeTestContext
      lineQ <- newTQueueIO
      withMockRun lineQ ctx $ do
        atomically $ do
          writeTQueue lineQ (Just "magical-calamity")
          writeTQueue lineQ (Just "quit")
      reqs <- drainRequestQueue ctx
      reqs `shouldBe` [MagicalCalamity, Quit]

    it "EOF（Nothing）を送ったとき pipeline が正常終了すること" $ do
      ctx   <- makeTestContext
      lineQ <- newTQueueIO
      withMockRun lineQ ctx $ do
        atomically $ do
          writeTQueue lineQ (Just "heal")
          writeTQueue lineQ Nothing
      reqs <- drainRequestQueue ctx
      reqs `shouldBe` [Heal]
