{-# LANGUAGE OverloadedStrings #-}

module CPA.Response.Boot.BootstrapSpec (spec) where

import Test.Hspec
import Control.Concurrent.Async        (async, wait)
import Control.Concurrent.STM
import Control.Concurrent              (threadDelay)
import Control.Monad.Logger

import CPA.Multiverse.CoreModel.Type
import CPA.Response.ApplicationBase.Control  (run)
import CPA.Response.ApplicationBase.State.Run (formatResponse)
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

-- | テスト用モック writeFn：TQueue T.Text に書き込む
mockWriteFn :: TQueue T.Text -> T.Text -> IO ()
mockWriteFn q t = atomically $ writeTQueue q t

-- | 出力キャプチャキューから全件取り出す
drainOutputQueue :: TQueue T.Text -> IO [T.Text]
drainOutputQueue q = atomically $ flushTQueue q

-- | run をモック writeFn で非同期起動し、テストアクションを実行して wait する
withMockRun :: TQueue T.Text -> GlobalContext -> IO () -> IO ()
withMockRun outQ ctx testAction = do
  a <- async (run (mockWriteFn outQ) ctx)
  threadDelay 30000
  testAction
  wait a

-- | responseQueue に Response を enqueue するヘルパー
enqueue :: GlobalContext -> Response -> IO ()
enqueue ctx resp = atomically $ writeTQueue (_responseQueueGlobalContext ctx) resp

--------------------------------------------------------------------------------
-- Spec
--------------------------------------------------------------------------------

spec :: Spec
spec = do

  -- -------------------------------------------------------------------------
  -- formatResponse 単体テスト
  -- -------------------------------------------------------------------------
  describe "formatResponse" $ do

    it "ResWorldLog → そのままテキスト" $
      formatResponse (ResWorldLog "hello world") `shouldBe` "hello world"

    it "ResAvatarStatus → Avatar: ... 形式" $ do
      let av = Avatar { _nameAvatar = "Asuka", _levelAvatar = 5
                      , _hpAvatar = 80, _mpAvatar = 60 }
      formatResponse (ResAvatarStatus av) `shouldBe`
        T.pack ("Avatar: " ++ show av)

    it "ResQuit → 終了メッセージ" $
      formatResponse ResQuit `shouldBe` "cpa-response: quit."

  -- -------------------------------------------------------------------------
  -- pipeline 統合テスト
  -- 注: Interface/Stdio.hs の writeStdout は putStr（改行なし）に変更済み。
  --     Run.hs は通常テキストに "\n" を付与し、">>> " はそのまま渡す。
  --     よってモック writeFn が受け取る文字列は:
  --       - 通常テキスト: "テキスト\n"
  --       - プロンプト:   ">>> "
  -- -------------------------------------------------------------------------
  describe "pipeline 統合テスト" $ do

    it "ResWorldLog → ResQuit のとき [テキスト\\n, >>> ] が出力されること" $ do
      ctx  <- makeTestContext
      outQ <- newTQueueIO
      withMockRun outQ ctx $ do
        enqueue ctx (ResWorldLog "hello")
        enqueue ctx ResQuit
      out <- drainOutputQueue outQ
      out `shouldBe` ["hello\n", ">>> "]

    it "ResAvatarStatus → ResQuit のとき [Avatar テキスト\\n, >>> ] が出力されること" $ do
      ctx  <- makeTestContext
      outQ <- newTQueueIO
      let av = Avatar { _nameAvatar = "Asuka", _levelAvatar = 5
                      , _hpAvatar = 80, _mpAvatar = 60 }
      withMockRun outQ ctx $ do
        enqueue ctx (ResAvatarStatus av)
        enqueue ctx ResQuit
      out <- drainOutputQueue outQ
      out `shouldBe` [T.pack ("Avatar: " ++ show av) <> "\n", ">>> "]

    it "複数 ResWorldLog → ResQuit のとき全件 + 各 >>> が正しい順序で出力されること" $ do
      ctx  <- makeTestContext
      outQ <- newTQueueIO
      withMockRun outQ ctx $ do
        enqueue ctx (ResWorldLog "msg1")
        enqueue ctx (ResWorldLog "msg2")
        enqueue ctx (ResWorldLog "msg3")
        enqueue ctx ResQuit
      out <- drainOutputQueue outQ
      out `shouldBe` ["msg1\n", ">>> ", "msg2\n", ">>> ", "msg3\n", ">>> "]

    it "ResQuit のみのとき即 pipeline 終了して出力なし" $ do
      ctx  <- makeTestContext
      outQ <- newTQueueIO
      withMockRun outQ ctx $ do
        enqueue ctx ResQuit
      out <- drainOutputQueue outQ
      out `shouldBe` []

    it "ResWorldLog のみ → ResQuit のとき pipeline が正常終了すること" $ do
      ctx  <- makeTestContext
      outQ <- newTQueueIO
      withMockRun outQ ctx $ do
        enqueue ctx (ResWorldLog "only one")
        enqueue ctx ResQuit
      out <- drainOutputQueue outQ
      out `shouldBe` ["only one\n", ">>> "]
