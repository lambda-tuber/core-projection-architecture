{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Application.State.ApplicationBase.State.Run where

import Control.Monad.Logger
import qualified Data.Text as T

import CPA.Application.State.CoreModel.Type
import CPA.Application.State.CoreModel.TH

-- | Template Haskell で IAppState RunStateData インスタンスを自動生成
instanceTH_IAppState ''RunStateData

-- | Entry：Run 状態に入ったときのログ
instance IStateActivity RunStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Run: entry.")
    return noStateTransition

-- | Exit：Run 状態を出るときのログ
instance IStateActivity RunStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Run: exit.")
    return noStateTransition

-- | Transit：デフォルト実装（RunToStop を受け付ける）
instance IStateActivity RunStateData TransitEventData

-- | AttackedEvent：Run 状態での doActivity
--   ProjectedContext のコールに対応（今回はログ出力で代替）
instance IStateActivity RunStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Run: AttackedEvent - ProjectedContext called. (doActivity)")
    return noStateTransition
