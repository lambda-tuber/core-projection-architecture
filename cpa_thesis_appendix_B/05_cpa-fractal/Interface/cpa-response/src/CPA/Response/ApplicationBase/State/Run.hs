{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Response.ApplicationBase.State.Run where

import Control.Monad.IO.Class         (liftIO)
import Control.Monad.Logger
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.Response.CoreModel.Type
import CPA.Response.CoreModel.TH

instanceTH_IWorldState ''RunStateData

instance IStateActivity RunStateData EntryEventData where
  action _ _ = do
    $logDebugS "CPA.Response" "Run: entry."
    return noStateTransition

instance IStateActivity RunStateData ExitEventData where
  action _ _ = do
    $logDebugS "CPA.Response" "Run: exit."
    return noStateTransition

-- | Transit：デフォルト実装（RunToStop を受け付ける）
instance IStateActivity RunStateData TransitEventData

-- | OutputEvent：writeFn で Response を stdout に出力する。
-- ResQuit → RunToStop（pipeline 終了）
-- other   → (formatResponse resp <> "\n") を出力（改行あり）
--           → ">>> " を出力（改行なし・即フラッシュ）
--           改行の有無は writeFn の呼び出し側（ここ）が責任を持つ。
--           writeFn の実体（writeStdout）は putStr のみ。
instance IStateActivity RunStateData OutputEventData where
  action _ (OutputEvent (OutputEventData writeFn resp)) = do
    case resp of
      ResQuit -> do
        $logDebugS "CPA.Response" "Run: ResQuit received. RunToStop."
        return (Just RunToStop)
      _ -> do
        let txt = formatResponse resp
        liftIO $ writeFn (txt <> "\n")  -- 通常出力（改行あり）
        liftIO $ writeFn ">>> "         -- プロンプト（改行なし・即フラッシュ）
        $logDebugS "CPA.Response" $ T.pack $ "Run: output: " ++ T.unpack txt
        return noStateTransition

--------------------------------------------------------------------------------
-- formatResponse
--------------------------------------------------------------------------------

formatResponse :: Response -> T.Text
formatResponse (ResAvatarStatus av) = T.pack $ "Avatar: " ++ show av
formatResponse (ResWorldLog msg)    = T.pack msg
formatResponse ResQuit              = T.pack "cpa-response: quit."
