module CPA.Response.CoreModel.Utility where

import Control.Monad.Trans.State.Lazy
import Control.Monad.Trans.Class (lift)

import CPA.Response.CoreModel.Type

-- | 状態遷移の実行：Exit → Entry → modify の順で処理する
-- ExceptT が外側にあるため、StateT 層へのアクセスは lift 経由。
changeTo :: WorldStateW -> WorldStateContext ()
changeTo nextSt = do
  curSt <- lift get
  _ <- actionSW curSt (EventW ExitEvent)
  _ <- actionSW nextSt (EventW EntryEvent)
  lift $ modify (\_ -> nextSt)
