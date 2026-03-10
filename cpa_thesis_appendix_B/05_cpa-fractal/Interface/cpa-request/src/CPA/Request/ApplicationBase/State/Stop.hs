{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Request.ApplicationBase.State.Stop where

import Control.Monad.Logger

import CPA.Request.CoreModel.Type
import CPA.Request.CoreModel.TH

instanceTH_IWorldState ''StopStateData

instance IStateActivity StopStateData EntryEventData where
  action _ _ = do
    $logDebugS "CPA.Request" "Stop: entry."
    return noStateTransition

instance IStateActivity StopStateData ExitEventData where
  action _ _ = do
    $logDebugS "CPA.Request" "Stop: exit."
    return noStateTransition

instance IStateActivity StopStateData TransitEventData

instance IStateActivity StopStateData InputEventData where
  action _ _ = return noStateTransition
