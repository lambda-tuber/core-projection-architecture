{-# LANGUAGE OverloadedStrings #-}

module CPA.Fractal.ApplicationBase.ControlSpec (spec) where

import Test.Hspec
import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Concurrent        (threadDelay)
import Data.Maybe                (isNothing)
import Control.Monad.Logger

import CPA.Multiverse.CoreModel.Type
import CPA.Fractal.ApplicationBase.Control (run)

--------------------------------------------------------------------------------
-- テスト用ヘルパー
--------------------------------------------------------------------------------

makeTestContext :: IO GlobalContext
makeTestContext = do
  reqQ  <- newTQueueIO
  semQ  <- newTQueueIO
  ontQ  <- newTQueueIO
  resQ  <- newTQueueIO
  return GlobalContext
    { _requestQueueGlobalContext     = reqQ
    , _semanticQueueGlobalContext    = semQ
    , _ontologicalQueueGlobalContext = ontQ
    , _responseQueueGlobalContext    = resQ
    , _logLevelGlobalContext         = LevelDebug
    , _logDirGlobalContext           = ""
    }

-- | semantic-world TQueue からメッセージを取り出す
recvSemantic :: GlobalContext -> IO Message
recvSemantic ctx = atomically $ readTQueue (_semanticQueueGlobalContext ctx)

-- | ontological-world TQueue からメッセージを取り出す
recvOntological :: GlobalContext -> IO Message
recvOntological ctx = atomically $ readTQueue (_ontologicalQueueGlobalContext ctx)

-- | タイムアウト付き：ontological TQueue にメッセージがなければ Nothing
recvOntologicalTimeout :: GlobalContext -> IO (Maybe Message)
recvOntologicalTimeout ctx = atomically $ orElse
  (Just <$> readTQueue (_ontologicalQueueGlobalContext ctx))
  (return Nothing)

sendRequest :: GlobalContext -> Request -> IO ()
sendRequest ctx req = atomically $ writeTQueue (_requestQueueGlobalContext ctx) req

--------------------------------------------------------------------------------
-- around ブラケット
--------------------------------------------------------------------------------

-- | run をサブスレッドで起動し、Start の初期化（MsgSetAvatar enqueue）を待つ
withWorld :: (GlobalContext -> IO ()) -> IO ()
withWorld testAction = do
  ctx <- makeTestContext
  withAsync (run ctx) $ \_ -> do
    threadDelay 50000
    testAction ctx

-- | Quit テスト用：run が自然終了するまで wait する
withWorldForQuit :: (GlobalContext -> IO ()) -> IO ()
withWorldForQuit testAction = do
  ctx <- makeTestContext
  a <- async (run ctx)
  threadDelay 50000
  testAction ctx
  wait a

--------------------------------------------------------------------------------
-- Spec
--------------------------------------------------------------------------------

spec :: Spec
spec = do
  describe "CPA.Fractal.ApplicationBase.Control.run" $ do

    -- -----------------------------------------------------------------------
    -- 初期化：Start Exit で semantic-world に MsgSetAvatar が届くこと
    -- -----------------------------------------------------------------------
    context "初期化" $ do

      around withWorld $ do

        context "起動直後" $ do
          it "semantic-world の TQueue に MsgSetAvatar が enqueue されること" $ \ctx -> do
            msg <- recvSemantic ctx
            case msg of
              MsgSetAvatar av -> _nameAvatar av `shouldBe` "Hero"
              other           -> expectationFailure $ "unexpected message: " ++ show other

    -- -----------------------------------------------------------------------
    -- Semantic 状態：Attacked / Heal が semantic TQueue に流れること
    -- -----------------------------------------------------------------------
    context "Semantic 状態" $ do

      around withWorld $ do

        context "初期化メッセージを受け取ってから" $ do

          it "Attacked Request が semantic TQueue に MsgAttacked として届くこと" $ \ctx -> do
            _ <- recvSemantic ctx   -- 初期 MsgSetAvatar を消費
            sendRequest ctx (Attacked 30)
            msg <- recvSemantic ctx
            msg `shouldBe` MsgAttacked 30

          it "Heal Request が semantic TQueue に MsgHeal として届くこと" $ \ctx -> do
            _ <- recvSemantic ctx
            sendRequest ctx Heal
            msg <- recvSemantic ctx
            msg `shouldBe` MsgHeal

    -- -----------------------------------------------------------------------
    -- MagicalCalamity：Semantic → Ontological 状態遷移
    -- -----------------------------------------------------------------------
    context "MagicalCalamity（転生）" $ do

      around withWorld $ do

        context "Semantic 状態で MagicalCalamity を送ったとき" $ do

          it "semantic TQueue に MsgMagicalCalamity が届くこと" $ \ctx -> do
            _ <- recvSemantic ctx
            sendRequest ctx MagicalCalamity
            msg <- recvSemantic ctx
            msg `shouldBe` MsgMagicalCalamity

          it "MagicalCalamity 後の Attacked は ontological TQueue に届くこと" $ \ctx -> do
            _ <- recvSemantic ctx
            sendRequest ctx MagicalCalamity
            _ <- recvSemantic ctx
            threadDelay 20000
            sendRequest ctx (Attacked 10)
            msg <- recvOntological ctx
            msg `shouldBe` MsgAttacked 10

    -- -----------------------------------------------------------------------
    -- MagicalCalamity：Ontological → Semantic 状態遷移（帰還）
    -- -----------------------------------------------------------------------
    context "MagicalCalamity（帰還）" $ do

      around withWorld $ do

        context "Ontological 状態で MagicalCalamity を送ったとき" $ do

          it "ontological TQueue に MsgMagicalCalamity が届くこと" $ \ctx -> do
            _ <- recvSemantic ctx
            sendRequest ctx MagicalCalamity
            _ <- recvSemantic ctx
            threadDelay 20000
            sendRequest ctx MagicalCalamity   -- 帰還：Ontological → Semantic
            msg <- recvOntological ctx
            msg `shouldBe` MsgMagicalCalamity

          it "帰還後の Attacked は semantic TQueue に届くこと" $ \ctx -> do
            _ <- recvSemantic ctx
            sendRequest ctx MagicalCalamity
            _ <- recvSemantic ctx
            threadDelay 20000
            sendRequest ctx MagicalCalamity
            _ <- recvOntological ctx
            threadDelay 20000
            sendRequest ctx (Attacked 5)
            msg <- recvSemantic ctx
            msg `shouldBe` MsgAttacked 5

    -- -----------------------------------------------------------------------
    -- Quit：pipeline 正常終了
    -- -----------------------------------------------------------------------
    context "Quit" $ do

      around withWorldForQuit $ do

        context "Semantic 状態で Quit を送ったとき" $ do
          it "semantic TQueue に MsgBalse が届き、run が正常終了すること" $ \ctx -> do
            _ <- recvSemantic ctx
            sendRequest ctx Quit
            msg <- recvSemantic ctx
            msg `shouldBe` MsgBalse

    -- -----------------------------------------------------------------------
    -- ontological TQueue に余分なメッセージが届かないこと
    -- -----------------------------------------------------------------------
    context "Semantic 状態での ontological TQueue 非汚染" $ do

      around withWorld $ do

        it "Attacked を Semantic 状態で送っても ontological TQueue は空のまま" $ \ctx -> do
          _ <- recvSemantic ctx
          sendRequest ctx (Attacked 30)
          _ <- recvSemantic ctx
          threadDelay 50000
          msg <- recvOntologicalTimeout ctx
          msg `shouldSatisfy` isNothing
