{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE GADTs #-}

module CPA.Request.ApplicationBase.Control where

import Control.Monad                        (void)
import Control.Exception                    (finally)
import Control.Monad.Logger
import Control.Monad.Trans.State.Lazy       (get, evalStateT)
import Control.Monad.Trans.Class            (lift)
import Control.Monad.Trans.Reader           (runReaderT)
import Control.Monad.Trans.Except           (runExceptT)
import Control.Monad.Except                 (catchError)
import Control.Monad.IO.Class               (liftIO)
import Data.Conduit
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.Multiverse.CoreModel.Utility     (createLogger, runFastLoggerT)
import CPA.Request.CoreModel.Type
import CPA.Request.CoreModel.TH
import CPA.Request.CoreModel.Constant       (_LOG_FILE)
import CPA.Request.CoreModel.Utility    ()
import CPA.Request.ApplicationBase.State.Start ()
import CPA.Request.ApplicationBase.State.Run   ()
import CPA.Request.ApplicationBase.State.Stop  ()

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

run :: IO (Maybe T.Text) -> GlobalContext -> IO ()
run readLine ctx = runWorldStateContext ctx $ do
  void $ actionSW (WorldStateW StartState) (EventW EntryEvent)
  transit StartToRun
  runConduit (src readLine .| work .| sink)
  transit RunToStop
  void $ actionSW (WorldStateW StopState) (EventW ExitEvent)

src :: IO (Maybe T.Text) -> ConduitT () T.Text WorldStateContext ()
src readLine = do
  mLine <- liftIO readLine
  case mLine of
    Nothing   -> return ()
    Just line -> do
      yield line
      src readLine

work :: ConduitT T.Text EventW WorldStateContext ()
work = awaitForever $ \line ->
  yield (EventW (InputEvent (InputEventData line)))

sink :: ConduitT EventW Void WorldStateContext ()
sink = await >>= \case
  Nothing -> do
    $logDebugS "CPA.Request" "sink: pipeline finished normally."
    return ()
  Just ev -> flip catchError errHdl $ do
    stopped <- lift (go ev)
    if stopped
      then do
        $logDebugS "CPA.Request" "sink: RunToStop detected. closing pipeline."
        return ()
      else sink
  where
    errHdl :: String -> ConduitT EventW Void WorldStateContext ()
    errHdl msg = do
      $logWarnS "CPA.Request" $ T.pack $ "sink: exception occurred. skip. " ++ msg
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
