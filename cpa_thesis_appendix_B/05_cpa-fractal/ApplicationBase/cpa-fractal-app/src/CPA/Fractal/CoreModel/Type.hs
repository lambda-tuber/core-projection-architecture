{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ExistentialQuantification #-}

module CPA.Fractal.CoreModel.Type where

import Control.Monad.Trans.State.Lazy
import Control.Monad.Logger
import Control.Monad.Reader
import Control.Monad.Trans.Except

import CPA.Multiverse.CoreModel.Type

--------------------------------------------------------------------------------
-- State Transition
--------------------------------------------------------------------------------

-- | fractal-app の状態遷移定義
-- TH の funcTH_transit はコンストラクタ名を "To" で分割して前後の状態を推定する。
--   StartToSemantic      → StartState    → SemanticState    （初回起動）
--   SemanticToOntological→ SemanticState → OntologicalState （MagicalCalamity・転生方向）
--   OntologicalToSemantic→ OntologicalState → SemanticState （MagicalCalamity・帰還方向）
--   SemanticToStop       → SemanticState → StopState        （Quit）
--   OntologicalToStop    → OntologicalState → StopState     （Quit）
-- 全コンストラクタが引数なし（arity=0）のため initXxxState 系の関数は不要。
data StateTransition
  = StartToSemantic
  | SemanticToOntological
  | OntologicalToSemantic
  | SemanticToStop
  | OntologicalToStop
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
data HealEventData     = HealEventData deriving (Show)

-- | Avatar をワールドの RunStateData に注入する（転移着地・初期化）
data SetAvatarEventData = SetAvatarEventData Avatar deriving (Show)

-- | 魔力災害発生：現在のワールドから Avatar を転移させる
-- fractal-app の現在状態（Semantic / Ontological）によって遷移方向が決まる。
data CalamityEventData = CalamityEventData deriving (Show)

-- | 終了：全ワールドに MsgBalse を送り pipeline を正常終了させる
data QuitEventData     = QuitEventData deriving (Show)

--------------------------------------------------------------------------------
-- Event GADT
--------------------------------------------------------------------------------

data Event r where
  EntryEvent     :: Event EntryEventData
  ExitEvent      :: Event ExitEventData
  TransitEvent   :: TransitEventData    -> Event TransitEventData
  AttackedEvent  :: AttackedEventData   -> Event AttackedEventData
  HealEvent      :: HealEventData       -> Event HealEventData
  SetAvatarEvent :: SetAvatarEventData  -> Event SetAvatarEventData
  CalamityEvent  :: CalamityEventData   -> Event CalamityEventData
  QuitEvent      :: QuitEventData       -> Event QuitEventData

deriving instance Show r => Show (Event r)

-- | 存在量化によるイベントラップ（状態を意識せず統一的に扱う）
data EventW = forall r. EventW (Event r)

-- | Request → EventW 変換
-- fractal-app のパイプライン work ステージで使用する。
-- MagicalCalamity は fractal-app の現在状態によって遷移方向が変わるが、
-- EventW 変換時点では CalamityEvent として統一し、状態側のアクションで方向を決める。
toEventW :: Request -> EventW
toEventW (Attacked n)    = EventW (AttackedEvent  (AttackedEventData n))
toEventW Heal            = EventW (HealEvent       HealEventData)
toEventW MagicalCalamity = EventW (CalamityEvent   CalamityEventData)
toEventW Quit            = EventW (QuitEvent       QuitEventData)

--------------------------------------------------------------------------------
-- WorldState Types
--------------------------------------------------------------------------------

-- | モナドスタック
-- ExceptT String：不正遷移・エラーを層内で閉じ込める。
-- StateT WorldStateW：ステートパターンの状態保持。
-- ReaderT GlobalContext：TQueue 群の注入。
-- LoggingT IO：ログ出力。
type WorldStateContext =
  ExceptT String (StateT WorldStateW (ReaderT GlobalContext (LoggingT IO)))

--------------------------------------------------------------------------------
-- WorldState Data（4状態）
--------------------------------------------------------------------------------

data StartStateData       = StartStateData       deriving (Show)
data SemanticStateData    = SemanticStateData    deriving (Show)
data OntologicalStateData = OntologicalStateData deriving (Show)
data StopStateData        = StopStateData        deriving (Show)

--------------------------------------------------------------------------------
-- WorldState GADT（4状態版）
--------------------------------------------------------------------------------

-- | fractal-app の状態
-- Start       : 起動直後。ExitAction で初期 Avatar を semantic-world に注入する。
-- Semantic    : semantic-world が「現在の世界」。Request を semantic TQueue に流す。
-- Ontological : ontological-world が「現在の世界」。Request を ontological TQueue に流す。
-- Stop        : 終了済み。全イベントを無視する。
data WorldState s where
  StartState       :: WorldState StartStateData
  SemanticState    :: WorldState SemanticStateData
  OntologicalState :: WorldState OntologicalStateData
  StopState        :: WorldState StopStateData

deriving instance Show s => Show (WorldState s)

-- | 存在量化によるラップ（全状態を統一的に扱う）
data WorldStateW = forall s. (IWorldState s, Show s) => WorldStateW (WorldState s)

--------------------------------------------------------------------------------
-- Type Classes
--------------------------------------------------------------------------------

-- | 状態ごとのイベント処理
-- デフォルト実装：TransitEvent のみ処理、他は何もしない
class (Show s, Show r) => IStateActivity s r where
  action :: WorldState s -> Event r -> WorldStateContext (Maybe StateTransition)
  action _ (TransitEvent (TransitEventData t)) = return (Just t)
  action _ _                                   = return Nothing

-- | 状態ごとの EventW ディスパッチ
class IWorldState s where
  actionS :: WorldState s -> EventW -> WorldStateContext (Maybe StateTransition)

-- | WorldStateW に対する EventW ディスパッチ
class IWorldStateW s where
  actionSW :: s -> EventW -> WorldStateContext (Maybe StateTransition)

instance IWorldStateW WorldStateW where
  actionSW (WorldStateW a) r = actionS a r
