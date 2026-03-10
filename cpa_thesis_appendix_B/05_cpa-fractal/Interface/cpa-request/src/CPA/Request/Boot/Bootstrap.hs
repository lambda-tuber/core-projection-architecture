module CPA.Request.Boot.Bootstrap where

import CPA.Multiverse.CoreModel.Type (GlobalContext)
import qualified CPA.Request.ApplicationBase.Control as Control
import CPA.Request.Interface.Stdio (readStdin)

-- | cpa-request のエントリポイント。
-- 本番用 readStdin を注入して Control.run を起動する。
-- cpa-boot から run ctx で呼ばれる。
run :: GlobalContext -> IO ()
run ctx = Control.run readStdin ctx
