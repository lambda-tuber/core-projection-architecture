# Appendix B：Haskell による形式化コード

---

## B.5　CPAフラクタル構造（`cpa-fractal`）

### B.5.1　本節の位置づけ

B.1〜B.3 ではスタンドアロンプロジェクト（`cpa-semantic`・`cpa-ontological`）として意味論的構成と存在論的構成を独立して形式化した。B.4 では AppState による状態管理を `cpa-application-state` として独立して形式化した。

本節が扱う `cpa-fractal` はこれら三つの形式化を**統合・発展**させた実証アプリケーションである。スタンドアロン版との最大の差異は「構造の繰り返し」にある。意味論ワールドと存在論ワールドのそれぞれが、CoreModel → ProjectedContext → ApplicationBase → Interface → Boot という**同一のレイヤ構成を内部に持ちながら**、全体もまた同一のレイヤ構成で組み上げられている。これが本節の表題における「フラクタル」の意味である。

本節（B.5）は論文第6章6.6節「フラクタル再帰性」（フラクタル再帰公理）の実証である。
公理5「Core Projection 構造は任意のスケールにおいて再帰的に成立する」が、
`cpa-fractal` の7パッケージ構成においてシステム全体（マクロ）と
各ワールドパッケージ内部（ミクロ）の双方で成立していることを示す。
また、B.5.8（Boot Layer）の型シグネチャは論文第8章8.6節「遡行依存則の型レベル証明」の
具体的な実装例として対応している。

---

### B.5.2　フラクタルとは何か

#### フラクタルの定義

本節における「フラクタル」とは、**同一のアーキテクチャ単位が、異なるスケールで自律した構造として繰り返し現れること**を指す。数学的なフラクタル図形と同様に、全体を構成する部分が全体と同じ構造を持つ。ここでいう「同一のアーキテクチャ単位」とは CPA の層構成（CoreModel → ProjectedContext → ApplicationBase → Interface → Boot）である。

この定義において重要なのは「自律した構造として」という点である。パイプラインの書き方やステートパターンの実装が各パッケージで共通していることは、設計の一貫性であってフラクタルではない。フラクタルとは、**あるパッケージがそれ単体で CPA の層構成を内包しており、システム全体と同じ構造的論理で動作できること**を指す。

#### CPA の層構成（5層）

CPA は以下の5層で構成される。

```
Boot              ← 起動・設定・注入の起点。上位層を知らない。
Interface         ← 外部世界との接点。入出力の変換。
ApplicationBase   ← アプリケーション基盤。状態管理・オーケストレーション。
ProjectedContext  ← 投影されたコンテキスト。ドメイン操作の実行場所。
CoreModel         ← 中心モデル。他のいかなる層にも依存しない。
```

依存方向は一方向であり、Boot が最も上位（多くを知る）、CoreModel が最も下位（何も知らない）である。

#### フラクタル性の観測

通常の階層型アーキテクチャでは、各層は「一度しか現れない」。しかし `cpa-fractal` では、**この5層構成がシステム全体（マクロ）にも、各ワールドパッケージの内部（ミクロ）にも現れる**。

```
【全体構成（マクロ）】
Boot            : cpa-bootstrap
Interface       : cpa-request / cpa-response
ApplicationBase : cpa-fractal-app
ProjectedContext: cpa-semantic-world / cpa-ontological-world
CoreModel       : cpa-multiverse

【cpa-semantic-world の内部（ミクロ）】
Boot            : ← cpa-bootstrap が起動を担う
Interface       : ← GlobalContext の TQueue（外部との接点）
ApplicationBase : cpa-semantic-world の AppState 管理
ProjectedContext: cpa-semantic-world の処理パイプライン
CoreModel       : cpa-multiverse の Avatar / Message
```

全体の ProjectedContext 層に位置する `cpa-semantic-world` の内部を見ると、そこにも CoreModel → ProjectedContext → ApplicationBase の構造が現れる。全体の Projected Context が、自身の内部でも CPA の層構成に従って動作する。これが「同じ構造が異なるスケールで自律して繰り返す」フラクタル性である。

フラクタル性の型レベル証拠は次の型シグネチャにも現れる：

```haskell
-- cpa-semantic-world の ProjectedContext
-- 全体構造の ProjectedContext 層が、内部で再び ProjectedContext スタックを持つ
type SemanticWorldContext a =
  ReaderT GlobalConfig (StateT ContextualState (ConduitT Message Void IO)) a
```

---

### B.5.3　7パッケージ構成とレイヤ配置

`cpa-fractal` は7つの Haskell パッケージで構成される。各パッケージの CPA レイヤ上の位置を以下に示す。

```
【Boot Layer】
  Boot/cpa-bootstrap          ← 起動・設定・スレッド管理

【Interface Layer】
  Interface/cpa-request       ← stdin → RequestQueue（入力側）
  Interface/cpa-response      ← ResponseQueue → stdout（出力側）

【Application Base Layer】
  ApplicationBase/cpa-fractal-app   ← 転生プロトコル・4状態 GADTs

【Projected Context Layer】
  ProjectedContext/cpa-semantic-world    ← 意味論ワールド
  ProjectedContext/cpa-ontological-world ← 存在論ワールド

【Core Model Layer】
  CoreModel/cpa-multiverse    ← Avatar / Message / Response / GlobalContext
```

各パッケージの依存方向は一方向（下から上へ）であり、循環参照は発生しない。

```
cpa-bootstrap
    ↓ depends on
cpa-request, cpa-response, cpa-fractal-app
    ↓ depends on
cpa-semantic-world, cpa-ontological-world
    ↓ depends on
cpa-multiverse
    ↓ no dependencies (Pure)
```

#### パッケージ分割とフラクタル構造の必然性

大規模なソフトウェア開発において、システムはパッケージ（またはモジュール）単位に分割される。この分割には実務上の理由がある。各パッケージは最小限の公開インターフェースのみを外部に露出させ、内部実装を隠蔽する。これにより、あるパッケージの内部変更が他のパッケージに波及しない「変更の局所化」が実現される。また、パッケージ境界は開発チームや責務の境界とも対応し、複数のチームが独立して開発・リリースできる単位となる。

CPA においてこの分割は「フラクタル構造の必然的な出現」として解釈できる。各パッケージが自律した単位として機能するためには、それ自身が CoreModel から Boot までの層構成を内包している必要がある。パッケージが増えるほど、CPA の層構成が複数のスケールで繰り返し現れる。これはフラクタル構造が「設計上の工夫」ではなく、**大規模開発において構造が自然に取る形**であることを示している。

---

### B.5.4　Core Model：GlobalContext と TQueue 通信路

**パッケージ：** `CoreModel/cpa-multiverse`

`cpa-multiverse` はシステム全体の「共通言語」を定義する。最も重要なのは `GlobalContext` であり、4本の TQueue によってスレッド間通信路を一元的に保持する。

```haskell
-- cpa-multiverse の GlobalContext
-- 4本の TQueue がシステム全体のメッセージングバックボーンを形成する
data GlobalContext = GlobalContext
  { _requestQueueGlobalContext     :: TQueue Request    -- stdin → fractal-app
  , _semanticQueueGlobalContext    :: TQueue Message    -- fractal-app → semantic-world
  , _ontologicalQueueGlobalContext :: TQueue Message    -- fractal-app → ontological-world
  , _responseQueueGlobalContext    :: TQueue Response   -- any → stdout
  }
```

```haskell
-- Avatar：意味論（世界パラメータなし）と存在論（世界パラメータあり）の2ワールド共通の実体
data Avatar = Avatar
  { _nameAvatar  :: String
  , _levelAvatar :: Int
  , _hpAvatar    :: Int
  , _mpAvatar    :: Int
  }

-- Message：fractal-app が各ワールドへ送るコマンドの代数的データ型
-- 転生プロトコルの実体はこの型で表現される
data Message
  = MsgAttacked Int        -- damage を与える
  | MsgHeal                -- 回復させる
  | MsgSetAvatar Avatar    -- Avatar を注入する
  | MsgMagicalCalamity     -- 転生トリガー（fractal-app → 現在の world）
  | MsgQuit                -- スレッド終了指示

-- Request：stdin から解析した入力コマンド
data Request
  = ReqAttacked Int
  | ReqHeal
  | ReqCalamity
  | ReqQuit
  | ReqUnknown String

-- Response：stdout に出力する応答
data Response
  = ResAvatar Avatar       -- Avatar 状態の表示
  | ResMessage String      -- テキストメッセージ
  | ResQuit                -- 終了シグナル
```

`Message` 型は**コマンドパターン**として設計されており、各ワールドへの指示をデータとして表現する。`MsgSetAvatar`（Avatar 注入）と `MsgMagicalCalamity`（転生トリガー）が転生プロトコルの核心である。

---

### B.5.5　Projected Context：処理パイプラインのワールドエンジン

**パッケージ：** `ProjectedContext/cpa-semantic-world`・`ProjectedContext/cpa-ontological-world`

各ワールドは TQueue をソースとして、メッセージを受け取るたびにアクションを実行するパイプラインとして動作する。

```haskell
-- cpa-semantic-world の ApplicationBase.Control
run :: GlobalContext -> IO ()
run ctx = runSemanticWorldContext ctx $ do
  void $ actionSW (WorldStateW StartState) (EventW EntryEvent)
  transit StartToRun
  runConduit (src .| work .| sink)   -- ← パイプライン駆動
  transit RunToStop
  void $ actionSW (WorldStateW StopState) (EventW ExitEvent)

-- src：semanticQueue から Message を取り出して yield する
src :: ConduitT () Message SemanticWorldContext ()
src = do
  ctx  <- lift $ lift $ lift ask
  msg  <- liftIO $ atomically $ readTQueue (_semanticQueueGlobalContext ctx)
  case msg of
    MsgQuit -> return ()    -- パイプライン終了
    _       -> yield msg >> src

-- work：Message を EventW に変換
work :: ConduitT Message EventW SemanticWorldContext ()
work = awaitForever $ \msg -> yield (EventW (InputEvent (InputEventData msg)))

-- sink：EventW をステートパターンに送り、アクション結果を処理
sink :: ConduitT EventW Void SemanticWorldContext ()
sink = await >>= \case
  Nothing -> return ()
  Just ev -> do
    stopped <- lift (go ev)
    if stopped then return () else sink
```

`src .| work .| sink` のパイプラインが、TQueue から流れ込む `Message` をステートパターンに接続する。`MsgQuit` でパイプラインが閉じられ、ワールドのスレッドが正常終了する。

#### 存在論ワールドとの構造的同一性

`cpa-ontological-world` の制御構造は `cpa-semantic-world` と完全に同一の `src .| work .| sink` パターンを持つ。差異は Projected Context の型（存在論は `World m` 制約を持つ）と Avatar アクションの実装のみである。

---

### B.5.6　Application Base：転生プロトコルと4状態 GADTs

**パッケージ：** `ApplicationBase/cpa-fractal-app`

`cpa-fractal-app` はシステム全体のオーケストレーターである。意味論ワールドと存在論ワールドのどちらに Avatar が「いるか」を4状態 GADTs で管理し、`MsgMagicalCalamity` を受け取ったワールドが転生を自律的に実行する。

#### 4状態 GADTs による存在様式の型表現

```haskell
-- fractal-app の AppState GADT
-- 4状態：Start / Semantic（Avatar は意味論世界） / Ontological（Avatar は存在論世界） / Stop
data AppState s where
  StartState       :: AppState StartStateData
  SemanticState    :: AppState SemanticStateData     -- Avatar が意味論ワールドに存在
  OntologicalState :: AppState OntologicalStateData  -- Avatar が存在論ワールドに存在
  StopState        :: AppState StopStateData
```

スタンドアロン版（`cpa-application-state`）の3状態（Start/Run/Stop）が、`cpa-fractal-app` では「どの世界に Avatar が存在するか」を表現する4状態（Start/Semantic/Ontological/Stop）に発展している。

#### 転生プロトコル：MsgMagicalCalamity の伝播

転生プロトコルは以下の手順で実行される。

```
1. ユーザが "calamity" を入力
2. Interface 層が ReqCalamity として requestQueue に enqueue
3. cpa-fractal-app が ReqCalamity を受け取る
4. fractal-app は現在の AppState を確認し、現在のワールドの TQueue に MsgMagicalCalamity を送信
5. 受け取ったワールド（例：semantic-world）の Run 状態の doActivity が処理：
   a. 自身の Avatar を取り出す（消去）
   b. 相手ワールド（ontological-world）の TQueue に MsgSetAvatar（Avatar）を送信（注入）
   c. fractal-app の requestQueue に ReqCalamity を返送（AppState 遷移を促す）
6. cpa-fractal-app が AppState を SemanticState → OntologicalState に遷移
```

この設計の核心は「消去と注入の責務が fractal-app ではなくワールド自身にある」点である。fractal-app はあくまで `MsgMagicalCalamity` という転生トリガーを現在のワールドに送るだけであり、Avatar の取り出しと注入はそのワールドの doActivity が担う。

```haskell
-- semantic-world の Run 状態：MsgMagicalCalamity ハンドラ（イメージ）
-- Avatar を取り出し → 相手ワールドへ注入 → fractal-app へ転生完了を通知
handleMagicalCalamity :: SemanticWorldContext ()
handleMagicalCalamity = do
  ctx    <- ask
  avatar <- gets currentAvatar
  -- 1. 存在論ワールドへ Avatar を注入
  liftIO $ atomically $
    writeTQueue (_ontologicalQueueGlobalContext ctx) (MsgSetAvatar avatar)
  -- 2. fractal-app へ転生完了を通知（AppState 遷移のトリガー）
  liftIO $ atomically $
    writeTQueue (_requestQueueGlobalContext ctx) (MsgCalamityDone)
```

---

### B.5.7　Interface Layer：パイプラインの外部接点

**パッケージ：** `Interface/cpa-request`・`Interface/cpa-response`

Interface 層は外部世界（stdin/stdout）と内部の TQueue を結ぶ接点である。`cpa-request` も `cpa-response` も、内部は `src .| work .| sink` の同一パターンで構成されている。

#### cpa-request：stdin → requestQueue

```haskell
run :: IO (Maybe T.Text) -> GlobalContext -> IO ()
run readLine ctx = runWorldStateContext ctx $ do
  void $ actionSW (WorldStateW StartState) (EventW EntryEvent)
  transit StartToRun
  runConduit (src readLine .| work .| sink)
  transit RunToStop
  void $ actionSW (WorldStateW StopState) (EventW ExitEvent)

-- src：stdin から1行ずつ読み込んで yield
src :: IO (Maybe T.Text) -> ConduitT () T.Text WorldStateContext ()
src readLine = do
  mLine <- liftIO readLine
  case mLine of
    Nothing   -> return ()
    Just line -> yield line >> src readLine

-- work：テキスト行を InputEvent（EventW）に変換
work :: ConduitT T.Text EventW WorldStateContext ()
work = awaitForever $ \line ->
  yield (EventW (InputEvent (InputEventData line)))
```

#### cpa-response：responseQueue → stdout

```haskell
run :: (T.Text -> IO ()) -> GlobalContext -> IO ()
run writeFn ctx = runWorldStateContext ctx $ do
  ...
  runConduit (src .| work writeFn .| sink)

-- src：responseQueue から Response を読み込んで yield
-- ResQuit を受け取ったらパイプラインを閉じる
src :: ConduitT () Response WorldStateContext ()
src = do
  ctx  <- lift $ lift $ lift ask
  resp <- liftIO $ atomically $ readTQueue (_responseQueueGlobalContext ctx)
  case resp of
    ResQuit -> return ()
    _       -> yield resp >> src
```

---

### B.5.8　Boot Layer：GlobalContext 生成とスレッド起動

**パッケージ：** `Boot/cpa-bootstrap`

Bootstrap はシステム全体の点火装置である。YAML 設定の読み込み・GlobalContext の生成・全スレッドの並列起動という3つの責務を持つ。

```haskell
-- cpa-bootstrap のエントリポイント
-- apps は Main から注入される (GlobalContext -> IO ()) のリスト
-- Control はリストの中身（どのパッケージを起動するか）を知らない
run :: ArgData -> [GlobalContext -> IO ()] -> IO ()
run args apps = do
  conf             <- loadConf args           -- YAML or def
  resolvedLogDir   <- resolveLogDir (_logDirConfigData conf)
  ctx              <- makeGlobalContext (_logLevelConfigData conf) resolvedLogDir
  runAll ctx apps

-- GlobalContext 生成：4本の TQueue を生成してパッケージに注入
makeGlobalContext :: LogLevel -> FilePath -> IO GlobalContext
makeGlobalContext logLevel logDir = do
  reqQ  <- newTQueueIO   -- stdin → fractal-app
  semQ  <- newTQueueIO   -- fractal-app → semantic-world
  ontQ  <- newTQueueIO   -- fractal-app → ontological-world
  resQ  <- newTQueueIO   -- any → stdout
  return GlobalContext { ... }

-- スレッド並列起動：いずれか1つが終了したら全スレッドをキャンセル
runAll :: GlobalContext -> [GlobalContext -> IO ()] -> IO ()
runAll ctx apps = do
  asyncs <- mapM (\f -> async (f ctx)) apps
  (_, result) <- waitAnyCatchCancel asyncs
  ...
```

Bootstrap は `apps` リストを通じて起動すべきアプリを受け取るが、各アプリの内部実装を知らない。Bootstrap が知っているのは `GlobalContext` と `IO ()` だけである。これは CPA の遡行的依存則（Boot 層は上位層を知らない）の型レベル実証である。

論文第8章8.6節「遡行依存則の型レベル証明」では `runReaderT` / `runState` による `run` の非対称性が示されているが、本 `run :: ArgData -> [GlobalContext -> IO ()] -> IO ()` の型シグネチャはその具体的実装例である。Bootstrap が受け取る `[GlobalContext -> IO ()]` という型は「Bootstrap は各アプリが何をするかを知らない（Interface を参照しない）」という遡行的依存則を型レベルで強制していることの証拠として機能する。

---

### B.5.9　スレッド構成と TQueue メッセージングの全体像

本システムは5つのスレッドが並列稼働する。

```
┌────────────────────────────────────────────────────────────────┐
│  cpa-bootstrap（メインスレッド）                                 │
│  GlobalContext（4本のTQueue）を生成し、5スレッドを withAsync      │
│  で並列起動。waitAnyCatchCancel で全スレッド監視。                │
└────────────────┬───────────────────────────────────────────────┘
                 │ async × 5
    ┌────────────┼───────────────────────────────────┐
    │            │                                   │
┌───▼───┐  ┌─────▼──────┐  ┌──────────────┐  ┌───────▼──────┐  ┌──────────────┐
│request│  │fractal-app │  │semantic-world│  │ontological   │  │response      │
│thread │  │thread      │  │thread        │  │world thread  │  │thread        │
└───┬───┘  └─────┬──────┘  └──────┬───────┘  └──────┬───────┘  └───────┬──────┘
    │            │                │                 │                  │
    │ requestQ   │  semanticQ     │  ontologicalQ   │  responseQ       │
    └────────────┼────────────────┼─────────────────┼──────────────────┘
                 │                │                 │
              TQueue            TQueue            TQueue
            (Request)          (Message)          (Message)
```

TQueue の流れ：

```
stdin
  ↓ (readLine)
cpa-request.src
  ↓ pipeline
requestQueue ← Request（enqueue）
  ↓ (dequeue)
cpa-fractal-app（解析・ルーティング）
  ↓ MsgAttacked / MsgHeal / MsgMagicalCalamity / MsgQuit
semanticQueue or ontologicalQueue ← Message（enqueue）
  ↓ (dequeue)
cpa-*-world.src
  ↓ pipeline（アクション実行）
responseQueue ← Response（enqueue）
  ↓ (dequeue)
cpa-response.src
  ↓ pipeline
stdout
```

---

### B.5.10　フラクタル性の本質と設計の一貫性

#### フラクタル性の本質：レイヤ構成の自己相似的再帰

`cpa-fractal` におけるフラクタル性の本質は、**CPA の5層構成（CoreModel → ProjectedContext → ApplicationBase → Interface → Boot）が、システム全体（マクロ）と各ワールドパッケージの内部（ミクロ）の双方で自律した構造として現れる**点にある。

システム全体を見ると Boot = `cpa-bootstrap`、Interface = `cpa-request`/`cpa-response`、ApplicationBase = `cpa-fractal-app`、ProjectedContext = `cpa-semantic-world`/`cpa-ontological-world`、CoreModel = `cpa-multiverse` という5層構成である。一方、ProjectedContext 層に位置する `cpa-semantic-world` の内部を見ると、そこにも Boot（起動を担う bootstrap）・Interface（TQueue による接点）・ApplicationBase（AppState 管理）・ProjectedContext（処理パイプライン）・CoreModel（Avatar/Message）という同じ構造が現れる。

この「部分が全体と同じ構造を持つ」という性質がフラクタルである。パッケージの数が増えるほど、あるいはシステムの規模が大きくなるほど、この5層構造はより多くのスケールで繰り返し現れることになる。

#### フラクタル構造がもたらす設計の一貫性

フラクタル性が成立していることの結果として、`cpa-fractal` 全体に次のような設計の一貫性が現れる。これらはフラクタルの定義そのものではないが、フラクタル構造から自然に導かれる性質である。

**パイプラインパターンの共通化**

`src .| work .| sink` というパイプラインパターンが、入力・出力・各ワールドの全パッケージにわたって共通して使われる。型は異なるが構造は同一である。これは各パッケージが同じ「入力を受け取り、変換し、出力する」という役割を持つことの反映であり、フラクタル構造において各スケールの単位が同一の振る舞いを示すことと対応する。

**ステートパターンの共通化**

GADTs と存在量化（`WorldStateW`）によるステートパターンが全パッケージで共通して用いられる。各パッケージが自律した ApplicationBase を持つ結果として、ステート管理の実装が共通の形式をとる。

**遡行的依存則の貫徹**

CPA の遡行的依存則（上位層は下位層を知らない）が、全体構成においても各ワールド内においても成立する。Bootstrap が `[GlobalContext -> IO ()]` しか知らないという型レベルの制約は、フラクタル構造の各スケールでこの依存則が繰り返し強制されることを示している。

---

### B.5.11　`cpa-fractal` の動作確認

```bash
cd cpa-fractal && cpa-bootstrap.exe -y ./cpa-fractal.yaml

# prompt が現れたらコマンドを入力
>> attacked 10      # HP 100 → 90（意味論ワールドで処理）
>> heal             # HP 90 → 95、MP 50 → 40
>> calamity         # 転生：semantic-world から ontological-world へ Avatar 移動
                    # AppState: SemanticState → OntologicalState
>> attacked 20      # HP 95 → 75（存在論ワールドで処理）
>> calamity         # 帰還：ontological-world から semantic-world へ Avatar 移動
                    # AppState: OntologicalState → SemanticState
>> quit             # 全スレッド終了
```

`calamity` コマンドの実行前後で Avatar の処理が意味論ワールドと存在論ワールドの間を移動する。ユーザから見ると Avatar の連続性（hp・mp の値）は維持されており、「どの世界にいるか」という存在様式の変化が透過的に処理される。これが「1体の Avatar がフラクタル構造の中を渡り歩く」という本アプリケーションの本質的な動作である。

---
