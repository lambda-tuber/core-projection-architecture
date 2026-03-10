module CPA.Semantic.CoreModel.Type where

-- | 大域設定（ReaderT の環境）
data GlobalConfig = GlobalConfig
  { configName :: String
  } deriving (Show)

-- | 文脈的状態（StateT の状態）
data ContextualState = ContextualState
  { stateLog :: [String]
  } deriving (Show)

-- | 存在（意味論的構成：世界パラメータなし）
data Avatar = Avatar
  { avatarName :: String
  , level      :: Int
  , hp         :: Int
  , mp         :: Int
  } deriving (Show)

-- | Avatar の永続化インターフェース型（Boot層がインジェクト、形式化スコープ外）
-- Avatarは1インスタンス固定のためIDなし
type LoadAvatar = IO Avatar
type SaveAvatar = Avatar -> IO ()
