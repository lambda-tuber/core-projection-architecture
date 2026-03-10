{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ExistentialQuantification #-}

module CPA.SemanticWorld.CoreModel.Type where

import Control.Monad.Trans.State.Lazy
import Control.Monad.Logger
import Control.Monad.Reader
import Control.Monad.Trans.Except

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

data EntryEventData    = EntryEventData    deriving (Show)
data ExitEventData     = ExitEventData     deriving (Show)
data TransitEventData  = TransitEventData StateTransition deriving (Show)

-- | 外界からの作用：ダメージ量を引数で受け取る
data AttackedEventData = AttackedEventData Int deriving (Show)

-- | Avatar 内部の能力発動：引数なし（回復量は ProjectedContext で計算）
data HealEventData     = HealEventData         deriving (Show)

-- | Avatar をワールドの RunStateData に注入する（転生プロトコルの布石）
data SetAvatarEventData = SetAvatarEventData Avatar deriving (Show)

-- | 魔力災害発生：Avatar を相手ワールドへ転移させる
data MagicalCalamityEventData = MagicalCalamityEventData deriving (Show)

--------------------------------------------------------------------------------
-- Event GADT
--------------------------------------------------------------------------------

data Event r where
  EntryEvent           :: Event EntryEventData
  ExitEvent            :: Event ExitEventData
  TransitEvent         :: TransitEventData        -> Event TransitEventData
  AttackedEvent        :: AttackedEventData        -> Event AttackedEventData
  HealEvent            :: HealEventData            -> Event HealEventData
  SetAvatarEvent       :: SetAvatarEventData       -> Event SetAvatarEventData
  MagicalCalamityEvent :: MagicalCalamityEventData -> Event MagicalCalamityEventData

deriving instance Show r => Show (Event r)

-- | 存在量化によるイベントラップ（状態を意識せず統一的に扱う）
data EventW = forall r. EventW (Event r)

-- | Message → EventW 変換
-- MsgBalse は src レベルで弾かれるため、この関数には到達しない。
toEventW :: Message -> EventW
toEventW (MsgAttacked n)    = EventW (AttackedEvent        (AttackedEventData n))
toEventW MsgHeal            = EventW (HealEvent            HealEventData)
toEventW (MsgSetAvatar av)  = EventW (SetAvatarEvent       (SetAvatarEventData av))
toEventW MsgMagicalCalamity = EventW (MagicalCalamityEvent MagicalCalamityEventData)
toEventW MsgBalse           = error "toEventW: MsgBalse must be handled in src before reaching here."

--------------------------------------------------------------------------------
-- WorldState Types
--------------------------------------------------------------------------------

-- | モナドスタック
type WorldStateContext =
  ExceptT String (StateT WorldStateW (ReaderT GlobalContext (LoggingT IO)))

--------------------------------------------------------------------------------
-- WorldState Data
--------------------------------------------------------------------------------

data StartStateData = StartStateData deriving (Show)

-- | Run 状態：Avatar を値として保持する（TVar 撤廃、StateT で状態管理）
-- RunStateData の Avatar は MsgSetAvatar によって外部から注入される。
-- Nothing のまま Attacked / Heal を受けた場合は throwError になる。
data RunStateData = RunStateData { _avatarRunStateData :: Maybe Avatar } deriving (Show)

data StopStateData = StopStateData deriving (Show)

--------------------------------------------------------------------------------
-- WorldState GADT
--------------------------------------------------------------------------------

data WorldState s where
  StartState :: WorldState StartStateData
  RunState   :: RunStateData -> WorldState RunStateData
  StopState  :: WorldState StopStateData

deriving instance Show s => Show (WorldState s)

-- | 存在量化によるラップ（全状態を統一的に扱う）
data WorldStateW = forall s. (IWorldState s, Show s) => WorldStateW (WorldState s)

-- | Run 状態の初期値（Avatar は MsgSetAvatar で後から注入）
initRunState :: WorldState RunStateData
initRunState = RunState (RunStateData Nothing)

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
