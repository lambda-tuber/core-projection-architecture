module CPA.Response.Boot.Bootstrap where

import CPA.Multiverse.CoreModel.Type                (GlobalContext)
import qualified CPA.Response.ApplicationBase.Control as Control
import CPA.Response.Interface.Stdio                 (writeStdout)

-- | cpa-response のエントリポイント。
-- 本番用 writeStdout を注入して Control.run を起動する。
-- cpa-boot から run ctx で呼ばれる。
run :: GlobalContext -> IO ()
run ctx = Control.run writeStdout ctx
