{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.OntologicalWorld.ApplicationBase.State.Start where

import Control.Monad.Logger
import qualified Data.Text as T

import CPA.OntologicalWorld.CoreModel.Type
import CPA.OntologicalWorld.CoreModel.TH

instanceTH_IWorldState ''StartStateData

instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Start: entry.")
    return noStateTransition

instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Start: exit.")
    return noStateTransition

instance IStateActivity StartStateData TransitEventData

instance IStateActivity StartStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Start: AttackedEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData HealEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Start: HealEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData SetAvatarEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Start: SetAvatarEvent not handled.")
    return noStateTransition

-- | MagicalCalamityEvent：Start 状態では処理しない
instance IStateActivity StartStateData MagicalCalamityEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Start: MagicalCalamityEvent not handled.")
    return noStateTransition
