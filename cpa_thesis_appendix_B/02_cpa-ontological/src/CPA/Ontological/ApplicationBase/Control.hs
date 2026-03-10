module CPA.Ontological.ApplicationBase.Control where

import Control.Monad.Trans.Reader (runReaderT)
import Control.Monad.Trans.State  (runStateT)

import CPA.Ontological.CoreModel.Type
  ( GlobalConfig
  , ContextualState
  , Avatar
  , World
  )
import CPA.Ontological.ProjectedContext.Context
  ( ProjectedContext
  , attacked
  , heal
  )

-- | ProjectedContext を実行して結果と最終状態を返す
-- World m 制約のみ。AnotherWorld を知らない！
-- m の具体化は Boot 層（形式化スコープ外）が担う
runProjectedContext
  :: Monad m
  => GlobalConfig
  -> ContextualState
  -> ProjectedContext m a
  -> m (a, ContextualState)
runProjectedContext config initState action =
  runStateT (runReaderT action config) initState

-- | 被弾アクションの実行（Interface 層代替）
-- World m 制約のみ。m が何であるかは呼び出し側が決める。
runAttacked
  :: World m
  => GlobalConfig -> ContextualState
  -> Int
  -> m (Avatar m, ContextualState)
runAttacked config state damage =
  runProjectedContext config state (attacked damage)

-- | 魔法回復アクションの実行（Interface 層代替）
runHeal
  :: World m
  => GlobalConfig -> ContextualState
  -> m (Avatar m, ContextualState)
runHeal config state =
  runProjectedContext config state heal
