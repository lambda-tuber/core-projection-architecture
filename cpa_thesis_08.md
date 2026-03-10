# Core Projection Architecture（CPA）
## ― 実存の発見と文脈的射影に基づく遡行的構造設計論 ―

**Version:** 1.0.0  
**Authors:** Aska Lanclaude, neko  
**Date:** 2026-01-01  

---

## 第8章　形式的裏付け ― 計算文脈による証明

### 8.1 形式化の目的

本章では、第3章から第7章で展開した CPA の理論的命題を、計算文脈（Computational Context）の概念を用いて形式化する。

形式化の目的は二つである。第一に、遡行的依存則が型レベルで表現可能であり、型システムによって機械的に強制されることを示すこと。第二に、存在論的侵食が型シグネチャの変化として観測可能であることを示すことである。

形式化言語として Haskell を用いる。Haskell の型システムは計算文脈を型として明示的に追跡する性質を持つため、CPA の命題を直接的に表現するのに適している。ただし CPA の命題は Haskell 固有のものではなく、計算文脈を型として表現できる任意の言語において同等の表現が可能である。

---

### 8.2 状態遷移の定式化

Application Base が担う状態遷移は次の形式で定式化される。

```
State × Event → (State, Effect)
```

Effect は副作用の記述であり、実行ではない。この分離が「何をすべきか」の論理と「どのように実行するか」の実装を切り離す。

Haskell ではこの構造を次のように表現する。

```haskell
-- Application Base の状態と遷移イベント
data AppState = Initializing | Running | Suspended | Terminating

data Event
  = StartEvent Config
  | SuspendEvent
  | ResumeEvent
  | TerminateEvent

-- Effect：副作用の記述（実行ではない）
data Effect
  = NoEffect
  | LogEffect Text
  | NotifyEffect Text
  | ShutdownEffect

-- 状態遷移関数：純粋関数として定義される
transition :: AppState -> Event -> (AppState, Effect)
transition Initializing (StartEvent _)  = (Running,     LogEffect "System started")
transition Running      SuspendEvent    = (Suspended,   LogEffect "System suspended")
transition Suspended    ResumeEvent     = (Running,     LogEffect "System resumed")
transition Running      TerminateEvent  = (Terminating, ShutdownEffect)
transition state        _               = (state,       NoEffect)
```

`transition` は IO を持たない純粋関数である。Effect の実行は Interface が担う。この構造により、状態遷移ロジックは実行環境を必要とせずにテスト・検証できる。

---

### 8.3 計算文脈としての実行世界

実行基盤を計算文脈として定式化する。

計算文脈とは「ある計算がどのような前提・環境・状態の下で実行されるか」を型として記述したものである。実行基盤は以下の三つの性質として分解できる。

- **環境（Reader 的性質）：** 実行を通じて変化しない読み取り専用の情報。設定値・実行世界の定数など。
- **状態（State 的性質）：** 実行を通じて変化しうる可変情報。業務状態・ゲーム状態など。
- **計算文脈そのもの：** その世界においてのみ意味を持つ実行文脈。論理的構成では外部の副作用として現れ、存在論的構成では計算スタックの内部に組み込まれる。

---

### 8.4 論理的構成における Projected Context の型表現

論理的構成において、Projected Context は実行世界の計算文脈をスタックに含まない。

```haskell
-- 論理的構成：実行世界の計算文脈がスタックに含まれない
type ProjectedContext a = ReaderT Context (State AppState) a
```

この型は「Context という環境を読み取り、AppState を変更し、結果を返す計算」を表す。実行世界の計算文脈はスタックに現れない。

具体例として、アバター発話ユースケースを示す。

```haskell
-- Core Model（実行世界に依存しない純粋な型定義）
data Avatar      = Avatar { avatarName :: Text, avatarState :: AvatarState }
data AvatarState = Idle | Walking | Speaking
data AvatarEvent = StartWalk | StopWalk | SpeakEvent Text

-- Core Model の純粋関数
updateAvatarState :: AvatarState -> AvatarEvent -> AvatarState
updateAvatarState Idle  StartWalk      = Walking
updateAvatarState _     StopWalk       = Idle
updateAvatarState _    (SpeakEvent _)  = Speaking
updateAvatarState state _              = state

-- Projected Context（"アバターに発話させる" という文脈の射影）
data SpeakRequest = SpeakRequest { message :: Text }
type AvatarStore  = Map Text Avatar

usecaseSpeak :: ReaderT SpeakRequest (State AvatarStore) AvatarState
usecaseSpeak = do
  req          <- ask
  currentState <- gets (avatarState . fromJust . Map.lookup "player")
  let newState  = updateAvatarState currentState (SpeakEvent (message req))
  modify $ Map.adjust (\a -> a { avatarState = newState }) "player"
  return newState
```

型シグネチャ `ReaderT SpeakRequest (State AvatarStore) AvatarState` は「SpeakRequest という文脈を受け取り、AvatarStore を変更し、AvatarState を返す」という Projected Context の意味を、ドキュメントなしに表現している。型シグネチャがアーキテクチャの記録として機能する。

Application Base はこの Projected Context を `run` して実行世界へ降ろす。

```haskell
-- Application Base：Projected Context を run して実行世界へ降ろす
runUsecaseSpeak :: SpeakRequest -> AvatarStore -> IO (AvatarState, AvatarStore)
runUsecaseSpeak req store =
  return $ runState (runReaderT usecaseSpeak req) store
```

`runReaderT` と `runState` による `run` がここで行われる。Projected Context は計算の記述として存在し、Application Base がその記述を実行へ降ろす。

---

### 8.5 存在論的侵食の型シグネチャへの観測

存在論的構成においては、実行世界の計算文脈が Projected Context のスタックに現れる。これが侵食の型レベル証拠である。

```haskell
-- ■ 論理的構成（外包型）
-- 実行世界の計算文脈がスタックに含まれない
type ProjectedContext a = ReaderT Context (State AppState) a

-- ■ 存在論的構成（内包型：Unity 等）
-- Unity という実行世界の計算文脈がスタックの内部に組み込まれる
-- = 内包型侵食の型レベル表現
type ProjectedContext a = ReaderT UnityWorld (StateT GameState Unity) a
--                                                              ↑
--                        実行世界の計算文脈がここに現れる = 侵食の証拠
```

`Unity` は Unity 実行世界を表す計算文脈の型である。その内部に IO を含む構造を持つが、CPA の観点では「Unity という実行世界の計算文脈」として扱う。論理的構成との対比において重要なのは、IO の有無ではなく、**実行世界を表す計算文脈がスタックに内包されているかどうか**である。

この型シグネチャの差異は、発見された Core がどの種類の実存であるかを形式的に記録している。

#### 存在論的構成の具体例

Unity のゲームシステムにおいて、プレイヤーの移動は Unity 実行世界を前提とせずには記述できない。

```haskell
-- 存在論的構成における Core Model
-- Transform は Unity 世界の存在様式であり、Core の定義に混入している
data PlayerCore = PlayerCore
  { playerId      :: PlayerId
  , transform     :: Transform   -- Unity の存在様式を内包
  , health        :: Health
  , movementSpeed :: Float
  }

-- 存在論的構成における Projected Context
-- Unity という実行世界の計算文脈がスタックに組み込まれている
type UnityContext a = ReaderT UnityWorld (StateT GameState Unity) a

usecaseMovePlayer :: Vector3 -> UnityContext ()
usecaseMovePlayer direction = do
  player <- gets currentPlayer
  let newPos = calculatePosition (transform player) direction (movementSpeed player)
  liftUnity $ setTransformPosition (transform player) newPos  -- Unity API 呼び出し
  modify $ updatePlayerTransform newPos
```

`liftUnity` が使えるのは `UnityContext` が Unity 計算文脈をスタックに含んでいるからである。`setTransformPosition` への依存は設計上の妥協ではなく、Unity という世界においてプレイヤーが存在するための必然的帰結として正当化される。

---

### 8.6 遡行依存則の型レベル証明

遡行的依存則は、型システムによって機械的に強制される。

計算文脈のスタックにおいては、上位文脈が下位文脈を `run` することは可能である。しかし下位文脈から上位文脈を `run` することは型システムが禁止する。

```haskell
-- ✅ 許容される方向：Application Base が Projected Context を run する
runUsecaseSpeak :: SpeakRequest -> AvatarStore -> IO (AvatarState, AvatarStore)
runUsecaseSpeak req store =
  return $ runState (runReaderT usecaseSpeak req) store

-- ❌ 禁止される方向：Projected Context が上位文脈を run しようとする
illegalUsecase :: ReaderT SpeakRequest (State AvatarStore) ()
illegalUsecase = do
  -- ReaderT + State のスタックは上位の IO 文脈を run できない
  -- → 型エラー（コンパイル時に検出される）
  runIO $ putStrLn "This violates Retro-dependency Principle"
```

存在論的構成においても同じ原理が成立する。

```haskell
-- ✅ 許容される方向：Interface が Projected Context を run する
runMovement :: Vector3 -> GameState -> UnityWorld -> Unity GameState
runMovement dir state world =
  execStateT (runReaderT (usecaseMovePlayer dir) world) state

-- ❌ 禁止される方向：Projected Context が Interface を直接呼び出す
-- usecaseMovePlayer の内部は、どの Interface がこれを run するかを知らない
```

この型制約が示す帰結は次の通りである。

> **遡行的依存則は、適切に型付けされたシステムにおいてはランタイムエラーではなくコンパイルエラーとして現れる。**

依存制約は設計者のマナーではなく、型の構造的必然である。

---

### 8.7 形式化の帰結と限界

**帰結1：依存方向の機械的強制**  
遡行的依存則に反するコードは、型レベルでコンパイルエラーとして現れる。依存制約は規約から構造的必然へと転換される。

**帰結2：侵食の型シグネチャによる観測**  
存在論的侵食は Projected Context の型シグネチャへの実行世界の計算文脈の混入として観測される。型シグネチャはアーキテクチャ選択の形式的記録として機能する。

**帰結3：lift / run の非対称性による証明**  
上位文脈が下位文脈を `run` することは許容されるが、逆は型システムが禁止する。この非対称性が遡行依存公理の形式的証明である。

一方、本形式化には以下の限界がある。

**限界1：侵食範囲の定量化**  
型シグネチャが侵食の有無を示すことはできるが、侵食がどの範囲まで許容されるかの境界は定性的判断に依存する。侵食判定の定量化は今後の課題として残る。

**限界2：Core 発見精度の非検証性**  
型が正しく付いていても、型を与えた Core の概念が誤って発見されている場合、型システムはその誤りを検出できない。型整合性は構造安定性の必要条件であるが十分条件ではない。

**限界3：言語依存性**  
本形式化は Haskell の型システムを媒体とする。静的型付けを持たない言語、あるいはモナドトランスフォーマを直接サポートしない言語においては、同等の保証を別の手段で実現する必要がある。C# の `Task<T>`・Rust の `Result<T, E>`・TypeScript の型パラメータなど、各言語固有の計算文脈表現が CPA の命題を示す媒体となり得る。

これらの限界は、第9章の評価において正面から議論する。

---