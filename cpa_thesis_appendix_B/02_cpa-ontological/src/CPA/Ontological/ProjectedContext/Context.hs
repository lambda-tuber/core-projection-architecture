module CPA.Ontological.ProjectedContext.Context where

import Control.Monad.Trans.Class  (lift)
import Control.Monad.Trans.Reader (ReaderT, ask)
import Control.Monad.Trans.State  (StateT, modify)

import CPA.Ontological.CoreModel.Type
  ( GlobalConfig
  , ContextualState (..)
  , Avatar (..)
  , World (..)
  )

-- | 存在論的構成における Projected Context
-- 底は m（World パラメータ）
-- 意味論：ReaderT GlobalConfig (StateT ContextualState IO) a  ← 底が IO 固定
-- 存在論：ReaderT GlobalConfig (StateT ContextualState m)  a  ← 底が m（World）
-- m がスタックのパラメータとして現れることが内包型侵食の型レベル証拠
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m) a

-- | 被弾アクション
-- World m の loadAvatar でAvatarを取得し、hp を damage 分減らして saveAvatar で保存
-- 引数注入不要！World m 型クラスのメソッドとして内在化されている
attacked :: World m => Int -> ProjectedContext m (Avatar m)
attacked damage = do
  _ <- ask
  avatar <- lift . lift $ loadAvatar
  let newAvatar = avatar { hp = hp avatar - damage }
  lift . lift $ saveAvatar newAvatar
  lift $ modify (\s -> s { stateLog = stateLog s ++
      [ avatarName avatar ++ " was attacked."
        ++ " hp: " ++ show (hp avatar)
        ++ " -> "  ++ show (hp newAvatar)
      ] })
  pure newAvatar

-- | 魔法回復アクション
-- World m の loadAvatar でAvatarを取得し、hp を回復・mp を消費して saveAvatar で保存
-- 回復量：level * 5、MP消費：固定 10
heal :: World m => ProjectedContext m (Avatar m)
heal = do
  _ <- ask
  avatar <- lift . lift $ loadAvatar
  let healAmount = level avatar * 5
      mpCost     = 10
      newAvatar  = avatar { hp = hp avatar + healAmount, mp = mp avatar - mpCost }
  lift . lift $ saveAvatar newAvatar
  lift $ modify (\s -> s { stateLog = stateLog s ++
      [ avatarName avatar ++ " used heal."
        ++ " hp: " ++ show (hp avatar)
        ++ " -> "  ++ show (hp newAvatar)
        ++ ", mp: " ++ show (mp avatar)
        ++ " -> "  ++ show (mp newAvatar)
      ] })
  pure newAvatar
