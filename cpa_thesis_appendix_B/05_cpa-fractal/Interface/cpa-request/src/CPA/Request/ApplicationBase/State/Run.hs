{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Request.ApplicationBase.State.Run where

import Control.Monad.IO.Class         (liftIO)
import Control.Monad.Trans.Class      (lift)
import Control.Monad.Trans.Reader     (ask)
import Control.Monad.Logger
import qualified Control.Concurrent.STM as STM
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.Multiverse.CoreModel.Constant (_USAGE_MESSAGE)
import CPA.Request.CoreModel.Type
import CPA.Request.CoreModel.TH

instanceTH_IWorldState ''RunStateData

instance IStateActivity RunStateData EntryEventData where
  action _ _ = do
    $logDebugS "CPA.Request" "Run: entry."
    return noStateTransition

instance IStateActivity RunStateData ExitEventData where
  action _ _ = do
    $logDebugS "CPA.Request" "Run: exit."
    return noStateTransition

-- | Transit：デフォルト実装（RunToStop を受け付ける）
instance IStateActivity RunStateData TransitEventData

-- | InputEvent：Text を parseRequest して Request を requestQueue に enqueue する
-- Just Quit   → enqueue して RunToStop を返す（pipeline 終了）
-- Just other  → enqueue して noStateTransition（ループ継続）
-- Nothing     → usage を responseQueue に enqueue して noStateTransition（不正入力通知）
instance IStateActivity RunStateData InputEventData where
  action _ (InputEvent (InputEventData line)) = do
    case parseRequest line of
      Nothing -> do
        $logDebugS "CPA.Request" $ T.pack $ "Run: unknown input, skip: " ++ T.unpack line
        ctx <- lift $ lift ask
        liftIO $ STM.atomically $
          STM.writeTQueue (_responseQueueGlobalContext ctx) (ResWorldLog _USAGE_MESSAGE)
        return noStateTransition
      Just req -> do
        ctx <- lift $ lift ask
        liftIO $ STM.atomically $ STM.writeTQueue (_requestQueueGlobalContext ctx) req
        $logDebugS "CPA.Request" $ T.pack $ "Run: enqueue: " ++ show req
        case req of
          Quit -> return (Just RunToStop)
          _    -> return noStateTransition

--------------------------------------------------------------------------------
-- parseRequest（ApplicationBase の責務）
-- Interface.Stdio は「読む」副作用のみ。「解釈する」のは Run 状態。
--------------------------------------------------------------------------------

parseRequest :: T.Text -> Maybe Request
parseRequest t
  | t == "heal"             = Just Heal
  | t == "magical-calamity" = Just MagicalCalamity
  | t == "mc"               = Just MagicalCalamity
  | t == "calamity"         = Just MagicalCalamity
  | t == "quit"             = Just Quit
  | t == "q"                = Just Quit
  | "attacked " `T.isPrefixOf` t =
      case reads (T.unpack (T.drop (T.length "attacked ") t)) of
        [(n, "")] -> Just (Attacked n)
        _         -> Nothing
  | otherwise               = Nothing
