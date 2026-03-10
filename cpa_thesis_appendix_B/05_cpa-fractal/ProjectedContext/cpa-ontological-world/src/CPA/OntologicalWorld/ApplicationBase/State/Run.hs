{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.OntologicalWorld.ApplicationBase.State.Run where

import Control.Monad.IO.Class                    (liftIO)
import Control.Monad.Trans.Class                 (lift)
import Control.Monad.Trans.State.Lazy            (get, put, runStateT, execStateT)
import Control.Monad.Trans.Reader                (ask)
import Control.Monad.Logger
import qualified Control.Concurrent.STM as STM
import qualified Data.Text as T

import qualified CPA.Multiverse.CoreModel.Type as MV
import CPA.OntologicalWorld.CoreModel.Type
import CPA.OntologicalWorld.CoreModel.TH
import CPA.OntologicalWorld.ProjectedContext.Context

instanceTH_IWorldState ''RunStateData

instance IStateActivity RunStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Run: entry. AnotherWorld created (no avatar yet).")
    return noStateTransition

instance IStateActivity RunStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Run: exit.")
    return noStateTransition

instance IStateActivity RunStateData TransitEventData

-- | AttackedEvent
instance IStateActivity RunStateData AttackedEventData where
  action _ (AttackedEvent (AttackedEventData n)) = do
    $logDebugS (T.pack "CPA.OntologicalWorld") $ T.pack $ "Run: attacked " ++ show n
    av' <- runProjectedContext (attacked n)
    sendResponse av'
    return noStateTransition

-- | HealEvent
instance IStateActivity RunStateData HealEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Run: heal.")
    av' <- runProjectedContext heal
    sendResponse av'
    return noStateTransition

-- | SetAvatarEvent：転生プロトコル着地
instance IStateActivity RunStateData SetAvatarEventData where
  action _ (SetAvatarEvent (SetAvatarEventData mvAv)) = do
    $logDebugS (T.pack "CPA.OntologicalWorld") $ T.pack $ "Run: setAvatar (reincarnation protocol) " ++ show mvAv
    let avO = toOntologicalAvatar mvAv
    runProjectedContext (putAvatar avO)
    return noStateTransition

-- | MagicalCalamityEvent：転移プロトコル（ontological → semantic）
-- 1. runProjectedContext takeAvatar で AnotherWorld から Avatar を取り出す
-- 2. runProjectedContext vanishAvatar で自ワールドの Avatar を消去する
-- 3. toMultiverseAvatar で変換し、相手ワールド（semantic）の TQueue に MsgSetAvatar を enqueue する
-- 4. ResWorldLog で転移完了をユーザーに通知する（プロンプト再表示のため）
-- ワールド自身は止まらず Run を継続する。
instance IStateActivity RunStateData MagicalCalamityEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Run: MagicalCalamity. transferring avatar to semantic world.")
    avO <- runProjectedContext takeAvatar
    runProjectedContext vanishAvatar
    let av = toMultiverseAvatar avO
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $
      STM.writeTQueue (MV._semanticQueueGlobalContext ctx) (MV.MsgSetAvatar av)
    liftIO $ STM.atomically $
      STM.writeTQueue (MV._responseQueueGlobalContext ctx) (MV.ResWorldLog "avatar が semantic-world に帰還しました。")
    return noStateTransition

--------------------------------------------------------------------------------
-- runProjectedContext
--------------------------------------------------------------------------------

runProjectedContext :: AnotherWorld a -> WorldStateContext a
runProjectedContext worldAction = do
  curW <- takeWorld
  (result, newW) <- liftIO $ execWorld worldAction curW
  putWorld newW
  return result

execWorld :: AnotherWorld a -> AnotherWorld () -> IO (a, AnotherWorld ())
execWorld worldAction curW = do
  currentState <- execStateT (runAnotherWorld curW) Nothing
  (result, finalState) <- runStateT (runAnotherWorld worldAction) currentState
  return (result, wrapState finalState)

wrapState :: Maybe (Avatar AnotherWorld) -> AnotherWorld ()
wrapState mav = AnotherWorld $ put mav

--------------------------------------------------------------------------------
-- ヘルパー関数
--------------------------------------------------------------------------------

takeWorld :: WorldStateContext (AnotherWorld ())
takeWorld = do
  st <- lift get
  case st of
    WorldStateW (RunState dat) -> return (_worldRunStateData dat)
    _ -> liftIO $ fail "takeWorld called in non-Run state."

putWorld :: AnotherWorld () -> WorldStateContext ()
putWorld w = do
  st <- lift get
  case st of
    WorldStateW (RunState _) ->
      lift $ put $ WorldStateW $ RunState $ RunStateData w
    _ -> return ()

sendResponse :: Avatar AnotherWorld -> WorldStateContext ()
sendResponse avO = do
  ctx <- lift $ lift ask
  liftIO $ STM.atomically $ STM.writeTQueue (MV._responseQueueGlobalContext ctx) (MV.ResAvatarStatus (toMultiverseAvatar avO))
