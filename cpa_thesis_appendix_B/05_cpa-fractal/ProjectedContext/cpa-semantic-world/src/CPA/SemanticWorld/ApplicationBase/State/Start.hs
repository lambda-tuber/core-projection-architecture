{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.SemanticWorld.ApplicationBase.State.Start where

import Control.Monad.Logger
import qualified Data.Text as T

import CPA.SemanticWorld.CoreModel.Type
import CPA.SemanticWorld.CoreModel.TH

instanceTH_IWorldState ''StartStateData

instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Start: entry.")
    return noStateTransition

instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Start: exit.")
    return noStateTransition

instance IStateActivity StartStateData TransitEventData

instance IStateActivity StartStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Start: AttackedEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData HealEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Start: HealEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData SetAvatarEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Start: SetAvatarEvent not handled.")
    return noStateTransition

-- | MagicalCalamityEvent：Start 状態では処理しない
instance IStateActivity StartStateData MagicalCalamityEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Start: MagicalCalamityEvent not handled.")
    return noStateTransition
