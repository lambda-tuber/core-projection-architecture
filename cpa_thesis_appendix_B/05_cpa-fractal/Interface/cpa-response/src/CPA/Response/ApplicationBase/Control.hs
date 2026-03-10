{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE GADTs #-}

module CPA.Response.ApplicationBase.Control where

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
import CPA.Response.CoreModel.Type
import CPA.Response.CoreModel.TH
import CPA.Response.CoreModel.Constant      (_LOG_FILE)
import CPA.Response.CoreModel.Utility    ()
import CPA.Response.ApplicationBase.State.Start ()
import CPA.Response.ApplicationBase.State.Run   ()
import CPA.Response.ApplicationBase.State.Stop  ()

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

run :: (T.Text -> IO ()) -> GlobalContext -> IO ()
run writeFn ctx = runWorldStateContext ctx $ do
  void $ actionSW (WorldStateW StartState) (EventW EntryEvent)
  transit StartToRun
  runConduit (src .| work writeFn .| sink)
  transit RunToStop
  void $ actionSW (WorldStateW StopState) (EventW ExitEvent)

src :: ConduitT () Response WorldStateContext ()
src = do
  ctx <- lift $ lift $ lift ask
  resp <- liftIO $ STM.atomically $ STM.readTQueue (_responseQueueGlobalContext ctx)
  case resp of
    ResQuit -> do
      $logDebugS "CPA.Response" "src: ResQuit received. closing pipeline."
      return ()
    _ -> do
      yield resp
      src

work :: (T.Text -> IO ()) -> ConduitT Response EventW WorldStateContext ()
work writeFn = awaitForever $ \resp ->
  yield (EventW (OutputEvent (OutputEventData writeFn resp)))

sink :: ConduitT EventW Void WorldStateContext ()
sink = await >>= \case
  Nothing -> do
    $logDebugS "CPA.Response" "sink: pipeline finished normally."
    return ()
  Just ev -> flip catchError errHdl $ do
    stopped <- lift (go ev)
    if stopped
      then do
        $logDebugS "CPA.Response" "sink: RunToStop detected. closing pipeline."
        return ()
      else sink
  where
    errHdl :: String -> ConduitT EventW Void WorldStateContext ()
    errHdl msg = do
      $logWarnS "CPA.Response" $ T.pack $ "sink: exception occurred. skip. " ++ msg
      sink

    go :: EventW -> WorldStateContext Bool
    go ev = do
      st     <- lift get
      result <- actionSW st ev
      case result of
        Nothing         -> return False
        Just RunToStop  -> return True
        Just t          -> do
          transit t
          return False
