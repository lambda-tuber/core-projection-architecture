{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Request.ApplicationBase.State.Start where

import Control.Monad.Logger

import CPA.Request.CoreModel.Type
import CPA.Request.CoreModel.TH

instanceTH_IWorldState ''StartStateData

instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS "CPA.Request" "Start: entry."
    return noStateTransition

instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS "CPA.Request" "Start: exit."
    return noStateTransition

instance IStateActivity StartStateData TransitEventData

instance IStateActivity StartStateData InputEventData where
  action _ _ = return noStateTransition
