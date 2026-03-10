{-# LANGUAGE OverloadedStrings #-}

module CPA.Bootstrap.ApplicationBase.ControlSpec (spec) where

import Test.Hspec
import Control.Concurrent.STM
import Control.Concurrent        (threadDelay)
import Control.Monad.Logger      (LogLevel (..))

import CPA.Multiverse.CoreModel.Type
import CPA.Bootstrap.ApplicationBase.Control (run, makeGlobalContext)
import CPA.Bootstrap.CoreModel.Type

--------------------------------------------------------------------------------
-- テスト用モックアプリ
--
-- 実際のライブラリの run は渡さない。
-- モック関数を [GlobalContext -> IO ()] として渡すことで
-- Control がリストの中身に依存しないことを確認する。
--------------------------------------------------------------------------------

-- | 起動したことを TQueue に記録してすぐ終了するモック
mockApp :: TQueue String -> String -> GlobalContext -> IO ()
mockApp log' name _ = atomically $ writeTQueue log' name

-- | GlobalContext の logLevel を TQueue に記録するモック
mockAppLogLevel :: TQueue LogLevel -> GlobalContext -> IO ()
mockAppLogLevel out ctx = atomically $ writeTQueue out (_logLevelGlobalContext ctx)

-- | すぐ例外を投げるモック（waitAnyCatchCancel の例外ハンドリング確認用）
mockAppFail :: GlobalContext -> IO ()
mockAppFail _ = ioError $ userError "mock failure"

--------------------------------------------------------------------------------
-- テストヘルパー
--------------------------------------------------------------------------------

defArgs :: ArgData
defArgs = ArgData { _yamlArgData = Nothing }

--------------------------------------------------------------------------------
-- Spec
--------------------------------------------------------------------------------

spec :: Spec
spec = do
  describe "CPA.Bootstrap.ApplicationBase.Control.run" $ do

    -- -----------------------------------------------------------------------
    -- makeGlobalContext：TQueue / ログ設定が正しく初期化されること
    -- -----------------------------------------------------------------------
    describe "makeGlobalContext" $ do

      it "logDir / logLevel が正しく設定されること" $ do
        ctx <- makeGlobalContext LevelInfo "/tmp/logs"
        _logDirGlobalContext   ctx `shouldBe` "/tmp/logs"
        _logLevelGlobalContext ctx `shouldBe` LevelInfo

      it "logDir が空文字列でも生成できること" $ do
        ctx <- makeGlobalContext LevelDebug ""
        _logDirGlobalContext ctx `shouldBe` ""

    -- -----------------------------------------------------------------------
    -- run：アプリリストが全て起動されること
    -- -----------------------------------------------------------------------
    describe "run（モックアプリ）" $ do

      it "apps リストの全アプリが GlobalContext を受け取って起動されること" $ do
        log' <- newTQueueIO
        let apps = [ mockApp log' "app1"
                   , mockApp log' "app2"
                   , mockApp log' "app3"
                   ]
        run defArgs apps
        threadDelay 50000
        names <- atomically $ flushTQueue log'
        names `shouldMatchList` ["app1", "app2", "app3"]

      it "apps リストが空のとき run が正常終了すること（runAll の空リストガード）" $ do
        -- waitAnyCatchCancel は空リスト不可のため runAll で早期 return する
        run defArgs [] `shouldReturn` ()

    -- -----------------------------------------------------------------------
    -- run：GlobalContext のログ設定が各アプリに届くこと
    -- -----------------------------------------------------------------------
    describe "run（GlobalContext 伝播）" $ do

      it "デフォルト設定の logLevel LevelDebug が apps に届くこと" $ do
        out <- newTQueueIO
        run defArgs [mockAppLogLevel out]
        threadDelay 50000
        levels <- atomically $ flushTQueue out
        levels `shouldBe` [LevelDebug]

    -- -----------------------------------------------------------------------
    -- run：いずれかのアプリが例外を投げても run が正常終了すること
    -- -----------------------------------------------------------------------
    describe "run（例外ハンドリング）" $ do

      it "アプリが例外を投げても run がパニックしないこと" $ do
        run defArgs [mockAppFail] `shouldReturn` ()
