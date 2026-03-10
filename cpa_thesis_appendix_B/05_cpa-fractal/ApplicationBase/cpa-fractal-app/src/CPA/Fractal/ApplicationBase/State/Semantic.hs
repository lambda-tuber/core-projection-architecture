{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Fractal.ApplicationBase.State.Semantic where

import Control.Monad.IO.Class         (liftIO)
import Control.Monad.Trans.Class      (lift)
import Control.Monad.Trans.Reader     (ask)
import Control.Monad.Logger
import qualified Control.Concurrent.STM as STM
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.Fractal.CoreModel.Type
import CPA.Fractal.CoreModel.TH

-- | Template Haskell で IWorldState SemanticStateData インスタンスを自動生成
instanceTH_IWorldState ''SemanticStateData

-- | Entry：Semantic 状態に入ったときのログ
instance IStateActivity SemanticStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Semantic: entry. semantic-world is now active.")
    return noStateTransition

-- | Exit：Semantic 状態を出るときのログ
instance IStateActivity SemanticStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Semantic: exit.")
    return noStateTransition

-- | Transit：デフォルト実装（SemanticToOntological / SemanticToStop を受け付ける）
instance IStateActivity SemanticStateData TransitEventData

-- | AttackedEvent：semantic-world の TQueue に MsgAttacked を enqueue
instance IStateActivity SemanticStateData AttackedEventData where
  action _ (AttackedEvent (AttackedEventData n)) = do
    $logDebugS (T.pack "CPA.Fractal") $ T.pack $ "Semantic: attacked " ++ show n ++ " -> enqueue to semantic-world."
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_semanticQueueGlobalContext ctx) (MsgAttacked n)
    return noStateTransition

-- | HealEvent：semantic-world の TQueue に MsgHeal を enqueue
instance IStateActivity SemanticStateData HealEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Semantic: heal -> enqueue to semantic-world.")
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_semanticQueueGlobalContext ctx) MsgHeal
    return noStateTransition

-- | SetAvatarEvent：Semantic 状態では直接処理しない（各ワールドが内部保持）
instance IStateActivity SemanticStateData SetAvatarEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Semantic: SetAvatarEvent not handled at fractal-app level.")
    return noStateTransition

-- | CalamityEvent：魔力災害発生
-- semantic-world に MsgMagicalCalamity を enqueue し、SemanticToOntological を返す。
-- semantic-world 側の責務：
--   1. takeAvatar で Avatar を取得
--   2. _ontologicalQueueGlobalContext に MsgSetAvatar av を enqueue
--   3. Run 継続（自分は止まらない）
instance IStateActivity SemanticStateData CalamityEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Semantic: MagicalCalamity! -> enqueue MsgMagicalCalamity to semantic-world. transit to Ontological.")
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_semanticQueueGlobalContext ctx) MsgMagicalCalamity
    return (Just SemanticToOntological)

-- | QuitEvent：semantic-world に MsgBalse を enqueue し、SemanticToStop を返す
-- MsgBalse を受けた semantic-world は pipeline を正常終了する。
instance IStateActivity SemanticStateData QuitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Semantic: Quit -> enqueue MsgBalse to semantic-world. transit to Stop.")
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $ STM.writeTQueue (_semanticQueueGlobalContext ctx) MsgBalse
    return (Just SemanticToStop)
