{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module CPA.OntologicalWorld.CoreModel.Type where

import Control.Monad.Trans.State.Lazy
import Control.Monad.Logger
import Control.Monad.Reader
import Control.Monad.Trans.Except
import Data.Kind                    (Type)

import qualified CPA.Multiverse.CoreModel.Type as MV

--------------------------------------------------------------------------------
-- Avatar m（存在論的 Avatar：世界パラメータ付き）
--------------------------------------------------------------------------------

data Avatar (m :: Type -> Type) = Avatar
  { _nameAvatarO  :: String
  , _levelAvatarO :: Int
  , _hpAvatarO    :: Int
  , _mpAvatarO    :: Int
  } deriving (Show)

--------------------------------------------------------------------------------
-- World 型クラス
--
-- vanishAvatar を追加：転移プロトコルで Avatar を消去するためのメソッド。
-- putAvatar の型は変更しない。vanishAvatar は「消す」専用。
--------------------------------------------------------------------------------

class Monad m => World (m :: Type -> Type) where
  takeAvatar   :: m (Avatar m)
  putAvatar    :: Avatar m -> m ()
  vanishAvatar :: m ()
  healInWorld  :: m (Avatar m)

--------------------------------------------------------------------------------
-- AnotherWorld
--------------------------------------------------------------------------------

newtype AnotherWorld a = AnotherWorld
  { runAnotherWorld :: StateT (Maybe (Avatar AnotherWorld)) IO a
  } deriving (Functor, Applicative, Monad, MonadIO)

-- | AnotherWorld の初期状態（住人なし）
emptyAnotherWorld :: AnotherWorld ()
emptyAnotherWorld = AnotherWorld $ put Nothing

instance World AnotherWorld where
  takeAvatar = AnotherWorld $ do
    mav <- get
    case mav of
      Just av -> return av
      Nothing -> error "takeAvatar: avatar not initialized. send MsgSetAvatar before Attacked/Heal."

  putAvatar av = AnotherWorld $ put (Just av)

  -- | Avatar を消去する（転移プロトコル用）
  -- 転移後に takeAvatar が呼ばれると error になる。
  vanishAvatar = AnotherWorld $ put Nothing

  healInWorld = do
    av <- takeAvatar
    let healAmount = _levelAvatarO av * 5
        mpCost     = 10
        maxHp      = 100
        av' = av { _hpAvatarO = min maxHp (_hpAvatarO av + healAmount)
                 , _mpAvatarO = max 0     (_mpAvatarO av - mpCost)
                 }
    putAvatar av'
    return av'

-- | 転生プロトコル：cpa-multiverse Avatar → Avatar AnotherWorld
toOntologicalAvatar :: MV.Avatar -> Avatar AnotherWorld
toOntologicalAvatar av = Avatar
  { _nameAvatarO  = MV._nameAvatar av
  , _levelAvatarO = MV._levelAvatar av
  , _hpAvatarO    = MV._hpAvatar av
  , _mpAvatarO    = MV._mpAvatar av
  }

-- | Avatar AnotherWorld → cpa-multiverse Avatar（Response 送信用）
toMultiverseAvatar :: Avatar AnotherWorld -> MV.Avatar
toMultiverseAvatar av = MV.Avatar
  { MV._nameAvatar  = _nameAvatarO av
  , MV._levelAvatar = _levelAvatarO av
  , MV._hpAvatar    = _hpAvatarO av
  , MV._mpAvatar    = _mpAvatarO av
  }

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

data EntryEventData           = EntryEventData           deriving (Show)
data ExitEventData            = ExitEventData            deriving (Show)
data TransitEventData         = TransitEventData StateTransition deriving (Show)
data AttackedEventData        = AttackedEventData Int    deriving (Show)
data HealEventData            = HealEventData            deriving (Show)
data SetAvatarEventData       = SetAvatarEventData MV.Avatar deriving (Show)
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

data EventW = forall r. EventW (Event r)

toEventW :: MV.Message -> EventW
toEventW (MV.MsgAttacked n)    = EventW (AttackedEvent        (AttackedEventData n))
toEventW MV.MsgHeal            = EventW (HealEvent            HealEventData)
toEventW (MV.MsgSetAvatar av)  = EventW (SetAvatarEvent       (SetAvatarEventData av))
toEventW MV.MsgMagicalCalamity = EventW (MagicalCalamityEvent MagicalCalamityEventData)
toEventW MV.MsgBalse           = error "toEventW: MsgBalse must be handled in src before reaching here."

--------------------------------------------------------------------------------
-- WorldState Types
--------------------------------------------------------------------------------

type WorldStateContext =
  ExceptT String (StateT WorldStateW (ReaderT MV.GlobalContext (LoggingT IO)))

--------------------------------------------------------------------------------
-- WorldState Data
--------------------------------------------------------------------------------

data StartStateData = StartStateData deriving (Show)

data RunStateData = RunStateData { _worldRunStateData :: AnotherWorld () }

instance Show RunStateData where
  show _ = "RunStateData { _worldRunStateData = AnotherWorld ... }"

data StopStateData = StopStateData deriving (Show)

--------------------------------------------------------------------------------
-- WorldState GADT
--------------------------------------------------------------------------------

data WorldState s where
  StartState :: WorldState StartStateData
  RunState   :: RunStateData -> WorldState RunStateData
  StopState  :: WorldState StopStateData

deriving instance Show s => Show (WorldState s)

data WorldStateW = forall s. (IWorldState s, Show s) => WorldStateW (WorldState s)

initRunState :: WorldState RunStateData
initRunState = RunState (RunStateData emptyAnotherWorld)

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
