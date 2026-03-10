module CPA.Multiverse.CoreModel.Type where

import Control.Concurrent.STM
import Control.Monad.Logger (LogLevel (..))

--------------------------------------------------------------------------------
-- Avatar（Core Model）
--------------------------------------------------------------------------------

-- | 全世界共通のアバター（Core Model）
-- フラクタル構造における唯一の存在。
-- 各ワールド（Projected Context）はこの Avatar を射影して処理する。
-- フィールド命名規則：_<フィールド名><データ名>（lens の makeLenses 対応）
data Avatar = Avatar
  { _nameAvatar  :: String
  , _levelAvatar :: Int
  , _hpAvatar    :: Int
  , _mpAvatar    :: Int
  } deriving (Show, Read, Eq)

--------------------------------------------------------------------------------
-- Request（cpa-request → fractal-app へのコマンド）
--------------------------------------------------------------------------------

-- | stdin から受け取る外部コマンド
-- Attacked は外界からの作用のためダメージ量を引数で受け取る。
-- Heal は Avatar 内部の能力発動のため引数なし（量は ProjectedContext で計算）。
-- MagicalCalamity は魔力災害発生による転移。
--   fractal-app の現在状態（Semantic / Ontological）によって転移方向が決まる。
--   Semantic 状態 → SemanticToOntological（転生）
--   Ontological 状態 → OntologicalToSemantic（帰還）
-- Quit は全ワールドを終了させる。
data Request
  = Attacked Int        -- ダメージ量（外から指定）
  | Heal                -- 回復（量は Avatar の能力から計算）
  | MagicalCalamity     -- 魔力災害発生 → Avatar を現在の世界から転移させる
  | Quit                -- 終了
  deriving (Show, Eq)

--------------------------------------------------------------------------------
-- Message（fractal-app → 各ワールドの TQueue に流す内部コマンド）
--------------------------------------------------------------------------------

-- | 各ワールドの TQueue に流す内部コマンド
-- Attacked は外界からの作用のためダメージ量を引数で受け取る。
-- Heal は Avatar 内部の能力発動のため引数なし（量は ProjectedContext で計算）。
-- SetAvatar は Avatar をワールドの RunStateData に注入する。
--   初期化時（fractal-app Start Exit）と転移着地時に使用。
-- MsgMagicalCalamity は魔力災害発生の通知。
--   受け取ったワールドは Avatar を取り出して相手ワールドの TQueue に MsgSetAvatar を enqueue する。
--   ワールド自身は止まらず Run を継続する。
-- Balse はワールドの pipeline を正常終了させる（Quit 時のみ）。
data Message
  = MsgAttacked Int        -- ダメージ量（外から指定）
  | MsgHeal                -- 回復（量は Avatar 能力から計算）
  | MsgSetAvatar Avatar    -- Avatar をワールドに注入する（初期化・転移着地）
  | MsgMagicalCalamity     -- 魔力災害発生（Avatar を相手ワールドへ転移させよ）
  | MsgBalse               -- pipeline を正常終了させる（Quit 時のみ）
  deriving (Show, Eq)

--------------------------------------------------------------------------------
-- Response（各ワールド → cpa-response への出力）
--------------------------------------------------------------------------------

-- | 各ワールドから responseQueue に流す出力
-- ResAvatarStatus：Avatar の現在状態を stdout に表示する。
-- ResWorldLog：ワールドからのログメッセージを stdout に表示する。
-- ResQuit：cpa-response の pipeline を正常終了させる終了センチネル。
--   MsgBalse（ワールド向け終了）と対称的な役割。
--   fractal-app が Quit を受信したとき responseQueue に enqueue する。
data Response
  = ResAvatarStatus Avatar   -- Avatar の現在状態
  | ResWorldLog String       -- ワールドからのログメッセージ
  | ResQuit                  -- pipeline 終了センチネル（fractal-app が Quit 時に送信）
  deriving (Show, Eq)

--------------------------------------------------------------------------------
-- GlobalContext（全パッケージ共通の注入コンテキスト）
--------------------------------------------------------------------------------

-- | fractal-app が生成し、各ワールドの run 関数に渡す注入コンテキスト
-- Avatar 型は semantic（Avatar）と ontological（Avatar m）で型が異なるため含めない。
-- 各ワールドが自身の Avatar 状態を内部保持する。
-- 転移時は MsgMagicalCalamity → MsgSetAvatar で Avatar を移送する。
--
-- ログ設定フィールド：
--   _logDirGlobalContext  : "" = stderr 出力 / フルパス = ライブラリ別ファイル出力
--                          bootstrap が doesDirectoryExist で存在確認済みの値を格納する。
--   _logLevelGlobalContext: 各パッケージのロガーが参照するログレベル。
--                          各パッケージは起動時にこれを見て自分のロガーを生成する。
data GlobalContext = GlobalContext
  { _requestQueueGlobalContext     :: TQueue Request    -- cpa-request → fractal-app への入力
  , _semanticQueueGlobalContext    :: TQueue Message    -- fractal-app → semantic-world 専用入力
  , _ontologicalQueueGlobalContext :: TQueue Message    -- fractal-app → ontological-world 専用入力
  , _responseQueueGlobalContext    :: TQueue Response   -- 全ワールド共通出力
  , _logDirGlobalContext           :: FilePath          -- "" or 存在確認済みフルパス
  , _logLevelGlobalContext         :: LogLevel          -- ログレベル（LevelDebug 等）
  }
