{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE GADTs #-}

module CPA.Fractal.ApplicationBase.Control where

import Control.Monad                        (void)
import Control.Exception                    (finally)
import Control.Monad.Logger
import Control.Monad.Trans.State.Lazy       (get, evalStateT)
import Control.Monad.Trans.Class            (lift)
import Control.Monad.Trans.Reader           (runReaderT, ask)
import Control.Monad.Trans.Except           (runExceptT)
import Control.Monad.Except                 (catchError)
import Control.Monad.IO.Class               (liftIO)
import Data.Conduit
import qualified Control.Concurrent.STM as STM
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.Multiverse.CoreModel.Utility     (createLogger, runFastLoggerT)
import CPA.Fractal.CoreModel.Type
import CPA.Fractal.CoreModel.TH
import CPA.Fractal.CoreModel.Constant       (_LOG_FILE)
import CPA.Fractal.CoreModel.Utility    ()
import CPA.Fractal.ApplicationBase.State.Start      ()
import CPA.Fractal.ApplicationBase.State.Semantic   ()
import CPA.Fractal.ApplicationBase.State.Ontological ()
import CPA.Fractal.ApplicationBase.State.Stop       ()

$(funcTH_transit)

-- | モナドスタックのアンラップ専用関数
-- logDir が "" → stderr 出力、有効パス → ライブラリ別ファイルに追記
runWorldStateContext :: GlobalContext -> WorldStateContext a -> IO ()
runWorldStateContext ctx worldAction = do
  (logger, cleanup) <- createLogger ctx _LOG_FILE
  runFastLoggerT ctx logger inner `finally` cleanup
  where
    inner =
        flip runReaderT ctx
      $ flip evalStateT (WorldStateW StartState)
      $ void $ runExceptT worldAction

run :: GlobalContext -> IO ()
run ctx = runWorldStateContext ctx $ do
  void $ actionSW (WorldStateW StartState) (EventW EntryEvent)
  transit StartToSemantic
  runConduit pipeline
  void $ actionSW (WorldStateW StopState) (EventW ExitEvent)
  return ()

pipeline :: ConduitM () Void WorldStateContext ()
pipeline = src .| work .| sink

src :: ConduitT () Request WorldStateContext ()
src = do
  req <- lift go
  yield req
  case req of
    Quit -> do
      $logDebugS (T.pack "CPA.Fractal") (T.pack "src: Quit received. stopping pipeline after processing.")
      return ()
    _ -> src
  where
    go :: WorldStateContext Request
    go = do
      ctx <- lift $ lift ask
      liftIO $ STM.atomically $ STM.readTQueue (_requestQueueGlobalContext ctx)

work :: ConduitT Request EventW WorldStateContext ()
work = awaitForever $ \req -> do
  $logDebugS (T.pack "CPA.Fractal") $ T.pack $ "work: request: " ++ show req
  yield (toEventW req)

sink :: ConduitT EventW Void WorldStateContext ()
sink = await >>= \case
  Nothing -> do
    $logDebugS (T.pack "CPA.Fractal") $ T.pack "sink: pipeline finished normally."
    return ()
  Just ev -> flip catchError errHdl $ do
    lift (go ev)
    sink
  where
    errHdl :: String -> ConduitT EventW Void WorldStateContext ()
    errHdl msg = do
      $logWarnS (T.pack "CPA.Fractal") $ T.pack $ "sink: exception occurred. skip. " ++ msg
      sink

    go :: EventW -> WorldStateContext ()
    go ev = do
      st <- lift get
      result <- actionSW st ev
      case result of
        Nothing -> return ()
        Just t  -> transit t
