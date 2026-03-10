{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ExistentialQuantification #-}

module CPA.Application.State.CoreModel.Type where

import Control.Monad.Trans.State.Lazy
import Control.Monad.Except
import Control.Monad.Logger
import Control.Monad.Reader

--------------------------------------------------------------------------------
-- State Transition
--------------------------------------------------------------------------------

data StateTransition =
    StartToRun
  | RunToStop
  deriving (Show, Eq)

noStateTransition :: Maybe StateTransition
noStateTransition = Nothing

--------------------------------------------------------------------------------
-- Event Data
--------------------------------------------------------------------------------

data EntryEventData    = EntryEventData    deriving (Show)
data ExitEventData     = ExitEventData     deriving (Show)
data TransitEventData  = TransitEventData StateTransition deriving (Show)
-- doActivity: ProjectedContext 呼び出しに対応するイベント（意味論・存在論共通）
data AttackedEventData = AttackedEventData deriving (Show)

--------------------------------------------------------------------------------
-- Event GADT
--------------------------------------------------------------------------------

data Event r where
  EntryEvent    :: Event EntryEventData
  ExitEvent     :: Event ExitEventData
  TransitEvent  :: TransitEventData  -> Event TransitEventData
  AttackedEvent :: AttackedEventData -> Event AttackedEventData

deriving instance Show r => Show (Event r)

-- | 存在量化によるイベントラップ（状態を意識せず統一的に扱う）
data EventW = forall r. EventW (Event r)

--------------------------------------------------------------------------------
-- AppState Types
--------------------------------------------------------------------------------

data GlobalConfig = GlobalConfig deriving (Show)

-- | モナドスタック：StateT AppStateW の上に Reader・Except・Logger・IO を積む
type AppStateContext = StateT AppStateW (ReaderT GlobalConfig (ExceptT String (LoggingT IO)))
type AppContext = AppStateContext

--------------------------------------------------------------------------------
-- AppState GADT（GADTs によるステートパターン）
--------------------------------------------------------------------------------

data StartStateData = StartStateData deriving (Show)
data RunStateData   = RunStateData   deriving (Show)
data StopStateData  = StopStateData  deriving (Show)

data AppState s where
  StartState :: AppState StartStateData
  RunState   :: AppState RunStateData
  StopState  :: AppState StopStateData

deriving instance Show s => Show (AppState s)

-- | 存在量化によるラップ（全状態を統一的に扱う）
data AppStateW = forall s. (IAppState s, Show s) => AppStateW (AppState s)

--------------------------------------------------------------------------------
-- Type Classes
--------------------------------------------------------------------------------

-- | 状態ごとのイベント処理（デフォルト実装：遷移イベントのみ処理、他は何もしない）
class (Show s, Show r) => IStateActivity s r where
  action :: (AppState s) -> (Event r) -> AppStateContext (Maybe StateTransition)
  action _ (TransitEvent (TransitEventData t)) = return (Just t)
  action _ _                                   = return Nothing

-- | 状態ごとの EventW ディスパッチ
class IAppState s where
  actionS :: AppState s -> EventW -> AppStateContext (Maybe StateTransition)

-- | AppStateW に対する EventW ディスパッチ
class IAppStateW s where
  actionSW :: s -> EventW -> AppStateContext (Maybe StateTransition)

instance IAppStateW AppStateW where
  actionSW (AppStateW a) r = actionS a r
