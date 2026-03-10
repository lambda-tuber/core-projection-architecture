{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.SemanticWorld.ApplicationBase.State.Run where

import Control.Monad.Except           (throwError)
import Control.Monad.IO.Class         (liftIO)
import Control.Monad.Trans.Class      (lift)
import Control.Monad.Trans.State.Lazy (get, put)
import Control.Monad.Trans.Reader     (ask)
import Control.Monad.Logger
import qualified Control.Concurrent.STM as STM
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type
import CPA.SemanticWorld.CoreModel.Type
import CPA.SemanticWorld.CoreModel.TH
import CPA.SemanticWorld.ProjectedContext.Context

-- | Template Haskell で IWorldState RunStateData インスタンスを自動生成
instanceTH_IWorldState ''RunStateData

-- | Entry：Run 状態に入ったときのログのみ
instance IStateActivity RunStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Run: entry.")
    return noStateTransition

-- | Exit：Run 状態を出るときのログ
instance IStateActivity RunStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Run: exit.")
    return noStateTransition

-- | Transit：デフォルト実装（RunToStop を受け付ける）
instance IStateActivity RunStateData TransitEventData

-- | AttackedEvent
-- 意味論のパターン：
--   takeAvatar → runProjectedContext (return . attacked n) av → putAvatar
--   Avatar を WorldStateContext の外に取り出し、純粋関数を IO に持ち上げて適用し、書き戻す。
--
-- cf. ontological：
--   runProjectedContext (attacked n) → AnotherWorld の中で完結（Avatar は外に出ない）
instance IStateActivity RunStateData AttackedEventData where
  action _ (AttackedEvent (AttackedEventData n)) = do
    $logDebugS (T.pack "CPA.SemanticWorld") $ T.pack $ "Run: attacked " ++ show n
    av  <- takeAvatar
    av' <- liftIO $ runProjectedContext (return . attacked n) av
    putAvatar av'
    sendResponse (ResAvatarStatus av')
    return noStateTransition

-- | HealEvent
-- 意味論のパターン：
--   takeAvatar → runProjectedContext heal av → putAvatar
--   heal は IO Avatar を返すため、return での持ち上げは不要。
--
-- cf. ontological：
--   runProjectedContext heal → AnotherWorld の中で完結（Avatar は外に出ない）
instance IStateActivity RunStateData HealEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Run: heal.")
    av  <- takeAvatar
    av' <- liftIO $ runProjectedContext heal av
    putAvatar av'
    sendResponse (ResAvatarStatus av')
    return noStateTransition

-- | SetAvatarEvent：外部から注入された Avatar を RunStateData に書き込む
instance IStateActivity RunStateData SetAvatarEventData where
  action _ (SetAvatarEvent (SetAvatarEventData av)) = do
    $logDebugS (T.pack "CPA.SemanticWorld") $ T.pack $ "Run: setAvatar " ++ show av
    putAvatar av
    return noStateTransition

-- | MagicalCalamityEvent：転移プロトコル（semantic → ontological）
-- 1. takeAvatar で現在の Avatar を取り出す（いなければ throwError）
-- 2. vanishAvatar で自ワールドの Avatar を消去する
-- 3. 相手ワールド（ontological）の TQueue に MsgSetAvatar を enqueue する
-- 4. ResWorldLog で転移完了をユーザーに通知する（プロンプト再表示のため）
-- ワールド自身は止まらず Run を継続する。
instance IStateActivity RunStateData MagicalCalamityEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA.SemanticWorld") (T.pack "Run: MagicalCalamity. transferring avatar to ontological world.")
    av <- takeAvatar
    vanishAvatar
    ctx <- lift $ lift ask
    liftIO $ STM.atomically $
      STM.writeTQueue (_ontologicalQueueGlobalContext ctx) (MsgSetAvatar av)
    sendResponse (ResWorldLog "ontological-world が avatar を召喚しました。")
    return noStateTransition

--------------------------------------------------------------------------------
-- runProjectedContext（semantic 版）
--
-- ontological の execWorld に相当するコンテキスト切り替えポイント。
-- World がない分、スタックが1段少ない。
--
-- attacked（純粋）を渡すとき : runProjectedContext (return . attacked n) av
-- heal（IO）を渡すとき       : runProjectedContext heal av
--------------------------------------------------------------------------------

runProjectedContext :: Monad m => (a -> m b) -> a -> m b
runProjectedContext f x = f x

--------------------------------------------------------------------------------
-- ヘルパー関数
--------------------------------------------------------------------------------

-- | Avatar を WorldStateContext から取り出す
-- semantic では Avatar が「外に取り出される存在」であることを体現している。
-- Nothing の場合は throwError（MsgSetAvatar が先に来ていない、または転移済み）
takeAvatar :: WorldStateContext Avatar
takeAvatar = do
  st <- lift get
  case st of
    WorldStateW (RunState dat) ->
      case _avatarRunStateData dat of
        Just av -> return av
        Nothing -> throwError "avatar not initialized. send MsgSetAvatar before Attacked/Heal."
    _ ->
      throwError "takeAvatar called in non-Run state."

-- | Avatar を WorldStateContext に書き戻す
putAvatar :: Avatar -> WorldStateContext ()
putAvatar av = do
  st <- lift get
  case st of
    WorldStateW (RunState _) ->
      lift $ put $ WorldStateW $ RunState $ RunStateData (Just av)
    _ ->
      return ()

-- | Avatar を WorldStateContext から消去する（転移プロトコル用）
-- putAvatar とは逆に RunStateData を Nothing に戻す。
-- 転移後に Attacked / Heal が来た場合は takeAvatar が throwError になる。
vanishAvatar :: WorldStateContext ()
vanishAvatar = do
  st <- lift get
  case st of
    WorldStateW (RunState _) ->
      lift $ put $ WorldStateW $ RunState $ RunStateData Nothing
    _ ->
      return ()

sendResponse :: Response -> WorldStateContext ()
sendResponse res = do
  ctx <- lift $ lift ask
  liftIO $ STM.atomically $ STM.writeTQueue (_responseQueueGlobalContext ctx) res
