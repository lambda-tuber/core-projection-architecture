{-# LANGUAGE OverloadedStrings #-}

module CPA.Multiverse.CoreModel.Constant where

import System.Log.FastLogger (TimeFormat)

_LOG_FILE :: FilePath
_LOG_FILE = "cpa-multiverse.log"

-- | FastLogger のタイムスタンプフォーマット
_TIME_FORMAT :: TimeFormat
_TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

-- | 利用可能コマンドの usage メッセージ
-- cpa-request（パースエラー時）と cpa-fractal-app（起動挨拶）で共有する。
_USAGE_MESSAGE :: String
_USAGE_MESSAGE = "利用可能なコマンド: attacked <n> / heal / calamity / quit"
