module CPA.Response.Interface.Stdio where

import qualified Data.Text    as T
import qualified Data.Text.IO as TIO
import System.IO (hFlush, stdout)

-- | stdout に文字列を書き出す。改行は含まない。hFlush で即フラッシュ。
-- 改行の有無は呼び出し側（Run.hs）が責任を持つ。
-- 通常出力: writeFn (txt <> "\n")
-- プロンプト: writeFn ">>> "（改行なし）
writeStdout :: T.Text -> IO ()
writeStdout t = do
  TIO.putStr t
  hFlush stdout
