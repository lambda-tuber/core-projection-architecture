# Appendix B：Haskell による形式化コード

---

## B.3　両構成の対比：侵食の型レベル観測

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
