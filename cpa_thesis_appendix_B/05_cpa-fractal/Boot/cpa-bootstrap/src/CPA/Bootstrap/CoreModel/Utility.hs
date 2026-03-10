module CPA.Bootstrap.CoreModel.Utility where

-- | deriveJSON の fieldLabelModifier 用ヘルパー
-- フィールド名から先頭の "_" と末尾のデータ名サフィックスを除去する。
-- 例：_logLevelConfigData → "logLevel"（dropDataName "ConfigData" を渡す）
dropDataName :: String -> String -> String
dropDataName str = tail . reverse . drop (length str) . reverse
