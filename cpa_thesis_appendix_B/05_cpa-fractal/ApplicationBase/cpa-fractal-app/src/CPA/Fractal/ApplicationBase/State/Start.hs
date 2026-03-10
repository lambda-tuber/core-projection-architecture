{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Fractal.ApplicationBase.State.Start where

import Control.Monad.IO.Class         (liftIO)
import Control.Monad.Trans.Class      (lift)
import Control.Monad.Trans.Reader     (ask)
import Control.Monad.Logger
import qualified Control.Concurrent.STM as STM
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.Multiverse.CoreModel.Constant (_USAGE_MESSAGE)
import CPA.Fractal.CoreModel.Type
import CPA.Fractal.CoreModel.TH

instanceTH_IWorldState ''StartStateData

instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Start: entry.")
    return noStateTransition

-- | Exit：初期 Avatar を semantic-world に注入し、起動挨拶メッセージを送信する。
-- MsgSetAvatar と ResWorldLog を同一 STM トランザクションで atomically に enqueue する。
-- これにより Avatar 注入と挨拶メッセージの順序が STM レベルで保証される。
-- cpa-response が ResWorldLog を受け取り出力後、自動で ">>> " プロンプトを表示する。
instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Start: exit. injecting initial Avatar to semantic-world.")
    ctx <- lift $ lift ask
    let initialAvatar = Avatar
          { _nameAvatar  = "Hero"
          , _levelAvatar = 1
          , _hpAvatar    = 100
          , _mpAvatar    = 50
          }
    liftIO $ STM.atomically $ do
      -- 1. 初期 Avatar を semantic-world に注入
      STM.writeTQueue (_semanticQueueGlobalContext ctx) (MsgSetAvatar initialAvatar)
      -- 2. 起動挨拶メッセージを response に送信（_USAGE_MESSAGE を共有）
      STM.writeTQueue (_responseQueueGlobalContext ctx)
        (ResWorldLog $ "cpa-fractal-app を開始します。\n" ++ _USAGE_MESSAGE)
    return noStateTransition

instance IStateActivity StartStateData TransitEventData

instance IStateActivity StartStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Start: AttackedEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData HealEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Start: HealEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData SetAvatarEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Start: SetAvatarEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData CalamityEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Start: CalamityEvent not handled.")
    return noStateTransition

instance IStateActivity StartStateData QuitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.Fractal") (T.pack "Start: QuitEvent not handled.")
    return noStateTransition
