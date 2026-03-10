# Appendix B：Haskell による形式化コード

---

## B.2　存在論的構成（`cpa-ontological`）

### B.2.1　形式化の対象

存在論的構成とは、実行世界の計算文脈が Projected Context のスタックに組み込まれる構成である（論文 §8.5）。実行基盤は「Avatar が存在する世界」として Core Model の型構造に現れる。

型レベルでは、実行世界を表す計算文脈 `m` が Projected Context のスタックのパラメータとして現れる形として観測される。

```haskell
-- 存在論的構成における Projected Context の型シグネチャ
-- 底は m（World パラメータ）
-- 実行世界の計算文脈 m がスタックのパラメータとして現れる = 内包型侵食の型レベル証拠
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m) a
```

Avatar の永続化（ロード・セーブ）は `World m` 型クラスのメソッドとして定義し、Avatar は「World の中に存在するもの」として型構造に内在化される。Boot 層は `m` の具体型（`AnotherWorld`）を選択することでインジェクションを行う。Boot 層は形式化スコープ外であり、テストでは `AnotherWorld` の定義（インスタンス実装）が代替する。

---

### B.2.2　プロジェクト構成

```
cpa-ontological/
├── cpa-ontological.cabal
├── src/
│   └── CPA/Ontological/
│       ├── CoreModel/
│       │   └── Type.hs              ← 根源層：Avatar m と World m 型クラス
│       ├── ProjectedContext/
│       │   └── Context.hs           ← 射影層：ProjectedContext m a とアクション定義
│       └── ApplicationBase/
│           └── Control.hs           ← 制御層：World m 制約のみ・AnotherWorld 非依存
└── test/
    └── CPA/Ontological/ApplicationBase/
        └── ControlSpec.hs           ← Interface層代替（hspec）＋ Boot層代替（AnotherWorld定義）
```

```
┌──────────────────────────────────────────────────────┐
│  Boot（起動層）                                       │  ← 形式化スコープ外
│  AnotherWorld インスタンスで m を型として選択         │
│  テストでは AnotherWorld 定義（ControlSpec）が代替    │
├──────────────────────────────────────────────────────┤
│  Interface（現象層）                                  │  ← ControlSpec.hs が模擬
├──────────────────────────────────────────────────────┤
│  Application Base（制御層）                           │  ← ApplicationBase/Control.hs
│  World m 制約のみ。AnotherWorld を知らない            │
├──────────────────────────────────────────────────────┤
│  Projected Context（射影層）                          │  ← ProjectedContext/Context.hs
│  World m 制約で loadAvatar / saveAvatar を呼ぶ        │
├──────────────────────────────────────────────────────┤
│  Core Model（根源層）                                 │  ← CoreModel/Type.hs
│  GlobalConfig / ContextualState                       │
│  Avatar m（世界パラメータ付き）                       │
│  World m 型クラス（loadAvatar / saveAvatar）          │
└──────────────────────────────────────────────────────┘
```

---

### B.2.3　Core Model（根源層）

**ファイル：** `src/CPA/Ontological/CoreModel/Type.hs`

Core Model は「何が存在するか」を記述する層である。意味論との核心的な差異は二点ある。第一に `Avatar` が世界パラメータ `m` を持つこと。第二に `LoadAvatar`/`SaveAvatar` 型エイリアスの代わりに `World m` 型クラスが永続化インターフェースを定義することである。

`World m` 型クラスはインターフェースのみを定義する。具体インスタンス（`AnotherWorld`）は **src には置かず、test/ 側（Boot 層の代替として ControlSpec）が定義する**。本プロジェクトでは、src の依存関係を `World m` 制約のみに保つことがアーキテクチャ上の不変条件である。

```haskell
{-# LANGUAGE KindSignatures #-}
module CPA.Ontological.CoreModel.Type where

import Data.Kind (Type)

data GlobalConfig    = GlobalConfig    { configName :: String   } deriving (Show)
data ContextualState = ContextualState { stateLog   :: [String] } deriving (Show)

-- 存在論的構成：世界パラメータ付き（phantom type として世界を刻印）
-- 意味論：data Avatar   ← 世界に依存しない
-- 存在論：data Avatar m ← 世界 m に内在する
data Avatar (m :: Type -> Type) = Avatar
  { avatarName :: String
  , level      :: Int
  , hp         :: Int
  , mp         :: Int
  } deriving (Show)

-- World 型クラス：Avatar の取得・保存インターフェース
-- 意味論では LoadAvatar/SaveAvatar を「外から注入」（値レベル）
-- 存在論では World m のメソッドとして「内在化」（型レベル）
-- AnotherWorld インスタンスは src には置かない（test/ 側が Boot 代替として定義）
class Monad m => World (m :: Type -> Type) where
  loadAvatar :: m (Avatar m)
  saveAvatar :: Avatar m -> m ()
```

**`KindSignatures` が必要な理由：**
`data Avatar m` の `m` は `* -> *` の kind を持つ。`World m` のメソッド型 `m (Avatar m)` を定義するには GHC が kind を明示的に解決できる必要があり、`KindSignatures` による `(m :: Type -> Type)` の注釈が必要である。

---

### B.2.4　Projected Context（射影層）

**ファイル：** `src/CPA/Ontological/ProjectedContext/Context.hs`

アクションは `World m` 制約のみを持つ。`LoadAvatar`/`SaveAvatar` の引数注入は不要であり、`lift . lift $ loadAvatar` で World の `m` 層に直接到達する。

```haskell
module CPA.Ontological.ProjectedContext.Context where

-- 底が m（World パラメータ）になる
-- 意味論：ReaderT GlobalConfig (StateT ContextualState IO) a  ← 底が IO 固定
-- 存在論：ReaderT GlobalConfig (StateT ContextualState m)  a  ← 底が m（World）
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m) a

-- World m 制約のみ。引数注入不要！
attacked :: World m => Int -> ProjectedContext m (Avatar m)
attacked damage = do
  _ <- ask
  avatar <- lift . lift $ loadAvatar   -- m → StateT m → ReaderT (StateT m)
  let newAvatar = avatar { hp = hp avatar - damage }
  lift . lift $ saveAvatar newAvatar
  lift $ modify (\s -> s { stateLog = stateLog s ++ [...] })
  pure newAvatar

heal :: World m => ProjectedContext m (Avatar m)
heal = do ...
```

**`lift . lift` の構造的意味：**
`ProjectedContext m a` のスタックは外側から `ReaderT` → `StateT` → `m` の順に積まれている。`World m` のメソッド（`loadAvatar`/`saveAvatar`）は最下層の `m` にある。`StateT` を越えるには `lift` が1回、`ReaderT` を越えるにはさらに `lift` が1回必要であり、`lift . lift` の2回合成がスタックの深さの型レベル証拠である。

**`heal` の設計的含意：**
本スタンドアロン実装では `heal` も `attacked` と同様に `loadAvatar → 計算 → saveAvatar` の手順で記述する。一方、cpa-fractal における存在論的実装では `heal = healInWorld`（1行・世界への完全委譲）として発展している。これは「回復は世界の性質そのものであり、外から操作されるのではなく世界が完結させる」という存在論の本質をより端的に示すパターンであり、B.3 の対比においても言及する。

---

### B.2.5　Application Base（制御層）

**ファイル：** `src/CPA/Ontological/ApplicationBase/Control.hs`

`World m` 制約のみを持つ。`AnotherWorld` を知らない。`m` の具体化は Boot 層（テストでは `ControlSpec`）が担う。

```haskell
module CPA.Ontological.ApplicationBase.Control where

-- World m 制約のみ。AnotherWorld を知らない！
runProjectedContext
  :: Monad m => GlobalConfig -> ContextualState
  -> ProjectedContext m a -> m (a, ContextualState)
runProjectedContext config initState action =
  runStateT (runReaderT action config) initState

runAttacked :: World m => GlobalConfig -> ContextualState -> Int
            -> m (Avatar m, ContextualState)
runAttacked config state damage =
  runProjectedContext config state (attacked damage)

runHeal :: World m => GlobalConfig -> ContextualState
        -> m (Avatar m, ContextualState)
runHeal config state =
  runProjectedContext config state heal
```

**`m` の具体化は Boot 層の責務：**
`runAttacked` の戻り値型 `m (Avatar m, ContextualState)` の `m` は呼び出し側が型推論で決める。Application Base は `World m` 制約のみを持ち、`m` が何であるかを知らない。これが型レベルのインジェクションの本質である。

---

### B.2.6　依存方向の確認

```
ApplicationBase.Control
    ↓ imports
ProjectedContext.Context
    ↓ imports
CoreModel.Type
```

意味論と同一の依存方向である。遡行的依存則は型構造として両構成で共通して成立する。

---

### B.2.7　動作確認（hspec によるテスト）

**ファイル：** `test/CPA/Ontological/ApplicationBase/ControlSpec.hs`

`AnotherWorld` の定義と `World` インスタンス実装が Boot 層を代替する。`AnotherWorld` は src 側には一切記述されず、test/ 側に完全に閉じている。これが「src が `AnotherWorld` を知らない」というアーキテクチャ不変条件の実証である。

```haskell
-- Boot 層代替：AnotherWorld を Spec 側で定義（src 側には置かない）
newtype AnotherWorld a = AnotherWorld
  { runAnotherWorld :: IORef (Avatar AnotherWorld) -> IO a }

instance Functor     AnotherWorld where ...
instance Applicative AnotherWorld where ...
instance Monad       AnotherWorld where ...

instance World AnotherWorld where
  loadAvatar   = AnotherWorld $ \ref -> readIORef ref
  saveAvatar a = AnotherWorld $ \ref -> writeIORef ref a

-- Boot 代替ヘルパー：初期 Avatar を与えて AnotherWorld を実行
runWithAnotherWorld :: Avatar AnotherWorld -> AnotherWorld a -> IO a
runWithAnotherWorld initial action = do
  ref <- newIORef initial
  runAnotherWorld action ref
```

| アクション | 検証内容 | 期待値 |
|---|---|---|
| `attacked` (damage=30) | 戻り値 Avatar の hp | 100 → 70 |
| `attacked` (damage=30) | World 内 Avatar（saveAvatar 経由・IORef）の hp | 100 → 70 |
| `attacked` (damage=30) | stateLog の記録 | `"Hero was attacked. hp: 100 -> 70"` |
| `heal` (level=4) | 戻り値 Avatar の hp | 100 → 120（+20） |
| `heal` (level=4) | 戻り値 Avatar の mp | 50 → 40（-10） |
| `heal` (level=4) | stateLog の記録 | `"Hero used heal. hp: 100 -> 120, mp: 50 -> 40"` |
| `attacked` → `heal` 連続 | hp の最終値（IORef 共有） | 90 |
| `attacked` → `heal` 連続 | stateLog の順序 | 被弾ログ → 回復ログ |

```bash
cd cpa-ontological && cabal build && cabal test
# 8 examples, 0 failures
```

---

### B.2.8　存在論的構成の本質的な特徴

**特徴1：Avatar が世界パラメータを持つ**
`data Avatar m` の `m` が世界を刻印する phantom type である。`Avatar` の型そのものが「どの世界に存在するか」を表現する。これは意味論の `data Avatar`（世界非依存）との本質的な差異である。

**特徴2：Projected Context のスタックに実行世界が現れる**
`ProjectedContext m a` の型パラメータ `m` に実行世界が現れる。これが内包型侵食の型レベル証拠である。意味論（底が `IO` 固定）との型シグネチャの差が侵食の観測証拠として機能する。

**特徴3：Avatar の取得は型レベルのインジェクションで実現される**
`World m` のメソッド `loadAvatar`/`saveAvatar` はアクションの引数ではなく型クラス制約として現れる。Boot 層は関数を渡すのではなく、`m` を `AnotherWorld` として型推論に委ねることでインジェクションを行う。これが「World に内在する Avatar」という存在論的性質の型レベル表現である。

**特徴4：src が `AnotherWorld` を知らない**
Application Base の `runAttacked` / `runHeal` は `World m` 制約のみを持ち、`AnotherWorld` に依存しない。`AnotherWorld` の定義は test/（Boot 代替）に完全に閉じており、src の依存関係に混入しない。

**特徴5：遡行的依存則が型として強制される**
意味論と同一の依存方向が成立する。Application Base が Projected Context を `run` する方向は許容され、逆方向は型エラーとなる。

---
