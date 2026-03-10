{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Application.State.ApplicationBase.State.Stop where

import Control.Monad.Logger
import qualified Data.Text as T

import CPA.Application.State.CoreModel.Type
import CPA.Application.State.CoreModel.TH

-- | Template Haskell で IAppState StopStateData インスタンスを自動生成
instanceTH_IAppState ''StopStateData

-- | Entry：Stop 状態に入ったときのログ
instance IStateActivity StopStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Stop: entry.")
    return noStateTransition

-- | Exit：Stop 状態を出るときのログ
instance IStateActivity StopStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Stop: exit.")
    return noStateTransition

-- | Transit：Stop は遷移先なし（不正遷移は throwError で捕捉）
instance IStateActivity StopStateData TransitEventData

-- | AttackedEvent：Stop 状態では何もしない（デフォルト）
instance IStateActivity StopStateData AttackedEventData
