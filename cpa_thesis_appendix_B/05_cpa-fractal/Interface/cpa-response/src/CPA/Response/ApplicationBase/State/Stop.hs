{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Response.ApplicationBase.State.Stop where

import Control.Monad.Logger

import CPA.Response.CoreModel.Type
import CPA.Response.CoreModel.TH

instanceTH_IWorldState ''StopStateData

instance IStateActivity StopStateData EntryEventData where
  action _ _ = do
    $logDebugS "CPA.Response" "Stop: entry."
    return noStateTransition

instance IStateActivity StopStateData ExitEventData where
  action _ _ = do
    $logDebugS "CPA.Response" "Stop: exit."
    return noStateTransition

instance IStateActivity StopStateData TransitEventData

-- | Stop 状態では OutputEvent を処理しない（処理なし）
instance IStateActivity StopStateData OutputEventData where
  action _ _ = return noStateTransition
