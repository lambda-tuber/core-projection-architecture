# Appendix B：Haskell による形式化コード

---

## B.4　ApplicationBase 状態管理（`cpa-application-state`）

### B.4.1　状態の種別と管理対象の確定

CPA のシステム状態は以下の4種に分類される。CR-006 ではこの分類を起点として形式化の管理対象を確定した。

| 種別 | 層 | 性質 | 形式化対象 |
|---|---|---|---|
| **Existential Info**（存在属性情報） | CoreModel | Avatar の HP・属性など「ただの値」。状態管理の対象ではない | 対象外（モデル定義のみ） |
| **Contextual State**（文脈的状態） | ProjectedContext | 射影計算中の一時的な記憶。SystemState から初期化され、フィードバックマッピングで返る | 対象外（CR-003〜005 で StateT として形式化済み） |
| **AppState**（アプリ存在様式） | ApplicationBase | アプリのライフサイクル（起動中・実行中・停止中）。存在の「様式」を表す | **★ 本節の形式化対象** |
| **External State**（外部世界状態） | Erosion 内部 | 管理境界の外側にある外部世界の状態 | 対象外（管理境界外） |

#### AppState の位置づけ

AppState はハードウェア・OS・ミドルウェア・ライブラリ・フレームワーク内部の状態とは区別される。これらの層の状態は CPA の管理対象外である。AppState は **フレームワークのエントリポイントと ApplicationBase の境界** において明示的に定義・保持・遷移させる状態であり、CPA が責任を持つ唯一の「存在様式」の形式化対象である。

AppState の形式化は意味論・存在論どちらの構成にも依存せず、**両構成に共通する ApplicationBase の責務**として独立して定義される。

---

### B.4.2　形式化の方針

以下の方針で形式化する。

- **GADTs によるステートパターン**：Start / Run / Stop の3状態を型レベルで表現する
- **存在量化 `AppStateW`**：全状態を統一的に扱えるラップ型を定義する
- **Template Haskell による自動生成**：IAppState インスタンスと transit 関数を状態・遷移定義から自動生成する
- **シンプルなイベントループ**：conduit 等の外部フレームワークを使わず HSpec から直接テスト可能な形にする。なお cpa-fractal では本スタンドアロン形式化を発展させ、Conduit パイプライン（`src .| work .| sink`）と TQueue による非同期駆動を採用している（B.5 参照）
- **ProjectedContext コールはログ出力で代替**：状態遷移の骨格の形式化に集中し、実際のアクション実行は代替する

---

### B.4.3　プロジェクト構成

```
cpa-application-state/
├── cpa-application-state.cabal
├── src/
│   └── CPA/Application/State/
│       ├── CoreModel/
│       │   ├── Type.hs      ← GADTs・型クラス・モナドスタック定義
│       │   ├── TH.hs        ← Template Haskell 自動生成関数
│       │   └── Utility.hs   ← changeTo（状態遷移の実行）
│       └── ApplicationBase/
│           ├── Control.hs   ← runAppBase・run・runAppState・transit（TH生成）
│           └── State/
│               ├── Start.hs ← Start 状態の IStateActivity インスタンス群
│               ├── Run.hs   ← Run 状態の IStateActivity インスタンス群
│               └── Stop.hs  ← Stop 状態の IStateActivity インスタンス群
└── test/
    └── CPA/Application/State/ApplicationBase/
        └── ControlSpec.hs   ← 状態遷移の実証テスト（4シナリオ）
```

```
┌──────────────────────────────────────────────────────────────┐
│  Boot（起動層）                                               │  ← 形式化スコープ外
│  AppStateW StartState を生成して run を呼ぶ                    │
├──────────────────────────────────────────────────────────────┤
│  Interface（現象層）                                          │  ← ControlSpec.hs が模擬
├──────────────────────────────────────────────────────────────┤
│  ApplicationBase / Control.hs                                │
│  runAppBase：イベントループ                                    │
│  transit   ：状態遷移の実行（TH自動生成）                       │
│  ApplicationBase / State / {Start, Run, Stop}.hs             │
│  各状態の IStateActivity インスタンス                          │
│                            （Entry/Exit/Transit/doActivity） │
├──────────────────────────────────────────────────────────────┤
│  CoreModel / Type.hs                                         │
│  AppState GADT / AppStateW / Event GADT / EventW             │
│  IStateActivity / IAppState / IAppStateW 型クラス             │
│  AppStateContext モナドスタック                               │
└──────────────────────────────────────────────────────────────┘
```

---

### B.4.4　CoreModel：型定義（`Type.hs`）

**ファイル：** `src/CPA/Application/State/CoreModel/Type.hs`

#### 状態遷移の定義

```haskell
data StateTransition =
    StartToRun
  | RunToStop
  deriving (Show, Eq)
```

#### イベント GADT

各イベントの型情報を型パラメータ `r` として保持する。`EventW` は存在量化によるラップで、イベントの種別を意識せず統一的に扱うために用いる。

```haskell
data Event r where
  EntryEvent    :: Event EntryEventData
  ExitEvent     :: Event ExitEventData
  TransitEvent  :: TransitEventData  -> Event TransitEventData
  AttackedEvent :: AttackedEventData -> Event AttackedEventData

-- 存在量化によるラップ
data EventW = forall r. EventW (Event r)
```

`AttackedEvent` は Run 状態の doActivity に対応するイベントであり、意味論・存在論の `attacked` アクションに相当する ProjectedContext コールを表現する。

#### AppState GADT とモナドスタック

```haskell
-- 状態種別（型レベル）
data StartStateData = StartStateData deriving (Show)
data RunStateData   = RunStateData   deriving (Show)
data StopStateData  = StopStateData  deriving (Show)

-- GADTs によるステートパターン：型パラメータで状態を区別する
data AppState s where
  StartState :: AppState StartStateData
  RunState   :: AppState RunStateData
  StopState  :: AppState StopStateData

-- 存在量化によるラップ（IAppState 制約を封じ込める）
data AppStateW = forall s. (IAppState s, Show s) => AppStateW (AppState s)

-- モナドスタック：状態保持・設定参照・エラー処理・ログ・IO を一括管理
type AppStateContext =
  StateT AppStateW (ReaderT GlobalConfig (ExceptT String (LoggingT IO)))
```

**`AppStateW` の役割：**
GADTs の型パラメータ `s` は個々のパターンマッチ節でのみ有効であり、リストやフィールドに複数の状態を混在させることができない。存在量化 `forall s.` によりこの制約を消去し、Start・Run・Stop を同一型として扱えるようにする。これがステートパターンの OOP 的多態性を Haskell の型システムで実現する核心的な機構である。

#### 型クラス定義

```haskell
-- 状態 s がイベント r を受け取ったときの処理（デフォルト：TransitEvent のみ処理）
class (Show s, Show r) => IStateActivity s r where
  action :: AppState s -> Event r -> AppStateContext (Maybe StateTransition)
  action _ (TransitEvent (TransitEventData t)) = return (Just t)
  action _ _                                   = return Nothing

-- 状態 s が EventW（存在量化されたイベント）をディスパッチする
class IAppState s where
  actionS :: AppState s -> EventW -> AppStateContext (Maybe StateTransition)

-- AppStateW（存在量化された状態）が EventW をディスパッチする
class IAppStateW s where
  actionSW :: s -> EventW -> AppStateContext (Maybe StateTransition)

instance IAppStateW AppStateW where
  actionSW (AppStateW a) r = actionS a r
```

---

### B.4.5　CoreModel：Template Haskell（`TH.hs`）

**ファイル：** `src/CPA/Application/State/CoreModel/TH.hs`

#### `instanceTH_IAppState`：IAppState インスタンスの自動生成

Event GADT のコンストラクタ数だけ `actionS` の節を自動生成する。Event に新しいコンストラクタが追加されても、各状態ファイルを修正することなく自動的に対応できる。

```haskell
-- 使用例（Start.hs）
instanceTH_IAppState ''StartStateData

-- 生成されるコード
instance IAppState StartStateData where
  actionS s (EventW r@EntryEvent{})    = action s r
  actionS s (EventW r@ExitEvent{})     = action s r
  actionS s (EventW r@TransitEvent{})  = action s r
  actionS s (EventW r@AttackedEvent{}) = action s r
```

#### `funcTH_transit`：transit 関数の自動生成

`StateTransition` コンストラクタの命名規約（`XxxToYyy` → `XxxState` から `YyyState` へ）を利用して、遷移関数を自動生成する。**不正遷移は `throwError` で `ExceptT` の `Left` に収める**（`fail` による IO 層への漏洩を防ぐ）。

```haskell
-- 生成されるコード
transit :: StateTransition -> AppStateContext ()
transit StartToRun = get >>= \case
  AppStateW StartState -> changeTo $ AppStateW RunState
  AppStateW x          -> throwError $
    "invalid state transition. trans:" ++ show StartToRun ++ ", curSt:" ++ show x
transit RunToStop = get >>= \case
  AppStateW RunState   -> changeTo $ AppStateW StopState
  AppStateW x          -> throwError $
    "invalid state transition. trans:" ++ show RunToStop  ++ ", curSt:" ++ show x
```

**`throwError` vs `fail` の設計的意味：**
`fail` は `MonadFail` の `IO` インスタンスを通じて IO 例外として投げられ、`ExceptT` を素通りして IO 層まで漏れる。`throwError` を用いることで不正遷移エラーが `ExceptT String` の `Left` に収まり、`AppStateContext` の層内で完結する。これは CPA の層構成が**型レベルで強制されている**ことの実証である。

#### `changeTo`：状態切り替えの実行（`Utility.hs`）

```haskell
-- Exit → Entry → modify の順で状態を切り替える
changeTo :: AppStateW -> AppStateContext ()
changeTo nextSt = do
  curSt <- get
  _ <- actionSW curSt  (EventW ExitEvent)   -- 現状態の Exit を発火
  _ <- actionSW nextSt (EventW EntryEvent)  -- 次状態の Entry を発火
  modify (\_ -> nextSt)                     -- StateT の状態を更新
```

---

### B.4.6　ApplicationBase：各状態の実装

#### Start 状態（`State/Start.hs`）

```haskell
-- TH で IAppState StartStateData インスタンスを自動生成
instanceTH_IAppState ''StartStateData

instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: entry.")
    return noStateTransition

instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: exit.")
    return noStateTransition

-- TransitEventData：デフォルト実装（StartToRun を受け付ける）
instance IStateActivity StartStateData TransitEventData

-- AttackedEvent：Start 状態では処理しない
instance IStateActivity StartStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: AttackedEvent not handled in this state.")
    return noStateTransition
```

#### Run 状態（`State/Run.hs`）

Run 状態の `AttackedEvent` が ProjectedContext コールに対応する doActivity である。今回はログ出力で代替するが、実際のシステムでは ProjectedContext の `attacked` アクションをここから呼び出す。

```haskell
instanceTH_IAppState ''RunStateData

instance IStateActivity RunStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Run: entry.")
    return noStateTransition

instance IStateActivity RunStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Run: exit.")
    return noStateTransition

-- TransitEventData：デフォルト実装（RunToStop を受け付ける）
instance IStateActivity RunStateData TransitEventData

-- AttackedEvent：doActivity（ProjectedContext コールに対応）
instance IStateActivity RunStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Run: AttackedEvent - ProjectedContext called. (doActivity)")
    return noStateTransition
```

#### Stop 状態（`State/Stop.hs`）

Stop 状態は遷移先を持たない終端状態である。`TransitEvent` を受け取った場合、TH 生成の `transit` が `throwError` でエラーを返す。

```haskell
instanceTH_IAppState ''StopStateData

instance IStateActivity StopStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Stop: entry.")
    return noStateTransition

instance IStateActivity StopStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Stop: exit.")
    return noStateTransition

instance IStateActivity StopStateData TransitEventData  -- 不正遷移は throwError
instance IStateActivity StopStateData AttackedEventData -- 何もしない
```

#### イベントループと実行ランナー（`Control.hs`）

```haskell
-- TH で transit 関数を生成
funcTH_transit

-- イベントリストを順番に処理するシンプルなループ
-- conduit 不使用・HSpec から直接テスト可能
runAppBase :: [EventW] -> AppStateContext ()
runAppBase []     = return ()
runAppBase (e:es) = do
  st     <- get
  result <- actionSW st e
  case result of
    Nothing -> runAppBase es
    Just t  -> transit t >> runAppBase es

-- Boot 層相当のエントリポイント（初期状態 StartState から起動）
run :: [EventW] -> IO (Either String ((), AppStateW))
run events = runAppState (AppStateW StartState) (runAppBase events)

-- AppStateContext を IO まで剥がすランナー
runAppState :: AppStateW -> AppStateContext a -> IO (Either String (a, AppStateW))
runAppState initSt ctx =
  runStderrLoggingT
    $ runExceptT
    $ flip runReaderT GlobalConfig
    $ runStateT ctx initSt
```

---

### B.4.7　動作確認（hspec による状態遷移の実証）

**ファイル：** `test/CPA/Application/State/ApplicationBase/ControlSpec.hs`

`run` 関数にイベントリストを渡し、最終状態と戻り値で状態遷移を検証する。

```haskell
-- ヘルパー：イベントを実行して最終 AppStateW を取得
runEvents :: [EventW] -> IO (Either String AppStateW)
runEvents events = fmap (fmap snd) <$> ... -- run の結果から最終状態を取り出す

stateLabel :: AppStateW -> String
stateLabel (AppStateW StartState) = "Start"
stateLabel (AppStateW RunState)   = "Run"
stateLabel (AppStateW StopState)  = "Stop"
```

| シナリオ | 入力イベント列 | 期待結果 |
|---|---|---|
| 1：Start → Run | `[TransitEvent StartToRun]` | 最終状態が `"Run"` |
| 2：Start → Run → Stop | `[TransitEvent StartToRun, TransitEvent RunToStop]` | 最終状態が `"Stop"` |
| 3：Run で doActivity | `[TransitEvent StartToRun, AttackedEvent]` | エラーなし・最終状態が `"Run"` |
| 4：不正遷移の捕捉 | `[TransitEvent RunToStop]`（Start 状態から） | `ExceptT` の `Left` にエラーが収まる |

シナリオ4の検証コード：

```haskell
context "Start 状態で RunToStop（不正遷移）を受け取ったとき" $ do
  it "ExceptT でエラーが捕捉されること" $ do
    let events = [ EventW (TransitEvent (TransitEventData RunToStop)) ]
    result <- runEvents events
    case result of
      Left  _  -> return ()   -- ExceptT の Left に収まればOK
      Right st -> expectationFailure $
        "エラーになるべきところが成功した。状態: " ++ stateLabel st
```

```bash
cd cpa-application-state && cabal build && cabal test
# 4 examples, 0 failures
```

---

### B.4.8　AppState 形式化の本質的な特徴

**特徴1：GADTs によるステートパターンの型安全性**
`AppState s` の型パラメータ `s` が状態を型レベルで区別する。Start・Run・Stop は個別の型として扱われ、状態ごとに異なる `IStateActivity` インスタンスを定義できる。

**特徴2：存在量化による多態性の実現**
`AppStateW = forall s. (IAppState s, Show s) => AppStateW (AppState s)` により、Start・Run・Stop を同一型として扱える。OOP のポリモーフィズムを型レベルで実現しつつ、各状態の型安全性を保持する。

**特徴3：Template Haskell による記述量の削減と拡張性**
`instanceTH_IAppState` が Event コンストラクタ数分の `actionS` 節を自動生成し、`funcTH_transit` が遷移名の命名規約から `transit` 関数を生成する。Event や StateTransition に新しいコンストラクタを追加しても、各状態ファイルを修正することなく対応できる。

**特徴4：`throwError` による層内エラー閉じ込め（CPA 層構成の型証明）**
不正遷移を `throwError` で `ExceptT String` の `Left` に収めることで、エラーが `AppStateContext` の計算文脈の内側に閉じ込められる。`fail` を用いた場合は IO 層まで漏れ、CPA の層境界を破壊する。HSpec のシナリオ4（`Left _ -> return ()`）がこの層構成の正しさを実証する。

**特徴5：意味論・存在論から独立した共通形式化**
AppState は B.1（意味論）・B.2（存在論）どちらの Avatar/World 構成にも依存しない。ApplicationBase の存在様式管理は、侵食の種別（外包・内包）に関わらず同一の型構造で定義される。これは CPA の層責務の独立性を示している。

---

### B.4.9　補足考察：状態遷移間のデータ共有

GoF のステートパターンは「状態ごとの振る舞いをカプセル化する」ことを本来の責務とする。したがって**「前の状態が持つデータを次の状態へ引き継ぐ」仕組みはパターンの標準的な範囲外**であり、必要に応じて外部に拡張として設計する必要がある。

EntryAction・ExitAction は各状態が持つフックであり、遷移時の共有処理を行う自然な挿入点となる。以下に、状態間データ共有の主要な設計アプローチを3分類で整理する。

---

#### アプローチ1：状態マシン内部への機能拡張（遷移フック）

状態遷移トリガーに「変換関数」を噛ませ、前状態の最終データと次状態の初期データを引数にとるユーザー定義関数を実行できるようにする方式。

```
changeTo 実行時：
  ExitAction(前状態)  →  変換関数(前状態データ, 次状態データ)  →  EntryAction(次状態)
```

Haskell での型イメージ：

```haskell
-- 遷移ごとに変換関数を定義する
type TransitFn s1 s2 = AppState s1 -> AppState s2 -> AppStateContext ()

handleTransition :: (State s1, State s2) => AppState s1 -> AppState s2 -> AppStateContext ()
```

**特徴：** 遷移ロジックが状態マシン内部に閉じており、型安全性を維持しやすい。ただし全遷移パターン（状態数の二乗）を網羅する必要があり、Template Haskell による自動生成またはデフォルト実装の上書きパターンで対応することになる。既存の `changeTo` / `funcTH_transit` への組み込みは別途検討が必要。

**cpa-fractal における判断：** 現状は不要。全遷移への対応コストに対し、得られる恩恵が小さいため採用しない。

---

#### アプローチ2：共有ストレージによる情報の受け渡し

状態マシンの外側（または上位レイヤー）に、遷移をまたいで維持される共有データ領域を設ける方式。EntryAction・ExitAction でこの領域を読み書きすることで、状態間のデータ引き継ぎを実現する。

共有データの実体は問わない。外部ファイル・RDB・オンメモリの拡張可能レコード・JSON（Aeson）など、システムの要件に応じて選択できる。Haskell では `StateT` をもう1段積む形が自然な実装となる。

```haskell
-- StateT を積んで共有コンテキストを持つイメージ
data SharedContext = SharedContext { sharedData :: Map Text Value }

type AppStateContext =
  StateT SharedContext (StateT AppStateW (ReaderT GlobalConfig (ExceptT String (LoggingT IO))))

-- ExitAction で書き込み、EntryAction で読み出す
onExit :: AppState s -> AppStateContext ()
onExit _ = modify (\ctx -> ctx { sharedData = ... })

onEntry :: AppState s -> AppStateContext ()
onEntry _ = gets sharedData >>= \d -> ...
```

共有データを `Map Text Value`（Aeson）で持つ場合、後からフィールドが増えても既存の状態定義を変更せずに対応できる。デバッグ時に共有メモリの中身をログ出力できる点も利点となる。

**特徴：** 状態クラスが互いの内部構造を知る必要がなく疎結合を保てる。全遷移パターンの網羅も不要。ただし共有領域が「何でもあり」のグローバル変数化しないよう、アクセス範囲の管理が必要。

**cpa-fractal における判断：** 現状は不要。状態間で引き継ぐデータは `MsgSetAvatar` によるイベント通知（アプローチ3）で十分に賄える。

---

#### アプローチ3：状態マシン外部での管理とイベント通知（cpa-fractal の現行方式）

状態マシンの外部エージェントがデータを保持・管理し、イベント（メッセージ）を通じて各状態へ情報を注入する方式。**cpa-fractal-app が現在採用している設計**である。

```
cpa-fractal-app（外部エージェント）
  │
  │  MsgSetAvatar（Avatar データをイベントとして送信）
  ▼
cpa-semantic-world / cpa-ontological-world（状態マシン）
  EntryAction で Avatar を受け取り内部状態に取り込む
```

具体的には、`fractal-app` の Start 状態の ExitAction が初期 Avatar を生成し、`MsgSetAvatar` として semantic-world の TQueue に enqueue する。また MagicalCalamity（転生）発生時も、Avatar の取り出しと相手ワールドへの `MsgSetAvatar` 送信はワールド側（受けたワールドの doActivity）が担い、fractal-app はあくまで転移指示（`MsgMagicalCalamity`）を送るだけとなる。

```haskell
-- Start 状態の ExitAction：初期 Avatar を semantic-world に注入
onExit StartState = do
  let avatar = Avatar { _nameAvatar = "Hero", ... }
  liftIO $ atomically $ writeTQueue semanticQueue (MsgSetAvatar avatar)

-- MsgMagicalCalamity を受けたワールドの doActivity：Avatar を取り出して相手ワールドへ転送
handleMagicalCalamity = do
  avatar <- takeAvatar
  liftIO $ atomically $ writeTQueue otherWorldQueue (MsgSetAvatar avatar)
```

**特徴：** 状態マシン内部の結合度がゼロに保たれる。データの所有者（外部エージェント）が明確であり、責務の境界が明快。非同期処理（TQueue）との相性も良い。ただし「どのタイミングで誰がデータを送るか」の設計がシステム全体の振る舞いに直結するため、イベントフローの設計が重要になる。

**cpa-fractal における判断：** 現行採用。Avatar の所有と転送責務が fractal-app とワールド間で明確に分離されており、現時点の要件を過不足なく満たす。

---

#### 3アプローチの比較

| アプローチ | データ管理の場所 | 状態間結合度 | cpa-fractal での採用 |
|---|---|---|---|
| 1. 遷移フック | 状態マシン内部 | 低〜中（遷移ペア間のみ） | 不要 |
| 2. 共有ストレージ | 状態マシン外側（共有領域） | 低（共有領域経由） | 不要 |
| 3. イベント通知 | 外部エージェント | ゼロ（イベント経由のみ） | **採用** |

GoF ステートパターンの純粋な範囲を超えてデータ引き継ぎが必要になった場合、システムの規模・非同期要件・型安全性の優先度に応じてこれら3アプローチを組み合わせるのが現実的な設計となる。

---
