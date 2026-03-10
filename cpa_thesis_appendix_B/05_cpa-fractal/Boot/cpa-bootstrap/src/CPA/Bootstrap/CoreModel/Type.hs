{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-orphans #-}
-- ^ FromJSON/ToJSON LogLevel は bootstrap の YAML 読み込み専用の意図的な孤立インスタンス。
--   multiverse に aeson 依存を追加しないための設計判断。

module CPA.Bootstrap.CoreModel.Type where

import Data.Default
import Control.Lens
import Control.Monad.Logger (LogLevel (..))
import Data.Aeson
import Data.Aeson.TH
import qualified Data.Text as T
import qualified Text.Read as R

import CPA.Bootstrap.CoreModel.Utility

--------------------------------------------------------------------------------
-- LogLevel の Aeson インスタンス
--
-- bootstrap の YAML 読み込みでのみ使用するため、ここで定義する。
-- multiverse に aeson 依存を追加することを避けるための判断。
-- 将来、他パッケージでも YAML を扱う場合は multiverse への移動を検討する。
--
-- FromJSON: "Level" プレフィックスを付加して Read インスタンスで解決する。
-- ToJSON:   LevelOther m は Text をそのまま返す。
--------------------------------------------------------------------------------

instance FromJSON LogLevel where
  parseJSON (String v) = case R.readEither ("Level" ++ T.unpack v) of
    Right l  -> pure l
    Left  er -> fail $ "invalid logLevel. <" ++ T.unpack v ++ "> " ++ er
  parseJSON o = fail $ "json parse error. LogLevel: " ++ show o

instance ToJSON LogLevel where
  toJSON  LevelDebug    = String "Debug"
  toJSON  LevelInfo     = String "Info"
  toJSON  LevelWarn     = String "Warn"
  toJSON  LevelError    = String "Error"
  toJSON (LevelOther m) = String m

--------------------------------------------------------------------------------
-- ArgData（コマンドライン引数）
--------------------------------------------------------------------------------

-- | optparse-applicative で生成する引数データ
-- -y / --yaml でYAMLファイルパスを受け取る。省略時は def（LevelDebug / stderr）を使用。
data ArgData = ArgData
  { _yamlArgData :: Maybe FilePath
  } deriving (Show)

makeLenses ''ArgData

--------------------------------------------------------------------------------
-- ConfigData（YAML設定）
--
-- YAML フォーマット：
--   logLevel: Debug   # Debug / Info / Warn / Error
--   logDir: ""        # "" = stderr / フルパス = ライブラリ別ファイル出力
--
-- deriveJSON で _logLevelConfigData → "logLevel"、
--             _logDirConfigData   → "logDir" に自動変換する。
--------------------------------------------------------------------------------

data ConfigData = ConfigData
  { _logLevelConfigData :: LogLevel   -- ログレベル（デフォルト LevelDebug）
  , _logDirConfigData   :: FilePath   -- "" = stderr / フルパス = ライブラリ別ファイル出力
  } deriving (Show)

makeLenses ''ConfigData

$(deriveJSON
  defaultOptions { fieldLabelModifier = dropDataName "ConfigData" }
  ''ConfigData)

instance Default ConfigData where
  def = ConfigData
    { _logLevelConfigData = LevelDebug
    , _logDirConfigData   = ""
    }
