{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.OntologicalWorld.ApplicationBase.State.Stop where

import Control.Monad.Logger
import qualified Data.Text as T

import CPA.OntologicalWorld.CoreModel.Type
import CPA.OntologicalWorld.CoreModel.TH

instanceTH_IWorldState ''StopStateData

instance IStateActivity StopStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Stop: entry. world loop finished.")
    return noStateTransition

instance IStateActivity StopStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.OntologicalWorld") (T.pack "Stop: exit.")
    return noStateTransition

instance IStateActivity StopStateData TransitEventData

instance IStateActivity StopStateData AttackedEventData where
  action _ _ = return noStateTransition

instance IStateActivity StopStateData HealEventData where
  action _ _ = return noStateTransition

instance IStateActivity StopStateData SetAvatarEventData where
  action _ _ = return noStateTransition

-- | MagicalCalamityEvent：Stop 状態では処理しない
instance IStateActivity StopStateData MagicalCalamityEventData where
  action _ _ = return noStateTransition
