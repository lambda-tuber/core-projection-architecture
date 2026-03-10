module CPA.Application.State.CoreModel.Utility where

import Control.Monad.Trans.State.Lazy

import CPA.Application.State.CoreModel.Type

-- | 状態遷移の実行：Exit → Entry → modify の順で処理する
changeTo :: AppStateW -> AppStateContext ()
changeTo nextSt = do
  curSt <- get
  _ <- actionSW curSt (EventW ExitEvent)
  _ <- actionSW nextSt (EventW EntryEvent)
  modify (\_ -> nextSt)
