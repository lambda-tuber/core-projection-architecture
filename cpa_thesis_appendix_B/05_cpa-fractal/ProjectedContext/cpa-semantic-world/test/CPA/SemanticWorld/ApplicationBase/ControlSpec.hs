{-# LANGUAGE OverloadedStrings #-}

module CPA.SemanticWorld.ApplicationBase.ControlSpec (spec) where

import Test.Hspec
import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Concurrent        (threadDelay)
import Data.Maybe                (isNothing)
import Control.Monad.Logger

import CPA.Multiverse.CoreModel.Type
import CPA.SemanticWorld.ApplicationBase.Control (run)

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

makeTestAvatar :: Avatar
makeTestAvatar = Avatar
  { _nameAvatar  = "TestHero"
  , _levelAvatar = 1
  , _hpAvatar    = 100
  , _mpAvatar    = 50
  }

sendMsg :: GlobalContext -> Message -> IO ()
sendMsg ctx msg = atomically $ writeTQueue (_semanticQueueGlobalContext ctx) msg

recvRes :: GlobalContext -> IO Response
recvRes ctx = atomically $ readTQueue (_responseQueueGlobalContext ctx)

recvResTimeout :: GlobalContext -> IO (Maybe Response)
recvResTimeout ctx =
  atomically $ orElse
    (Just <$> readTQueue (_responseQueueGlobalContext ctx))
    (return Nothing)

-- | ontological TQueue から受信（MagicalCalamity テスト用）
recvOntMsg :: GlobalContext -> IO Message
recvOntMsg ctx = atomically $ readTQueue (_ontologicalQueueGlobalContext ctx)

recvOntMsgTimeout :: GlobalContext -> IO (Maybe Message)
recvOntMsgTimeout ctx =
  atomically $ orElse
    (Just <$> readTQueue (_ontologicalQueueGlobalContext ctx))
    (return Nothing)

--------------------------------------------------------------------------------
-- around ブラケット
--------------------------------------------------------------------------------

withWorld :: (GlobalContext -> IO ()) -> IO ()
withWorld testAction = do
  ctx <- makeTestContext
  withAsync (run ctx) $ \_ -> do
    threadDelay 50000
    testAction ctx

withWorldReady :: (GlobalContext -> IO ()) -> IO ()
withWorldReady testAction =
  withWorld $ \ctx -> do
    sendMsg ctx (MsgSetAvatar makeTestAvatar)
    threadDelay 20000
    testAction ctx

withWorldForBalse :: (GlobalContext -> IO ()) -> IO ()
withWorldForBalse testAction = do
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
  describe "CPA.SemanticWorld.ApplicationBase.Control.run" $ do

    -- -----------------------------------------------------------------------
    -- 正常系：Avatar 初期化後の Attacked / Heal
    -- -----------------------------------------------------------------------
    context "正常系" $ do

      around withWorldReady $ do

        context "MsgAttacked 30 を送ったとき" $ do
          it "Avatar の HP が 70 になること（初期HP100 - 30）" $ \ctx -> do
            sendMsg ctx (MsgAttacked 30)
            res <- recvRes ctx
            case res of
              ResAvatarStatus av -> _hpAvatar av `shouldBe` 70
              other              -> expectationFailure $ "unexpected response: " ++ show other

        context "MsgAttacked 30 → MsgAttacked 30 を送ったとき" $ do
          it "Avatar の HP が 40 になること（100 - 30 - 30）" $ \ctx -> do
            sendMsg ctx (MsgAttacked 30)
            _ <- recvRes ctx
            sendMsg ctx (MsgAttacked 30)
            res <- recvRes ctx
            case res of
              ResAvatarStatus av -> _hpAvatar av `shouldBe` 40
              other              -> expectationFailure $ "unexpected response: " ++ show other

        context "MsgAttacked 200 を送ったとき" $ do
          it "Avatar の HP が 0 になること（下限チェック）" $ \ctx -> do
            sendMsg ctx (MsgAttacked 200)
            res <- recvRes ctx
            case res of
              ResAvatarStatus av -> _hpAvatar av `shouldBe` 0
              other              -> expectationFailure $ "unexpected response: " ++ show other

        context "MsgHeal を送ったとき" $ do
          it "Avatar の MP が 10 減ること（初期MP50 - 10）" $ \ctx -> do
            sendMsg ctx MsgHeal
            res <- recvRes ctx
            case res of
              ResAvatarStatus av -> _mpAvatar av `shouldBe` 40
              other              -> expectationFailure $ "unexpected response: " ++ show other

        context "MsgAttacked 50 → MsgHeal を送ったとき" $ do
          it "HP が回復し（50 + level×5 = 55）、MP が 10 減ること" $ \ctx -> do
            sendMsg ctx (MsgAttacked 50)
            _ <- recvRes ctx
            sendMsg ctx MsgHeal
            res <- recvRes ctx
            case res of
              ResAvatarStatus av -> do
                _hpAvatar av `shouldBe` 55
                _mpAvatar av `shouldBe` 40
              other -> expectationFailure $ "unexpected response: " ++ show other

    -- -----------------------------------------------------------------------
    -- MsgSetAvatar：Avatar の注入確認
    -- -----------------------------------------------------------------------
    context "MsgSetAvatar" $ do

      around withWorld $ do

        context "MsgSetAvatar で HP=30 の Avatar を注入してから MsgAttacked 10 を送ったとき" $ do
          it "Avatar の HP が 20 になること" $ \ctx -> do
            let customAv = makeTestAvatar { _hpAvatar = 30 }
            sendMsg ctx (MsgSetAvatar customAv)
            threadDelay 20000
            sendMsg ctx (MsgAttacked 10)
            res <- recvRes ctx
            case res of
              ResAvatarStatus av -> _hpAvatar av `shouldBe` 20
              other              -> expectationFailure $ "unexpected response: " ++ show other

    -- -----------------------------------------------------------------------
    -- MsgMagicalCalamity：転移プロトコル（semantic → ontological）
    -- -----------------------------------------------------------------------
    context "MsgMagicalCalamity" $ do

      around withWorldReady $ do

        context "MsgMagicalCalamity を送ったとき" $ do
          it "ontological の TQueue に MsgSetAvatar が届くこと" $ \ctx -> do
            sendMsg ctx MsgMagicalCalamity
            threadDelay 20000
            msg <- recvOntMsg ctx
            case msg of
              MsgSetAvatar av -> _nameAvatar av `shouldBe` "TestHero"
              other           -> expectationFailure $ "expected MsgSetAvatar, got: " ++ show other

          it "転移後に MsgAttacked を送っても responseQueue に返らないこと（Avatar が消去済み）" $ \ctx -> do
            sendMsg ctx MsgMagicalCalamity
            threadDelay 20000
            -- ontological TQueue の MsgSetAvatar を読み捨て（テスト干渉回避）
            _ <- recvOntMsgTimeout ctx
            -- 転移後に Attacked を送る → vanishAvatar で Nothing → throwError → レスポンスなし
            sendMsg ctx (MsgAttacked 10)
            threadDelay 100000
            res <- recvResTimeout ctx
            res `shouldSatisfy` isNothing

          it "転移後に再度 MsgSetAvatar を注入すれば Attacked が通ること" $ \ctx -> do
            sendMsg ctx MsgMagicalCalamity
            threadDelay 20000
            _ <- recvOntMsgTimeout ctx
            -- 再注入
            sendMsg ctx (MsgSetAvatar makeTestAvatar { _hpAvatar = 80 })
            threadDelay 20000
            sendMsg ctx (MsgAttacked 20)
            res <- recvRes ctx
            case res of
              ResAvatarStatus av -> _hpAvatar av `shouldBe` 60
              other              -> expectationFailure $ "unexpected response: " ++ show other

    -- -----------------------------------------------------------------------
    -- MsgBalse：pipeline 正常終了の確認
    -- -----------------------------------------------------------------------
    context "MsgBalse" $ do

      around withWorldForBalse $ do

        context "MsgBalse を送ったとき" $ do
          it "run が正常終了すること（全状態 Entry/Exit サイクル完走）" $ \ctx -> do
            sendMsg ctx MsgBalse
            return ()

    -- -----------------------------------------------------------------------
    -- エラー系：Avatar 未設定のまま操作
    -- -----------------------------------------------------------------------
    context "エラー系" $ do

      around withWorld $ do

        context "MsgSetAvatar なしで MsgAttacked を送ったとき" $ do
          it "responseQueue に何も返らないこと（throwError で sink がスキップ継続）" $ \ctx -> do
            sendMsg ctx (MsgAttacked 30)
            threadDelay 100000
            res <- recvResTimeout ctx
            res `shouldSatisfy` isNothing
