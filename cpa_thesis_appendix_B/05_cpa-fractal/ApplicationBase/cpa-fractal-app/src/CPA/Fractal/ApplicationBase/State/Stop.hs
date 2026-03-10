{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Fractal.ApplicationBase.State.Stop where

import Control.Monad.Logger
import qualified Data.Text as T

import CPA.Fractal.CoreModel.Type
import CPA.Fractal.CoreModel.TH

-- | Template Haskell で IWorldState StopStateData インスタンスを自動生成
instanceTH_IWorldState ''StopStateData

-- | Entry：Stop 状態に入ったときのログ
instance IStateActivity StopStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Stop: entry. world loop finished.")
    return noStateTransition

-- | Exit：Stop 状態を出るときのログ
instance IStateActivity StopStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Stop: exit.")
    return noStateTransition

-- | Transit：デフォルト実装
instance IStateActivity StopStateData TransitEventData

-- | 以下のイベントは Stop 状態では全て処理しない
instance IStateActivity StopStateData AttackedEventData where
  action _ _ = return noStateTransition

instance IStateActivity StopStateData HealEventData where
  action _ _ = return noStateTransition

instance IStateActivity StopStateData SetAvatarEventData where
  action _ _ = return noStateTransition

instance IStateActivity StopStateData CalamityEventData where
  action _ _ = return noStateTransition

instance IStateActivity StopStateData QuitEventData where
  action _ _ = return noStateTransition
