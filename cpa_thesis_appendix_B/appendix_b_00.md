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
