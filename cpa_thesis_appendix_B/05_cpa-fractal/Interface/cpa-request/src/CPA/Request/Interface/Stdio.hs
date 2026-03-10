module CPA.Request.Interface.Stdio where

import qualified Data.Text    as T
import qualified Data.Text.IO as TIO
import System.IO (hIsEOF, stdin)

-- | stdin から1行読み込む。
-- EOF の場合は Nothing を返す。
-- conduit を知らない。EventW を知らない。「読む」副作用のみ。
-- src 側では hIsEOF を重複チェックしない。
readStdin :: IO (Maybe T.Text)
readStdin = do
  eof <- hIsEOF stdin
  if eof
    then return Nothing
    else Just <$> TIO.hGetLine stdin
