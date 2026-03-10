module CPA.Semantic.ProjectedContext.Context where

import Control.Monad.Trans.Class  (lift)
import Control.Monad.Trans.Reader (ReaderT, ask)
import Control.Monad.Trans.State  (StateT, modify)
import Control.Monad.IO.Class     (liftIO)

import CPA.Semantic.CoreModel.Type
  ( GlobalConfig
  , ContextualState (..)
  , Avatar (..)
  , LoadAvatar
  , SaveAvatar
  )

-- | 意味論的構成における Projected Context
-- 底は IO（LoadAvatar / SaveAvatar の IO を吸収）
-- スタック：ReaderT GlobalConfig が外、StateT ContextualState が中、IO が底
type ProjectedContext a = ReaderT GlobalConfig (StateT ContextualState IO) a

-- | 被弾アクション
-- loadAvatar で Avatar をロードし、hp を damage 分減らして saveAvatar で保存する
attacked :: LoadAvatar -> SaveAvatar -> Int -> ProjectedContext Avatar
attacked loadAvatar saveAvatar damage = do
  _ <- ask
  avatar <- liftIO loadAvatar
  let newAvatar = avatar { hp = hp avatar - damage }
  liftIO (saveAvatar newAvatar)
  lift $ modify (\s -> s { stateLog = stateLog s ++
      [ avatarName avatar ++ " was attacked."
        ++ " hp: " ++ show (hp avatar)
        ++ " -> "  ++ show (hp newAvatar)
      ] })
  pure newAvatar

-- | 魔法回復アクション
-- loadAvatar で Avatar をロードし、hp を回復・mp を消費して saveAvatar で保存する
-- 回復量：level * 5、MP消費：固定 10
heal :: LoadAvatar -> SaveAvatar -> ProjectedContext Avatar
heal loadAvatar saveAvatar = do
  _ <- ask
  avatar <- liftIO loadAvatar
  let healAmount = level avatar * 5
      mpCost     = 10
      newAvatar  = avatar { hp = hp avatar + healAmount, mp = mp avatar - mpCost }
  liftIO (saveAvatar newAvatar)
  lift $ modify (\s -> s { stateLog = stateLog s ++
      [ avatarName avatar ++ " used heal."
        ++ " hp: " ++ show (hp avatar)
        ++ " -> "  ++ show (hp newAvatar)
        ++ ", mp: " ++ show (mp avatar)
        ++ " -> "  ++ show (mp newAvatar)
      ] })
  pure newAvatar
