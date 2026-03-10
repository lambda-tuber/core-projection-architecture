module CPA.Semantic.ApplicationBase.Control where

import Control.Monad.Trans.Reader (runReaderT)
import Control.Monad.Trans.State  (runStateT)

import CPA.Semantic.CoreModel.Type
  ( GlobalConfig
  , ContextualState
  , Avatar
  , LoadAvatar
  , SaveAvatar
  )
import CPA.Semantic.ProjectedContext.Context
  ( ProjectedContext
  , attacked
  , heal
  )

-- | ProjectedContext を実行して結果と最終状態を返す
-- 底が IO になったので IO で包んで返す
runProjectedContext
  :: GlobalConfig
  -> ContextualState
  -> ProjectedContext a
  -> IO (a, ContextualState)
runProjectedContext config initState action =
  runStateT (runReaderT action config) initState

-- | run 関数（Interface層代替）
-- loadAvatar / saveAvatar は Boot層がインジェクト（形式化スコープ外）
runAttacked
  :: GlobalConfig -> ContextualState
  -> LoadAvatar -> SaveAvatar
  -> Int
  -> IO (Avatar, ContextualState)
runAttacked config state loadAvatar saveAvatar damage =
  runProjectedContext config state (attacked loadAvatar saveAvatar damage)

runHeal
  :: GlobalConfig -> ContextualState
  -> LoadAvatar -> SaveAvatar
  -> IO (Avatar, ContextualState)
runHeal config state loadAvatar saveAvatar =
  runProjectedContext config state (heal loadAvatar saveAvatar)
