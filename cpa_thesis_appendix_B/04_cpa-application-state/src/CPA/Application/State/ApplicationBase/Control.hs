{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GADTs #-}

module CPA.Application.State.ApplicationBase.Control where

import Control.Monad.Trans.State.Lazy
import Control.Monad.Reader
import Control.Monad.Except
import Control.Monad.Logger
import qualified Data.Text as T

import CPA.Application.State.CoreModel.Type
import CPA.Application.State.CoreModel.TH
import CPA.Application.State.CoreModel.Utility ()
import CPA.Application.State.ApplicationBase.State.Start ()
import CPA.Application.State.ApplicationBase.State.Run  ()
import CPA.Application.State.ApplicationBase.State.Stop ()

-- | Template Haskell で transit 関数を生成
--   transit :: StateTransition -> AppStateContext ()
funcTH_transit

-- | シンプルなイベントループ
--   conduit を使わず、イベントリストを順番に処理する。
--   HSpec から直接テスト可能な形にするための設計。
--
runAppBase :: [EventW] -> AppStateContext ()
runAppBase []     = do
  $logDebugS (T.pack "CPA") (T.pack "runAppBase: all events processed.")
  return ()
runAppBase (e:es) = do
  st <- get
  result <- actionSW st e
  case result of
    Nothing -> do
      $logDebugS (T.pack "CPA") (T.pack "runAppBase: no transition.")
      runAppBase es
    Just t  -> do
      $logDebugS (T.pack "CPA") (T.pack $ "runAppBase: transition -> " ++ show t)
      transit t
      runAppBase es

-- | AppState の初期状態（StartState）でイベントループを起動する
--   Boot 層に相当するエントリポイント
run :: [EventW] -> IO (Either String ((), AppStateW))
run events =
  runAppState (AppStateW StartState) (runAppBase events)

-- | AppStateContext を IO まで実行するランナー
runAppState :: AppStateW
            -> AppStateContext a
            -> IO (Either String (a, AppStateW))
runAppState initSt ctx =
  runStderrLoggingT
    $ runExceptT
    $ flip runReaderT GlobalConfig
    $ runStateT ctx initSt
