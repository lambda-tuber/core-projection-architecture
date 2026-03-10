{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Application.State.ApplicationBase.State.Start where

import Control.Monad.Logger
import qualified Data.Text as T

import CPA.Application.State.CoreModel.Type
import CPA.Application.State.CoreModel.TH

-- | Template Haskell で IAppState StartStateData インスタンスを自動生成
instanceTH_IAppState ''StartStateData

-- | Entry：Start 状態に入ったときのログ
instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: entry.")
    return noStateTransition

-- | Exit：Start 状態を出るときのログ
instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: exit.")
    return noStateTransition

-- | Transit：デフォルト実装（StartToRun を受け付ける）
instance IStateActivity StartStateData TransitEventData

-- | AttackedEvent：Start 状態では何もしない（デフォルト）
instance IStateActivity StartStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: AttackedEvent not handled in this state.")
    return noStateTransition
