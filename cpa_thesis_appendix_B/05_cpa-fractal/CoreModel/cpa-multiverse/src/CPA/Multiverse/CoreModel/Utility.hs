{-# LANGUAGE OverloadedStrings #-}

module CPA.Multiverse.CoreModel.Utility where

import System.Log.FastLogger
import Control.Monad.Logger
import System.FilePath        ((</>))

import CPA.Multiverse.CoreModel.Type     (GlobalContext(..))
import CPA.Multiverse.CoreModel.Constant (_TIME_FORMAT)

-- | FastLogger を生成する。
-- _logDirGlobalContext が "" → stderr 出力（LogStderr）
-- _logDirGlobalContext が非空 → LogFileNoRotate で dir </> logFile に追記
-- 注意：_logDirGlobalContext は cpa-bootstrap が makeAbsolute + doesDirectoryExist
--       で検証済みの値のみが格納される（不変条件）。ここでの再チェックは不要。
createLogger :: GlobalContext -> FilePath -> IO (TimedFastLogger, IO ())
createLogger ctx logFile = newTimeCache _TIME_FORMAT >>= withDir (_logDirGlobalContext ctx)
  where
    withDir ""  tcache = newTimedFastLogger tcache $ LogStderr defaultBufSize
    withDir dir tcache = newTimedFastLogger tcache $ LogFileNoRotate (dir </> logFile) defaultBufSize

-- | FastLogger を使って LoggingT アクションを実行する。
-- logLevel は GlobalContext から取得してフィルタリングする。
runFastLoggerT :: GlobalContext -> TimedFastLogger -> LoggingT IO a -> IO a
runFastLoggerT ctx logger app =
  runLoggingT (filterLogger (filterByLevel (_logLevelGlobalContext ctx)) app) (output logger)
  where
    output :: TimedFastLogger -> Loc -> LogSource -> LogLevel -> LogStr -> IO ()
    output l loc src level msg =
      let str = defaultLogStr loc src level msg
      in  l (\ts -> toLogStr ts <> toLogStr (" " :: String) <> str)

    filterByLevel :: LogLevel -> LogSource -> LogLevel -> Bool
    filterByLevel target _ actual = actual >= target
