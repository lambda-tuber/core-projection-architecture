{-# LANGUAGE KindSignatures #-}

module CPA.Ontological.CoreModel.Type where

import Data.Kind (Type)

-- | 大域設定（ReaderT の環境）
data GlobalConfig = GlobalConfig
  { configName :: String
  } deriving (Show)

-- | 文脈的状態（StateT の状態）
data ContextualState = ContextualState
  { stateLog :: [String]
  } deriving (Show)

-- | 存在（存在論的構成：世界パラメータ付き）
-- 意味論：data Avatar    ← 世界に依存しない
-- 存在論：data Avatar m  ← 世界 m に内在する（phantom type として世界を刻印）
data Avatar (m :: Type -> Type) = Avatar
  { avatarName :: String
  , level      :: Int
  , hp         :: Int
  , mp         :: Int
  } deriving (Show)

-- | World 型クラス：Avatar の取得・保存インターフェース
-- 意味論では LoadAvatar/SaveAvatar を「外から注入」（値レベル）
-- 存在論では World m のメソッドとして「内在化」（型レベル）
-- インスタンスの実装は Boot 層が担う（形式化スコープ外）
class Monad m => World (m :: Type -> Type) where
  loadAvatar :: m (Avatar m)
  saveAvatar :: Avatar m -> m ()
