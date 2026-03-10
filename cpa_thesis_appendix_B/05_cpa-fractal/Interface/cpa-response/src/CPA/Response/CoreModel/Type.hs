{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ExistentialQuantification #-}

module CPA.Response.CoreModel.Type where

import Control.Monad.Trans.State.Lazy
import Control.Monad.Logger
import Control.Monad.Reader
import Control.Monad.Trans.Except
import qualified Data.Text as T

import CPA.Multiverse.CoreModel.Type

--------------------------------------------------------------------------------
-- State Transition
--------------------------------------------------------------------------------

data StateTransition
  = StartToRun
  | RunToStop
  deriving (Show, Eq)

noStateTransition :: Maybe StateTransition
noStateTransition = Nothing

--------------------------------------------------------------------------------
-- Event Data
--------------------------------------------------------------------------------

data EntryEventData   = EntryEventData   deriving (Show)
data ExitEventData    = ExitEventData    deriving (Show)
data TransitEventData = TransitEventData StateTransition deriving (Show)

-- | TQueue Response から読み込んだ Response と stdout 書き出し関数のペア。
-- work が Response + writeFn を OutputEventData に包んで EventW として yield する。
-- Run 状態の action が writeFn を呼んで stdout に書き出す。
-- writeFn は Bootstrap から注入（本番: writeStdout、テスト: mockWriteFn）。
data OutputEventData = OutputEventData
  { _writeFnOutputEventData  :: T.Text -> IO ()   -- 注入された書き出し関数
  , _responseOutputEventData :: Response           -- TQueue から読んだ Response
  }

instance Show OutputEventData where
  show (OutputEventData _ r) = "OutputEventData " ++ show r

--------------------------------------------------------------------------------
-- Event GADT
--------------------------------------------------------------------------------

data Event r where
  EntryEvent   :: Event EntryEventData
  ExitEvent    :: Event ExitEventData
  TransitEvent :: TransitEventData -> Event TransitEventData
  OutputEvent  :: OutputEventData  -> Event OutputEventData

deriving instance Show r => Show (Event r)

-- | 存在量化によるイベントラップ
data EventW = forall r. EventW (Event r)

--------------------------------------------------------------------------------
-- WorldState Types
--------------------------------------------------------------------------------

type WorldStateContext =
  ExceptT String (StateT WorldStateW (ReaderT GlobalContext (LoggingT IO)))

--------------------------------------------------------------------------------
-- WorldState Data
--------------------------------------------------------------------------------

data StartStateData = StartStateData deriving (Show)
data RunStateData   = RunStateData   deriving (Show)
data StopStateData  = StopStateData  deriving (Show)

--------------------------------------------------------------------------------
-- WorldState GADT
--------------------------------------------------------------------------------

data WorldState s where
  StartState :: WorldState StartStateData
  RunState   :: WorldState RunStateData
  StopState  :: WorldState StopStateData

deriving instance Show s => Show (WorldState s)

data WorldStateW = forall s. (IWorldState s, Show s) => WorldStateW (WorldState s)

initRunState :: WorldState RunStateData
initRunState = RunState

--------------------------------------------------------------------------------
-- Type Classes
--------------------------------------------------------------------------------

class (Show s, Show r) => IStateActivity s r where
  action :: WorldState s -> Event r -> WorldStateContext (Maybe StateTransition)
  action _ (TransitEvent (TransitEventData t)) = return (Just t)
  action _ _                                   = return Nothing

class IWorldState s where
  actionS :: WorldState s -> EventW -> WorldStateContext (Maybe StateTransition)

class IWorldStateW s where
  actionSW :: s -> EventW -> WorldStateContext (Maybe StateTransition)

instance IWorldStateW WorldStateW where
  actionSW (WorldStateW a) r = actionS a r
