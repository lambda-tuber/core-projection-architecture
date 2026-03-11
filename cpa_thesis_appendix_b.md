# Core Projection Architecture（CPA）
## ― 実存の発見と文脈的射影に基づく遡行的構造設計論 ―

**Version:** 1.0.0  
**Authors:** Aska Lanclaude, neko  
**Date:** 2026-01-01  

---

# Appendix B：Haskell による形式化コード

## 概要

本付録は、Core Projection Architecture（CPA）の理論的命題を Haskell によって形式化した実装コードを収録する。

形式化の目的は二つである。第一に、遡行的依存則が型レベルで表現可能であり、型システムによって機械的に強制されることを示すこと。第二に、意味論的構成と存在論的構成の差異が型シグネチャの変化として観測可能であることを示すことである。

本付録は以下のプロジェクトで構成される。

| プロジェクト | 対象 | 状態 |
|---|---|---|
| `cpa-semantic/` | 意味論的構成（外包型侵食） | ✅ 実装済み |
| `cpa-ontological/` | 存在論的構成（内包型侵食） | ✅ 実装済み |
| `cpa-application-state/` | ApplicationBase 状態管理（AppState ステートパターン） | ✅ 実装済み |
| `cpa-fractal/` | CPAフラクタル構造（7パッケージ統合・異世界転生エンジン） | ✅ 実装済み |

`cpa-semantic`・`cpa-ontological`・`cpa-application-state` は各概念を独立して形式化したスタンドアロンプロジェクトである。`cpa-fractal` はこれら三つの構成を統合・発展させた実証アプリケーションであり、B.5 において別途解説する。

---

## 意味論 vs 存在論：型レベルの対比

本付録の核心は、意味論的構成と存在論的構成の差異が **型シグネチャの変化**として観測できることにある。

```haskell
-- 【意味論】Avatar は世界パラメータを持たない
data Avatar

-- 【存在論】Avatar は世界パラメータを持つ
data Avatar m
```

```haskell
-- 【意味論】ProjectedContext の底は IO 固定
type ProjectedContext a   = ReaderT GlobalConfig (StateT ContextualState IO) a

-- 【存在論】ProjectedContext の底は m（World パラメータ）
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m)  a
```

```haskell
-- 【意味論】Avatar 取得は引数注入（値レベル）
attacked :: LoadAvatar -> SaveAvatar -> Int -> ProjectedContext Avatar

-- 【存在論】Avatar 取得は World m の型クラスメソッド（型レベル）
attacked :: World m => Int -> ProjectedContext m (Avatar m)
```

| 項目 | 意味論（B.1） | 存在論（B.2） |
|---|---|---|
| Avatar 型 | `data Avatar` | `data Avatar m` |
| Avatar の居場所 | 世界の外から運ばれる | World の中に内在する |
| 取得方法 | `LoadAvatar` を引数注入（値レベル） | `World m` のメソッド（型レベル） |
| ProjectedContext 底 | `IO`（固定） | `m`（World パラメータ） |
| Boot 層の役割 | `load`/`save` 関数を生成して渡す | `AnotherWorld` で `m` を型として選択 |
| src の知識 | `LoadAvatar`/`SaveAvatar` 型を知る | `World m` 制約のみ |
| 哲学的意味 | Avatar は「外から参照される存在」 | Avatar は「World に内在する存在」 |

---

## B.1　意味論的構成（`cpa-semantic`）

### B.1.1　形式化の対象

意味論的構成とは、実行基盤が配送装置型として機能し、Core Model が実行世界の存在様式から独立して成立する構成である（論文 §7.3）。

本節（B.1）は論文第8章の形式化コード例に対応する参照実装である。
論文8.4節「論理的構成における Projected Context の型表現」のアバターユースケースコード例は
本節の `attacked` / `heal` アクションの型構造に対応している。
また、本節の `ProjectedContext` 型シグネチャは8.5節「存在論的侵食の型シグネチャへの観測」における
外包型侵食の型レベル証拠として機能する（B.3 の型対比表も参照）。

実行基盤を除去しても Core の概念は成立する。侵食の影響は Interface と Application Base において吸収され、Core Model の定義に混入しない。型レベルでは、実行世界を表す計算文脈が Projected Context のスタックのパラメータとして現れない形として観測される。

```haskell
-- 意味論的構成における Projected Context の型シグネチャ
-- 底は IO（LoadAvatar / SaveAvatar の副作用を吸収）
-- 実行世界の計算文脈がスタックのパラメータとして現れない = 外包型侵食の型レベル証拠
type ProjectedContext a = ReaderT GlobalConfig (StateT ContextualState IO) a
```

本プロジェクトでは、ゲームシステムのアバターを題材として採用する。`attacked`（被弾）と `heal`（魔法回復）という二つのアクションを通じて、CPA の四層構造と遡行的依存則を形式化する。

Avatar の永続化（ロード・セーブ）は `LoadAvatar` / `SaveAvatar` 型として Core Model に定義し、Boot 層がその実装をインジェクトする。Boot 層は形式化スコープ外であり、テストでは `IORef` を用いた stub が代替する。

---

### B.1.2　プロジェクト構成

```
cpa-semantic/
├── cpa-semantic.cabal
├── src/
│   └── CPA/Semantic/
│       ├── CoreModel/
│       │   └── Type.hs              ← 根源層：発見された実存の定式化
│       ├── ProjectedContext/
│       │   └── Context.hs           ← 射影層：文脈的断面とアクション定義
│       └── ApplicationBase/
│           └── Control.hs           ← 制御層：射影を実行文脈に降ろす機構
└── test/
    └── CPA/Semantic/ApplicationBase/
        └── ControlSpec.hs           ← Interface層代替（hspec）＋ Boot層代替（stub定義）
```

```
┌──────────────────────────────────────────────────────┐
│  Boot（起動層）                                       │  ← 形式化スコープ外
│  LoadAvatar / SaveAvatar の実装を生成・インジェクト    │
│  テストでは IORef stub（ControlSpec）が代替する        │
├──────────────────────────────────────────────────────┤
│  Interface（現象層）                                  │  ← ControlSpec.hs が模擬
├──────────────────────────────────────────────────────┤
│  Application Base（制御層）                           │  ← ApplicationBase/Control.hs
├──────────────────────────────────────────────────────┤
│  Projected Context（射影層）                          │  ← ProjectedContext/Context.hs
├──────────────────────────────────────────────────────┤
│  Core Model（根源層）                                 │  ← CoreModel/Type.hs
│  GlobalConfig / ContextualState / Avatar             │
│  LoadAvatar / SaveAvatar 型エイリアス                 │
└──────────────────────────────────────────────────────┘
```

---

### B.1.3　Core Model（根源層）

**ファイル：** `src/CPA/Semantic/CoreModel/Type.hs`

Core Model は「何が存在するか」を記述する層である。型定義のみを保持し、上位層を参照しない。`Avatar` は世界パラメータを持たないシンプルなデータ型として定式化される。

Avatar の永続化インターフェースは `LoadAvatar` / `SaveAvatar` として型エイリアスで定義する。実装（ファイル読み書き等）は Boot 層が担い、形式化スコープ外である。

```haskell
module CPA.Semantic.CoreModel.Type where

data GlobalConfig    = GlobalConfig    { configName :: String   } deriving (Show)
data ContextualState = ContextualState { stateLog   :: [String] } deriving (Show)

-- 意味論的構成：世界パラメータなし
data Avatar = Avatar
  { avatarName :: String
  , level      :: Int
  , hp         :: Int
  , mp         :: Int
  } deriving (Show)

-- Avatar の永続化インターフェース型（Boot 層がインジェクト・形式化スコープ外）
type LoadAvatar = IO Avatar
type SaveAvatar = Avatar -> IO ()
```

---

### B.1.4　Projected Context（射影層）

**ファイル：** `src/CPA/Semantic/ProjectedContext/Context.hs`

`LoadAvatar` / `SaveAvatar` をアクションの引数として受け取り、`liftIO` で IO 操作を射影層の計算文脈に持ち上げる。

```haskell
module CPA.Semantic.ProjectedContext.Context where

-- 底は IO（LoadAvatar / SaveAvatar の IO を吸収）
type ProjectedContext a = ReaderT GlobalConfig (StateT ContextualState IO) a

-- アクション引数として load / save を受け取る（値レベルのインジェクション）
attacked :: LoadAvatar -> SaveAvatar -> Int -> ProjectedContext Avatar
attacked loadAvatar saveAvatar damage = do
  _ <- ask
  avatar <- liftIO loadAvatar
  let newAvatar = avatar { hp = hp avatar - damage }
  liftIO (saveAvatar newAvatar)
  lift $ modify (\s -> s { stateLog = stateLog s ++ [...] })
  pure newAvatar

heal :: LoadAvatar -> SaveAvatar -> ProjectedContext Avatar
heal loadAvatar saveAvatar = do ...
```

---

### B.1.5　Application Base（制御層）

**ファイル：** `src/CPA/Semantic/ApplicationBase/Control.hs`

`LoadAvatar` / `SaveAvatar` を引数として受け取り Projected Context へ渡す。

```haskell
module CPA.Semantic.ApplicationBase.Control where

runProjectedContext
  :: GlobalConfig -> ContextualState -> ProjectedContext a -> IO (a, ContextualState)
runProjectedContext config initState action =
  runStateT (runReaderT action config) initState

runAttacked :: GlobalConfig -> ContextualState -> LoadAvatar -> SaveAvatar -> Int
            -> IO (Avatar, ContextualState)
runAttacked config state loadAvatar saveAvatar damage =
  runProjectedContext config state (attacked loadAvatar saveAvatar damage)

runHeal :: GlobalConfig -> ContextualState -> LoadAvatar -> SaveAvatar
        -> IO (Avatar, ContextualState)
runHeal config state loadAvatar saveAvatar =
  runProjectedContext config state (heal loadAvatar saveAvatar)
```

---

### B.1.6　依存方向の確認

```
ApplicationBase.Control
    ↓ imports
ProjectedContext.Context
    ↓ imports
CoreModel.Type
```

---

### B.1.7　動作確認（hspec によるテスト）

**ファイル：** `test/CPA/Semantic/ApplicationBase/ControlSpec.hs`

`IORef` を用いた stub が Boot 層のインジェクションを代替する。

```haskell
-- Boot 層代替：IORef で LoadAvatar / SaveAvatar を生成
makeStub :: Avatar -> IO (IORef Avatar, LoadAvatar, SaveAvatar)
makeStub initial = do
  ref <- newIORef initial
  pure (ref, readIORef ref, writeIORef ref)
```

| アクション | 検証内容 | 期待値 |
|---|---|---|
| `attacked` (damage=30) | 戻り値 Avatar の hp | 100 → 70 |
| `attacked` (damage=30) | saveAvatar 経由の永続化（IORef） | 100 → 70 |
| `attacked` (damage=30) | stateLog の記録 | `"Hero was attacked. hp: 100 -> 70"` |
| `heal` (level=4) | 戻り値 Avatar の hp | 100 → 120（+20） |
| `heal` (level=4) | 戻り値 Avatar の mp | 50 → 40（-10） |
| `heal` (level=4) | stateLog の記録 | `"Hero used heal. hp: 100 -> 120, mp: 50 -> 40"` |
| `attacked` → `heal` 連続 | hp の最終値（IORef 共有） | 90 |
| `attacked` → `heal` 連続 | stateLog の順序 | 被弾ログ → 回復ログ |

本プロジェクト（`cpa-semantic`）では `attacked` のダメージ計算を `hp - damage` の純粋な減算として定式化する（hp の下限ガードは含まない）。実証アプリケーション（`cpa-fractal`）では `max 0 (hp - damage)` として下限を 0 にクランプしているが、これは形式化の本質ではなく応用側の実装判断である。

```bash
cd cpa-semantic && cabal build && cabal test
# 8 examples, 0 failures
```

---

### B.1.8　意味論的構成の本質的な特徴

**特徴1：Core Model が実行世界に依存しない**
`Avatar` は世界パラメータを持たない。永続化インターフェース（`LoadAvatar`/`SaveAvatar`）は型として Core Model に定義されるが、実装は Boot 層が担う。

**特徴2：Projected Context のスタックに実行世界が現れない**
`ProjectedContext a` の型パラメータに実行世界を表す `m` は現れない。底は `IO` として固定。これが外包型侵食の型レベル証拠である。

**特徴3：Avatar の取得は値レベルの関数注入で実現される**
`LoadAvatar` / `SaveAvatar` はアクションの引数として渡される。Boot 層が生成した関数を Application Base 経由で Projected Context へ届ける。これは「外から参照される Avatar」という意味論的性質の型レベル表現である。

**特徴4：遡行的依存則が型として強制される**
Application Base が Projected Context を `run` する方向は許容される。逆方向は型エラーとなりコンパイル時に検出される。

---

## B.2　存在論的構成（`cpa-ontological`）

### B.2.1　形式化の対象

存在論的構成とは、実行世界の計算文脈が Projected Context のスタックに組み込まれる構成である（論文 §8.5）。実行基盤は「Avatar が存在する世界」として Core Model の型構造に現れる。

本節（B.2）は論文第8章の形式化コード例に対応する参照実装である。
論文8.5節「存在論的侵食の型シグネチャへの観測」における内包型侵食の具体例として、
`World m` 型クラスと `data Avatar m` の型シグネチャが対応している。
B.3 の型対比表と合わせて参照することで、外包型（B.1）と内包型（B.2）の差異が
型レベルで確認できる。

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
│  AnotherWorld インスタンスで m を型として選択           │
│  テストでは AnotherWorld 定義（ControlSpec）が代替     │
├──────────────────────────────────────────────────────┤
│  Interface（現象層）                                  │  ← ControlSpec.hs が模擬
├──────────────────────────────────────────────────────┤
│  Application Base（制御層）                           │  ← ApplicationBase/Control.hs
│  World m 制約のみ。AnotherWorld を知らない             │
├──────────────────────────────────────────────────────┤
│  Projected Context（射影層）                          │  ← ProjectedContext/Context.hs
│  World m 制約で loadAvatar / saveAvatar を呼ぶ        │
├──────────────────────────────────────────────────────┤
│  Core Model（根源層）                                 │  ← CoreModel/Type.hs
│  GlobalConfig / ContextualState                      │
│  Avatar m（世界パラメータ付き）                        │
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

## B.3　両構成の対比：侵食の型レベル観測

本節の型対比表は、論文第7章7.5節「侵食の二タイプ」（外包型侵食・内包型侵食）の型レベル証拠として機能する。
意味論的構成（`cpa-semantic`）が外包型侵食、存在論的構成（`cpa-ontological`）が内包型侵食に
それぞれ対応しており、その差異が型シグネチャの変化として機械的に観測できることを示す。
論文第8章8.5節「存在論的侵食の型シグネチャへの観測」の具体的な実装例としても参照されたい。

意味論的構成と存在論的構成の差異は、以下の型シグネチャの変化として機械的に観測できる。

### Avatar 型の変化

```haskell
-- 意味論：世界から独立した Avatar
data Avatar = Avatar { avatarName :: String, level :: Int, hp :: Int, mp :: Int }

-- 存在論：世界 m に内在する Avatar
data Avatar (m :: Type -> Type) = Avatar { avatarName :: String, level :: Int, hp :: Int, mp :: Int }
```

### ProjectedContext 型の変化

```haskell
-- 意味論：底が IO 固定（外包型侵食）
type ProjectedContext a   = ReaderT GlobalConfig (StateT ContextualState IO) a

-- 存在論：底が m（内包型侵食）
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m)  a
```

### アクション型の変化：attacked

```haskell
-- 意味論：load/save を引数として「外から注入」
attacked :: LoadAvatar -> SaveAvatar -> Int -> ProjectedContext Avatar

-- 存在論：World m 制約で「内在化」
attacked :: World m => Int -> ProjectedContext m (Avatar m)
```

### アクション型の変化：heal

`heal` の型シグネチャの変化は、意味論と存在論の哲学的差異をより端的に示している。

```haskell
-- 意味論：load/save を引数として「外から注入」（attacked と同一パターン）
heal :: LoadAvatar -> SaveAvatar -> ProjectedContext Avatar

-- 存在論：World m 制約のみ。引数注入は一切不要
heal :: World m => ProjectedContext m (Avatar m)
```

さらに、cpa-fractal における存在論的実装では `heal` は次のように1行で定義される。

```haskell
-- cpa-fractal 存在論：heal を healInWorld に完全委譲
-- 「回復」は世界（World m）の性質そのものであり、Avatar が外から操作されるのではなく
-- 世界が内側から完結させる。これが「World に内在する能力」の存在論的表現である。
heal :: World m => m (Avatar m)
heal = healInWorld
```

この1行の委譲は、意味論における `heal loadAvatar saveAvatar` という引数注入パターンとの対比として、内包型侵食の本質を最も端的に示す例となっている。

### Boot 層の役割の変化

```haskell
-- 意味論：関数を生成して渡す（値レベル）
runAttacked config state loadAvatar saveAvatar 30

-- 存在論：m を AnotherWorld として型推論に委ねる（型レベル）
runWithAnotherWorld heroAvatar $ runAttacked config state 30
-- ↑ この時点で m = AnotherWorld が型推論で決まる
```

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
│  ApplicationBase / Control.hs                                 │
│  runAppBase：イベントループ                                    │
│  transit   ：状態遷移の実行（TH自動生成）                       │
│  ApplicationBase / State / {Start, Run, Stop}.hs              │
│  各状態の IStateActivity インスタンス                          │ 
│                            （Entry/Exit/Transit/doActivity）  │
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



