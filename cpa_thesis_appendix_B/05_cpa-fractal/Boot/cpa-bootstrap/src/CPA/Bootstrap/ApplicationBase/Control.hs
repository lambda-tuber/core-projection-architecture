{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module CPA.Bootstrap.ApplicationBase.Control where

import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Monad.Logger       (LogLevel (..))
import Data.Default
import Data.Yaml
import Control.Lens
import System.IO
import System.Directory           (doesDirectoryExist, makeAbsolute)

import CPA.Multiverse.CoreModel.Type
import CPA.Bootstrap.CoreModel.Type

--------------------------------------------------------------------------------
-- エントリポイント
--------------------------------------------------------------------------------

-- | cpa-bootstrap のエントリポイント
-- apps は Main から注入される (GlobalContext -> IO ()) のリスト。
-- Control はこのリストの中身を知らない。依存するのは cpa-multiverse のみ。
--
--   1. YAML 設定読み込み（省略時は def）
--   2. logDir を makeAbsolute → doesDirectoryExist で存在確認
--   3. GlobalContext 生成（4 TQueue + logDir + logLevel）
--   4. apps を並列起動（withAsync）
--   5. waitAnyCatchCancel → 全スレッドキャンセル → 終了
run :: ArgData -> [GlobalContext -> IO ()] -> IO ()
run args apps = do
  hPutStrLn stderr "[INFO] cpa-bootstrap: starting."

  conf <- loadConf args
  hPutStrLn stderr $ "[INFO] cpa-bootstrap: config loaded. " ++ show conf

  resolvedLogDir <- resolveLogDir (_logDirConfigData conf)
  hPutStrLn stderr $ "[INFO] cpa-bootstrap: logDir resolved. " ++ show resolvedLogDir

  ctx <- makeGlobalContext (_logLevelConfigData conf) resolvedLogDir
  hPutStrLn stderr "[INFO] cpa-bootstrap: GlobalContext created."

  runAll ctx apps

--------------------------------------------------------------------------------
-- GlobalContext 生成
--------------------------------------------------------------------------------

makeGlobalContext :: LogLevel -> FilePath -> IO GlobalContext
makeGlobalContext logLevel logDir = do
  reqQ  <- newTQueueIO
  semQ  <- newTQueueIO
  ontQ  <- newTQueueIO
  resQ  <- newTQueueIO
  return GlobalContext
    { _requestQueueGlobalContext     = reqQ
    , _semanticQueueGlobalContext    = semQ
    , _ontologicalQueueGlobalContext = ontQ
    , _responseQueueGlobalContext    = resQ
    , _logDirGlobalContext           = logDir
    , _logLevelGlobalContext         = logLevel
    }

--------------------------------------------------------------------------------
-- スレッド起動
--------------------------------------------------------------------------------

-- | apps リストを並列起動し、いずれか1つが終了したら残りを全キャンセルする
-- 空リストの場合は waitAnyCatchCancel が例外を投げるため、即 return () する。
runAll :: GlobalContext -> [GlobalContext -> IO ()] -> IO ()
runAll _   []   = do
  hPutStrLn stderr "[WARN] cpa-bootstrap: no apps to run."
  return ()
runAll ctx apps = do
  asyncs <- mapM (\f -> async (f ctx)) apps
  hPutStrLn stderr "[INFO] cpa-bootstrap: all threads started."
  (_, result) <- waitAnyCatchCancel asyncs
  case result of
    Right _ -> hPutStrLn stderr "[INFO] cpa-bootstrap: a thread finished normally. exiting."
    Left  e -> hPutStrLn stderr $ "[WARN] cpa-bootstrap: a thread finished with exception: " ++ show e

--------------------------------------------------------------------------------
-- YAML 読み込み
--------------------------------------------------------------------------------

loadConf :: ArgData -> IO ConfigData
loadConf args = case args ^. yamlArgData of
  Nothing   -> return def
  Just path -> decodeFileThrow path

--------------------------------------------------------------------------------
-- logDir 解決
--------------------------------------------------------------------------------

-- | 空文字列 → "" のまま返す（stderr）
-- 非空文字列 → makeAbsolute → doesDirectoryExist
--   存在する  → 絶対パスを返す
--   存在しない → "" にフォールバック（stderr）
resolveLogDir :: FilePath -> IO FilePath
resolveLogDir "" = return ""
resolveLogDir dir = do
  absDir <- makeAbsolute dir
  exists <- doesDirectoryExist absDir
  if exists
    then return absDir
    else do
      hPutStrLn stderr $ "[WARN] cpa-bootstrap: logDir not found, fallback to stderr. dir=" ++ absDir
      return ""
