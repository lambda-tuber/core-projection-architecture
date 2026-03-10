# Appendix B：Haskell による形式化コード

---

## B.1　意味論的構成（`cpa-semantic`）

### B.1.1　形式化の対象

意味論的構成とは、実行基盤が配送装置型として機能し、Core Model が実行世界の存在様式から独立して成立する構成である（論文 §7.3）。

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
│  LoadAvatar / SaveAvatar の実装を生成・インジェクト   │
│  テストでは IORef stub（ControlSpec）が代替する       │
├──────────────────────────────────────────────────────┤
│  Interface（現象層）                                  │  ← ControlSpec.hs が模擬
├──────────────────────────────────────────────────────┤
│  Application Base（制御層）                           │  ← ApplicationBase/Control.hs
├──────────────────────────────────────────────────────┤
│  Projected Context（射影層）                          │  ← ProjectedContext/Context.hs
├──────────────────────────────────────────────────────┤
│  Core Model（根源層）                                 │  ← CoreModel/Type.hs
│  GlobalConfig / ContextualState / Avatar              │
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
