{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Response.ApplicationBase.State.Start where

import Control.Monad.Logger

import CPA.Response.CoreModel.Type
import CPA.Response.CoreModel.TH

instanceTH_IWorldState ''StartStateData

instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS "CPA.Response" "Start: entry."
    return noStateTransition

instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS "CPA.Response" "Start: exit."
    return noStateTransition

instance IStateActivity StartStateData TransitEventData

-- | Start 状態では OutputEvent を処理しない（処理なし）
instance IStateActivity StartStateData OutputEventData where
  action _ _ = return noStateTransition
