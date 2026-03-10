{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Fractal.ApplicationBase.State.Ontological where

import Control.Monad.IO.Class         (liftIO)
import Control.Monad.Trans.Class      (lift)
import Control.Monad.Trans.Reader     (ask)
import Control.Monad.Logger
import qualified Control.Concurrent.STM as STM
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.Fractal.CoreModel.Type
import CPA.Fractal.CoreModel.TH

-- | Template Haskell で IWorldState OntologicalStateData インスタンスを自動生成
instanceTH_IWorldState ''OntologicalStateData

-- | Entry：Ontological 状態に入ったときのログ
instance IStateActivity OntologicalStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Ontological: entry. ontological-world is now active.")
    return noStateTransition

-- | Exit：Ontological 状態を出るときのログ
instance IStateActivity OntologicalStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Ontological: exit.")
    return noStateTransition

-- | Transit：デフォルト実装（OntologicalToSemantic / OntologicalToStop を受け付ける）
instance IStateActivity OntologicalStateData TransitEventData

-- | AttackedEvent：ontological-world の TQueue に MsgAttacked を enqueue
instance IStateActivity OntologicalStateData AttackedEventData where
  action _ (AttackedEvent (AttackedEventData n)) = do
    $logDebugS (T.pack "CPA.Fractal") $ T.pack $ "Ontological: attacked " ++ show n ++ " -> enqueue to ontological-world."
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_ontologicalQueueGlobalContext ctx) (MsgAttacked n)
    return noStateTransition

-- | HealEvent：ontological-world の TQueue に MsgHeal を enqueue
instance IStateActivity OntologicalStateData HealEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Ontological: heal -> enqueue to ontological-world.")
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_ontologicalQueueGlobalContext ctx) MsgHeal
    return noStateTransition

-- | SetAvatarEvent：Ontological 状態では直接処理しない（各ワールドが内部保持）
instance IStateActivity OntologicalStateData SetAvatarEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Ontological: SetAvatarEvent not handled at fractal-app level.")
    return noStateTransition

-- | CalamityEvent：魔力災害発生（帰還方向）
-- ontological-world に MsgMagicalCalamity を enqueue し、OntologicalToSemantic を返す。
-- ontological-world 側の責務：
--   1. Avatar を取得
--   2. _semanticQueueGlobalContext に MsgSetAvatar av を enqueue
--   3. Run 継続（自分は止まらない）
instance IStateActivity OntologicalStateData CalamityEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Ontological: MagicalCalamity! -> enqueue MsgMagicalCalamity to ontological-world. transit to Semantic.")
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_ontologicalQueueGlobalContext ctx) MsgMagicalCalamity
    return (Just OntologicalToSemantic)

-- | QuitEvent：ontological-world に MsgBalse を enqueue し、OntologicalToStop を返す
-- MsgBalse を受けた ontological-world は pipeline を正常終了する。
instance IStateActivity OntologicalStateData QuitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Ontological: Quit -> enqueue MsgBalse to ontological-world. transit to Stop.")
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_ontologicalQueueGlobalContext ctx) MsgBalse
    return (Just OntologicalToStop)
