# Core Projection Architecture (CPA)
## — A Theory of Structural Design Based on the Discovery of Existence and Contextual Projection, with Retro-dependency —

**Version:** 1.0.0  
**Authors:** Aska Lanclaude, neko  
**Date:** 2026-01-01  

---

# Appendix B: Formalization Code in Haskell

## Overview

We present a Haskell implementation that formalizes the theoretical propositions of Core Projection Architecture (CPA).

**The central claim of this appendix is that differences in architectural ontology can be observed as differences in type signatures.**

There are two purposes of formalization. First, to show that the Retro-dependency Principle — the principle that higher layers depend on lower layers for execution, while lower layers remain independent of higher-level concerns — can be expressed at the type level and mechanically enforced by the type system. Second, to show that the difference between Semantic Configuration and Ontological Configuration is observable as a change in type signatures. Erosion, in this context, refers to how the execution context propagates into the type structure.

This appendix consists of the following projects:

| Project | Target | Status |
|---|---|---|
| `cpa-semantic/` | Semantic Configuration (Outside-in Erosion) | ✅ Implemented |
| `cpa-ontological/` | Ontological Configuration (Inside-out Erosion) | ✅ Implemented |
| `cpa-application-state/` | ApplicationBase State Management (AppState pattern) | ✅ Implemented |
| `cpa-fractal/` | CPA Fractal Structure (7-package integration · Isekai Reincarnation Engine) | ✅ Implemented |

`cpa-semantic`, `cpa-ontological`, and `cpa-application-state` are standalone projects that independently formalize each concept. `cpa-fractal` is a demonstration application that integrates and extends these three configurations, and is explained separately in B.5.

---

## Semantic vs. Ontological: Type-Level Contrast

The core of this appendix is that the difference between Semantic Configuration and Ontological Configuration can be observed as **a change in type signatures**.

```haskell
-- [Semantic] Avatar has no world parameter
data Avatar

-- [Ontological] Avatar has a world parameter
data Avatar m
```

```haskell
-- [Semantic] The base of ProjectedContext is fixed to IO
type ProjectedContext a   = ReaderT GlobalConfig (StateT ContextualState IO) a

-- [Ontological] The base of ProjectedContext is m (World parameter)
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m)  a
```

```haskell
-- [Semantic] Avatar retrieval via argument injection (value level)
attacked :: LoadAvatar -> SaveAvatar -> Int -> ProjectedContext Avatar

-- [Ontological] Avatar retrieval via World m type class method (type level)
attacked :: World m => Int -> ProjectedContext m (Avatar m)
```

| Item | Semantic (B.1) | Ontological (B.2) |
|---|---|---|
| Avatar type | `data Avatar` | `data Avatar m` |
| Avatar's location | Carried in from outside the world | Inherent within the World |
| Retrieval method | `LoadAvatar` injected as argument (value level) | Method of `World m` (type level) |
| ProjectedContext base | `IO` (fixed) | `m` (World parameter) |
| Boot layer role | Generates and passes `load`/`save` functions | Selects `m` as `AnotherWorld` via type inference |
| Knowledge in `src` | Knows `LoadAvatar`/`SaveAvatar` types | Only the `World m` constraint |
| Philosophical meaning | Avatar is "an entity referenced from outside" | Avatar is "an entity inherent to the World" |

---

## B.1 Semantic Configuration (`cpa-semantic`)

### B.1.1 Target of Formalization

Semantic Configuration is a configuration in which the execution substrate functions as a Delivery-type and the Core Model is established independently of the mode of being of the execution world (Paper §7.3).

This section (B.1) is the reference implementation corresponding to the formalization code examples in Chapter 8 of the paper. The avatar use case code examples in Paper §8.4 "Type Expression of Projected Context in Logical Configuration" correspond to the type structure of the `attacked` / `heal` actions in this section. Also, the `ProjectedContext` type signature in this section functions as type-level evidence of Outside-in Erosion in Paper §8.5 "Observation of Ontological Erosion in Type Signatures" (see also the type contrast table in B.3).

Even if the execution substrate is removed, the concepts of the Core remain valid. The influence of erosion is absorbed in the Interface and Application Base and does not propagate into the Core Model's definition. At the type level, this is observed as a form in which the computational context representing the execution world does not appear as a parameter of the Projected Context stack.

```haskell
-- Type signature of ProjectedContext in Semantic Configuration
-- The base is IO (absorbs the IO side effects of LoadAvatar / SaveAvatar)
-- The computational context of the execution world does not appear as a stack parameter
-- = type-level evidence of Outside-in Erosion
type ProjectedContext a = ReaderT GlobalConfig (StateT ContextualState IO) a
```

This project adopts a game system avatar as its subject matter. Through two actions — `attacked` (taking damage) and `heal` (magical recovery) — the four-layer structure of CPA and the Retro-dependency Principle are formalized.

Avatar persistence (load/save) is defined in the Core Model as the `LoadAvatar` / `SaveAvatar` types, and the Boot layer injects their implementations. The Boot layer is outside the scope of formalization; in tests, a stub using `IORef` serves as a substitute.

---

### B.1.2 Project Structure

```
cpa-semantic/
├── cpa-semantic.cabal
├── src/
│   └── CPA/Semantic/
│       ├── CoreModel/
│       │   └── Type.hs              ← Root Layer: formalization of the discovered structure
│       ├── ProjectedContext/
│       │   └── Context.hs           ← Projection Layer: contextual projection and action definitions
│       └── ApplicationBase/
│           └── Control.hs           ← Control Layer: mechanism that brings projection down to execution context
└── test/
    └── CPA/Semantic/ApplicationBase/
        └── ControlSpec.hs           ← Interface Layer substitute (hspec) + Boot Layer substitute (stub definitions)
```

```
┌──────────────────────────────────────────────────────┐
│  Boot (Startup Layer)                                 │  ← Outside scope of formalization
│  Generates and injects LoadAvatar / SaveAvatar impls  │
│  In tests, IORef stub (ControlSpec) serves as substitute │
├──────────────────────────────────────────────────────┤
│  Interface (Phenomenon Layer)                         │  ← Simulated by ControlSpec.hs
├──────────────────────────────────────────────────────┤
│  Application Base (Control Layer)                     │  ← ApplicationBase/Control.hs
├──────────────────────────────────────────────────────┤
│  Projected Context (Projection Layer)                 │  ← ProjectedContext/Context.hs
├──────────────────────────────────────────────────────┤
│  Core Model (Root Layer)                              │  ← CoreModel/Type.hs
│  GlobalConfig / ContextualState / Avatar              │
│  LoadAvatar / SaveAvatar type aliases                 │
└──────────────────────────────────────────────────────┘
```

---

### B.1.3 Core Model (Root Layer)

**File:** `src/CPA/Semantic/CoreModel/Type.hs`

The Core Model defines the set of entities in the system. It holds only type definitions and remains independent of all upper layers. `Avatar` is formalized as a simple data type with no world parameter.

The persistence interface for Avatar is defined as type aliases `LoadAvatar` / `SaveAvatar`. The implementation (file I/O, etc.) is handled by the Boot layer and is outside the scope of formalization.

```haskell
module CPA.Semantic.CoreModel.Type where

data GlobalConfig    = GlobalConfig    { configName :: String   } deriving (Show)
data ContextualState = ContextualState { stateLog   :: [String] } deriving (Show)

-- Semantic Configuration: no world parameter
data Avatar = Avatar
  { avatarName :: String
  , level      :: Int
  , hp         :: Int
  , mp         :: Int
  } deriving (Show)

-- Avatar persistence interface types (injected by Boot layer; outside scope of formalization)
type LoadAvatar = IO Avatar
type SaveAvatar = Avatar -> IO ()
```

---

### B.1.4 Projected Context (Projection Layer)

**File:** `src/CPA/Semantic/ProjectedContext/Context.hs`

Receives `LoadAvatar` / `SaveAvatar` as action arguments, and lifts IO operations into the projection layer's computational context using `liftIO`.

```haskell
module CPA.Semantic.ProjectedContext.Context where

-- Base is IO (absorbs the IO of LoadAvatar / SaveAvatar)
type ProjectedContext a = ReaderT GlobalConfig (StateT ContextualState IO) a

-- Receives load / save as action arguments (value-level injection)
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

### B.1.5 Application Base (Control Layer)

**File:** `src/CPA/Semantic/ApplicationBase/Control.hs`

Receives `LoadAvatar` / `SaveAvatar` as arguments and passes them to the Projected Context.

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

### B.1.6 Verification of Dependency Direction

```
ApplicationBase.Control
    ↓ imports
ProjectedContext.Context
    ↓ imports
CoreModel.Type
```

---

### B.1.7 Operational Verification (Tests via hspec)

**File:** `test/CPA/Semantic/ApplicationBase/ControlSpec.hs`

A stub using `IORef` substitutes for the Boot layer's injection.

```haskell
-- Boot layer substitute: generates LoadAvatar / SaveAvatar via IORef
makeStub :: Avatar -> IO (IORef Avatar, LoadAvatar, SaveAvatar)
makeStub initial = do
  ref <- newIORef initial
  pure (ref, readIORef ref, writeIORef ref)
```

| Action | Verified Item | Expected Value |
|---|---|---|
| `attacked` (damage=30) | hp of returned Avatar | 100 → 70 |
| `attacked` (damage=30) | Persistence via saveAvatar (IORef) | 100 → 70 |
| `attacked` (damage=30) | stateLog record | `"Hero was attacked. hp: 100 -> 70"` |
| `heal` (level=4) | hp of returned Avatar | 100 → 120 (+20) |
| `heal` (level=4) | mp of returned Avatar | 50 → 40 (−10) |
| `heal` (level=4) | stateLog record | `"Hero used heal. hp: 100 -> 120, mp: 50 -> 40"` |
| `attacked` → `heal` sequence | Final hp value (shared IORef) | 90 |
| `attacked` → `heal` sequence | Order of stateLog | Damage log → Recovery log |

In this project (`cpa-semantic`), the damage calculation for `attacked` is formalized as the pure subtraction `hp - damage` (no lower bound guard on hp). In the demonstration application (`cpa-fractal`), this is implemented as `max 0 (hp - damage)` to clamp hp at 0, but this is an application-side implementation decision rather than an essential aspect of the formalization.

```bash
cd cpa-semantic && cabal build && cabal test
# 8 examples, 0 failures
```

---

### B.1.8 Essential Characteristics of Semantic Configuration

**Characteristic 1: Core Model remains independent of the execution world**
`Avatar` has no world parameter. The persistence interface (`LoadAvatar`/`SaveAvatar`) is defined as types in the Core Model, but their implementation is handled by the Boot layer.

**Characteristic 2: The execution world does not appear in the Projected Context stack**
The type parameter `m` representing the execution world does not appear in `ProjectedContext a`. The base is fixed to `IO`. This constitutes type-level evidence of Outside-in Erosion.

**Characteristic 3: Avatar retrieval is achieved via value-level function injection**
`LoadAvatar` / `SaveAvatar` are passed as action arguments. Functions generated by the Boot layer are delivered to the Projected Context via the Application Base. This characterizes the semantic property "Avatar referenced from outside" at the type level.

**Characteristic 4: The Retro-dependency Principle is enforced as types**
The direction in which Application Base `run`s the Projected Context is permitted. The reverse direction results in a type error and is detected at compile time.

---

## B.2 Ontological Configuration (`cpa-ontological`)

### B.2.1 Target of Formalization

Ontological Configuration is a configuration in which the computational context of the execution world is embedded in the Projected Context stack (Paper §8.5). The execution substrate appears in the type structure of the Core Model as "the world in which Avatar exists."

This section (B.2) is the reference implementation corresponding to the formalization code examples in Chapter 8 of the paper. As a concrete example of Inside-out Erosion in Paper §8.5 "Observation of Ontological Erosion in Type Signatures," the type signatures of the `World m` type class and `data Avatar m` correspond to this section. By referring to this section together with the type contrast table in B.3, the difference between Outside-in (B.1) and Inside-out (B.2) can be confirmed at the type level.

At the type level, this is observed as a form in which the computational context `m` representing the execution world appears as a parameter of the Projected Context stack.

```haskell
-- Type signature of ProjectedContext in Ontological Configuration
-- The base is m (World parameter)
-- The computational context m of the execution world appears as a stack parameter
-- = type-level evidence of Inside-out Erosion
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m) a
```

Avatar persistence (load/save) is defined as methods of the `World m` type class, and Avatar is internalized into the type structure as "something that exists within the World." The Boot layer performs injection by selecting the concrete type for `m` (`AnotherWorld`). The Boot layer is outside the scope of formalization; in tests, the definition of `AnotherWorld` (instance implementation) serves as a substitute.

---

### B.2.2 Project Structure

```
cpa-ontological/
├── cpa-ontological.cabal
├── src/
│   └── CPA/Ontological/
│       ├── CoreModel/
│       │   └── Type.hs              ← Root Layer: Avatar m and World m type class
│       ├── ProjectedContext/
│       │   └── Context.hs           ← Projection Layer: ProjectedContext m a and action definitions
│       └── ApplicationBase/
│           └── Control.hs           ← Control Layer: World m constraint only, independent of AnotherWorld
└── test/
    └── CPA/Ontological/ApplicationBase/
        └── ControlSpec.hs           ← Interface Layer substitute (hspec) + Boot Layer substitute (AnotherWorld definition)
```

```
┌──────────────────────────────────────────────────────┐
│  Boot (Startup Layer)                                 │  ← Outside scope of formalization
│  Selects m as type via AnotherWorld instance          │
│  In tests, AnotherWorld definition (ControlSpec) substitutes │
├──────────────────────────────────────────────────────┤
│  Interface (Phenomenon Layer)                         │  ← Simulated by ControlSpec.hs
├──────────────────────────────────────────────────────┤
│  Application Base (Control Layer)                     │  ← ApplicationBase/Control.hs
│  World m constraint only. Does not know AnotherWorld  │
├──────────────────────────────────────────────────────┤
│  Projected Context (Projection Layer)                 │  ← ProjectedContext/Context.hs
│  Calls loadAvatar / saveAvatar via World m constraint │
├──────────────────────────────────────────────────────┤
│  Core Model (Root Layer)                              │  ← CoreModel/Type.hs
│  GlobalConfig / ContextualState                       │
│  Avatar m (with world parameter)                      │
│  World m type class (loadAvatar / saveAvatar)         │
└──────────────────────────────────────────────────────┘
```

---

### B.2.3 Core Model (Root Layer)

**File:** `src/CPA/Ontological/CoreModel/Type.hs`

The Core Model defines the set of entities in the system. There are two essential differences from the Semantic Configuration. First, `Avatar` has a world parameter `m`. Second, instead of the `LoadAvatar`/`SaveAvatar` type aliases, the `World m` type class defines the persistence interface.

The `World m` type class defines only the interface. Concrete instances (`AnotherWorld`) are **not placed in `src` but defined by the `test/` side (ControlSpec as a Boot layer substitute)**. In this project, keeping `src` dependencies limited to the `World m` constraint alone is an architectural invariant.

```haskell
{-# LANGUAGE KindSignatures #-}
module CPA.Ontological.CoreModel.Type where

import Data.Kind (Type)

data GlobalConfig    = GlobalConfig    { configName :: String   } deriving (Show)
data ContextualState = ContextualState { stateLog   :: [String] } deriving (Show)

-- Ontological Configuration: with world parameter (stamps the world as a phantom type)
-- Semantic:    data Avatar   ← world-independent
-- Ontological: data Avatar m ← inherent to world m
data Avatar (m :: Type -> Type) = Avatar
  { avatarName :: String
  , level      :: Int
  , hp         :: Int
  , mp         :: Int
  } deriving (Show)

-- World type class: Avatar retrieval and persistence interface
-- In Semantic, LoadAvatar/SaveAvatar are "injected from outside" (value level)
-- In Ontological, they are "internalized" as methods of World m (type level)
-- AnotherWorld instances are not placed in src (test/ side defines them as Boot substitutes)
class Monad m => World (m :: Type -> Type) where
  loadAvatar :: m (Avatar m)
  saveAvatar :: Avatar m -> m ()
```

**Why `KindSignatures` is needed:**
The `m` in `data Avatar m` has kind `* -> *`. To define the method type `m (Avatar m)` of `World m`, GHC needs to be able to resolve the kind explicitly, which requires the `(m :: Type -> Type)` annotation via `KindSignatures`.

---

### B.2.4 Projected Context (Projection Layer)

**File:** `src/CPA/Ontological/ProjectedContext/Context.hs`

Actions hold only the `World m` constraint. No argument injection of `LoadAvatar`/`SaveAvatar` is needed; `lift . lift $ loadAvatar` reaches directly into the `m` layer of the World.

```haskell
module CPA.Ontological.ProjectedContext.Context where

-- The base becomes m (World parameter)
-- Semantic:    ReaderT GlobalConfig (StateT ContextualState IO) a  ← base is fixed IO
-- Ontological: ReaderT GlobalConfig (StateT ContextualState m)  a  ← base is m (World)
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m) a

-- World m constraint only. No argument injection needed!
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

**The structural meaning of `lift . lift`:**
The stack of `ProjectedContext m a` is layered from outside to inside as `ReaderT` → `StateT` → `m`. The methods of `World m` (`loadAvatar`/`saveAvatar`) are at the innermost layer `m`. Crossing `StateT` requires one `lift`, and crossing `ReaderT` requires one more `lift`, so the two-fold composition `lift . lift` is type-level evidence of the stack depth.

**Design implications of `heal`:**
In this standalone implementation, `heal` is described with the same procedure as `attacked`: `loadAvatar → computation → saveAvatar`. In the ontological implementation of `cpa-fractal`, however, `heal` is expressed as the single line `heal = healInWorld` (complete delegation to the world). This pattern more directly demonstrates the ontological essence — "recovery is a property of the world itself; it is not operated on from outside but completed from within the world" — and is also referenced in the contrast in B.3.

---

### B.2.5 Application Base (Control Layer)

**File:** `src/CPA/Ontological/ApplicationBase/Control.hs`

Holds only the `World m` constraint. Does not know `AnotherWorld`. The concretization of `m` is handled by the Boot layer (or `ControlSpec` in tests).

```haskell
module CPA.Ontological.ApplicationBase.Control where

-- World m constraint only. Does not know AnotherWorld!
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

**Concretization of `m` is the Boot layer's responsibility:**
The `m` in the return type `m (Avatar m, ContextualState)` of `runAttacked` is resolved by the caller via type inference. The Application Base holds only the `World m` constraint and does not know what `m` is. This is the essence of type-level injection.

---

### B.2.6 Verification of Dependency Direction

```
ApplicationBase.Control
    ↓ imports
ProjectedContext.Context
    ↓ imports
CoreModel.Type
```

This is the same dependency direction as in the Semantic Configuration. The Retro-dependency Principle holds as a type structure in both configurations.

---

### B.2.7 Operational Verification (Tests via hspec)

**File:** `test/CPA/Ontological/ApplicationBase/ControlSpec.hs`

The definition of `AnotherWorld` and its `World` instance implementation substitute for the Boot layer. `AnotherWorld` is not described anywhere in `src` and is entirely confined to `test/`. This is a demonstration of the architectural invariant that "src does not know AnotherWorld."

```haskell
-- Boot layer substitute: define AnotherWorld on the Spec side (not placed in src)
newtype AnotherWorld a = AnotherWorld
  { runAnotherWorld :: IORef (Avatar AnotherWorld) -> IO a }

instance Functor     AnotherWorld where ...
instance Applicative AnotherWorld where ...
instance Monad       AnotherWorld where ...

instance World AnotherWorld where
  loadAvatar   = AnotherWorld $ \ref -> readIORef ref
  saveAvatar a = AnotherWorld $ \ref -> writeIORef ref a

-- Boot substitute helper: runs AnotherWorld given an initial Avatar
runWithAnotherWorld :: Avatar AnotherWorld -> AnotherWorld a -> IO a
runWithAnotherWorld initial action = do
  ref <- newIORef initial
  runAnotherWorld action ref
```

| Action | Verified Item | Expected Value |
|---|---|---|
| `attacked` (damage=30) | hp of returned Avatar | 100 → 70 |
| `attacked` (damage=30) | Avatar in World (via saveAvatar · IORef) hp | 100 → 70 |
| `attacked` (damage=30) | stateLog record | `"Hero was attacked. hp: 100 -> 70"` |
| `heal` (level=4) | hp of returned Avatar | 100 → 120 (+20) |
| `heal` (level=4) | mp of returned Avatar | 50 → 40 (−10) |
| `heal` (level=4) | stateLog record | `"Hero used heal. hp: 100 -> 120, mp: 50 -> 40"` |
| `attacked` → `heal` sequence | Final hp value (shared IORef) | 90 |
| `attacked` → `heal` sequence | Order of stateLog | Damage log → Recovery log |

```bash
cd cpa-ontological && cabal build && cabal test
# 8 examples, 0 failures
```

---

### B.2.8 Essential Characteristics of Ontological Configuration

**Characteristic 1: Avatar has a world parameter**
The `m` in `data Avatar m` is a phantom type that stamps the world. The type of `Avatar` itself expresses "which world it exists in." This is an essential difference from `data Avatar` in Semantic Configuration (world-independent).

**Characteristic 2: The execution world appears in the Projected Context stack**
The execution world appears in the type parameter `m` of `ProjectedContext m a`. This constitutes the type-level evidence of Inside-out Erosion. The difference in type signature from Semantic Configuration (where the base is fixed to `IO`) serves as observational evidence of erosion.

**Characteristic 3: Avatar retrieval is achieved via type-level injection**
The methods `loadAvatar`/`saveAvatar` of `World m` appear not as action arguments but as type class constraints. The Boot layer performs injection not by passing functions but by delegating the concretization of `m` as `AnotherWorld` to type inference. This characterizes the ontological property "Avatar inherent to the World" at the type level.

**Characteristic 4: `src` remains independent of `AnotherWorld`**
The `runAttacked` / `runHeal` functions of Application Base hold only the `World m` constraint and do not depend on `AnotherWorld`. The definition of `AnotherWorld` is entirely confined to `test/` (Boot substitute) and does not propagate into the `src` dependency graph.

**Characteristic 5: The Retro-dependency Principle is enforced as types**
The same dependency direction as in Semantic Configuration holds. The direction in which Application Base `run`s the Projected Context is permitted, and the reverse direction results in a type error.

---

## B.3 Contrast of Both Configurations: Type-Level Observation of Erosion

The type contrast table in this section serves as type-level evidence for Paper §7.5 "Two Types of Erosion" (Outside-in Erosion · Inside-out Erosion). Semantic Configuration (`cpa-semantic`) corresponds to Outside-in Erosion, and Ontological Configuration (`cpa-ontological`) corresponds to Inside-out Erosion. **This demonstrates that architectural differences can be observed mechanically through type signatures.** This section can also be referred to as a concrete implementation example of Paper §8.5 "Observation of Ontological Erosion in Type Signatures."

The difference between Semantic Configuration and Ontological Configuration can be mechanically observed as the following changes in type signatures. Note that this difference is not merely syntactic but reflects a shift in the locus of existence of Avatar within the system.

### Change in Avatar Type

```haskell
-- Semantic: Avatar independent of the world
data Avatar = Avatar { avatarName :: String, level :: Int, hp :: Int, mp :: Int }

-- Ontological: Avatar inherent to world m
data Avatar (m :: Type -> Type) = Avatar { avatarName :: String, level :: Int, hp :: Int, mp :: Int }
```

### Change in ProjectedContext Type

```haskell
-- Semantic: base is fixed IO (Outside-in Erosion)
type ProjectedContext a   = ReaderT GlobalConfig (StateT ContextualState IO) a

-- Ontological: base is m (Inside-out Erosion)
type ProjectedContext m a = ReaderT GlobalConfig (StateT ContextualState m)  a
```

### Change in Action Type: `attacked`

```haskell
-- Semantic: load/save "injected from outside" as arguments
attacked :: LoadAvatar -> SaveAvatar -> Int -> ProjectedContext Avatar

-- Ontological: "internalized" via World m constraint
attacked :: World m => Int -> ProjectedContext m (Avatar m)
```

### Change in Action Type: `heal`

The change in the type signature of `heal` more directly illustrates the philosophical difference between Semantic and Ontological.

```haskell
-- Semantic: load/save injected as arguments (same pattern as attacked)
heal :: LoadAvatar -> SaveAvatar -> ProjectedContext Avatar

-- Ontological: World m constraint only. No argument injection whatsoever
heal :: World m => ProjectedContext m (Avatar m)
```

Furthermore, in the ontological implementation of `cpa-fractal`, `heal` is defined in a single line:

```haskell
-- cpa-fractal Ontological: heal fully delegated to healInWorld
-- "Recovery" is a property of the world (World m) itself; Avatar is not operated on
-- from outside — the world completes it from within.
-- This is the ontological expression of "capability inherent to the World."
heal :: World m => m (Avatar m)
heal = healInWorld
```

This single-line delegation, contrasted with the argument injection pattern of `heal loadAvatar saveAvatar` in the Semantic Configuration, is the most direct example of Inside-out Erosion's essence in the B.3 contrast.

### Change in Boot Layer Role

```haskell
-- Semantic: generates and passes functions (value level)
runAttacked config state loadAvatar saveAvatar 30

-- Ontological: delegates m as AnotherWorld to type inference (type level)
runWithAnotherWorld heroAvatar $ runAttacked config state 30
-- ↑ at this point, m = AnotherWorld is determined by type inference
```

---

## B.4 ApplicationBase State Management (`cpa-application-state`)

### B.4.1 Classification of States and Determination of Management Target

> **Note:** This section is orthogonal to the semantic/ontological distinction and focuses solely on application-level state management. The formalization of AppState does not depend on either Semantic or Ontological Configuration.

The system state in CPA is classified into the following four types:

| Type | Layer | Nature | Formalization Target |
|---|---|---|---|
| **Existential Info** | CoreModel | Avatar HP, attributes, etc. — "mere values." Not subject to state management. | Out of scope (model definition only) |
| **Contextual State** | ProjectedContext | Temporary memory during projection computation. Initialized from SystemState and returned via feedback mapping. | Out of scope (already formalized as `StateT` in Projected Context) |
| **AppState** (application mode of being) | ApplicationBase | Application lifecycle (starting, running, stopped). Represents the "mode" of existence. | **★ Target of formalization in this section** |
| **External State** | Inside Erosion | State of the external world outside the management boundary. | Out of scope (outside management boundary) |

#### Positioning of AppState

AppState occupies the topmost position in SystemState (hardware, OS, middleware, libraries, frameworks, and the internal state of the application). States below the application layer in the system stack are outside CPA's management scope. AppState is a state that is explicitly defined, held, and transitioned at **the boundary between the framework's entry point and the Application Base**, and is the sole target of formalization as a "mode of existence" for which CPA bears responsibility.

The formalization of AppState does not depend on either Semantic or Ontological Configuration, and is defined independently as **a responsibility of Application Base common to both configurations**.

---

### B.4.2 Formalization Policy

The formalization follows these policies:

- **State pattern via GADTs**: Represents the three states of Start / Run / Stop at the type level
- **Existential quantification `AppStateW`**: Defines a wrapper type that allows all states to be handled uniformly
- **Automatic generation via Template Haskell**: Automatically generates `IAppState` instances and the `transit` function from state and transition definitions
- **Simple event loop**: Directly testable from HSpec without external frameworks like `conduit`. Note that `cpa-fractal` advances this standalone formalization by adopting a Conduit pipeline (`src .| work .| sink`) and asynchronous TQueue-driven execution (see B.5)
- **ProjectedContext calls substituted with log output**: Focuses on formalizing the skeleton of state transitions; actual action execution is substituted

---

### B.4.3 Project Structure

```
cpa-application-state/
├── cpa-application-state.cabal
├── src/
│   └── CPA/Application/State/
│       ├── CoreModel/
│       │   ├── Type.hs      ← GADTs, type classes, monad stack definitions
│       │   ├── TH.hs        ← Template Haskell auto-generation functions
│       │   └── Utility.hs   ← changeTo (state transition execution)
│       └── ApplicationBase/
│           ├── Control.hs   ← runAppBase · run · runAppState · transit (TH-generated)
│           └── State/
│               ├── Start.hs ← IStateActivity instances for Start state
│               ├── Run.hs   ← IStateActivity instances for Run state
│               └── Stop.hs  ← IStateActivity instances for Stop state
└── test/
    └── CPA/Application/State/ApplicationBase/
        └── ControlSpec.hs   ← State transition verification tests (4 scenarios)
```

```
┌──────────────────────────────────────────────────────────────┐
│  Boot (Startup Layer)                                         │  ← Outside scope of formalization
│  Generates AppStateW StartState and calls run                 │
├──────────────────────────────────────────────────────────────┤
│  Interface (Phenomenon Layer)                                 │  ← Simulated by ControlSpec.hs
├──────────────────────────────────────────────────────────────┤
│  ApplicationBase / Control.hs                                 │
│  runAppBase: event loop                                       │
│  transit: state transition execution (TH auto-generated)      │
│  ApplicationBase / State / {Start, Run, Stop}.hs             │
│  IStateActivity instances for each state                     │
│                            (Entry/Exit/Transit/doActivity)    │
├──────────────────────────────────────────────────────────────┤
│  CoreModel / Type.hs                                         │
│  AppState GADT / AppStateW / Event GADT / EventW             │
│  IStateActivity / IAppState / IAppStateW type classes         │
│  AppStateContext monad stack                                  │
└──────────────────────────────────────────────────────────────┘
```

---

### B.4.4 CoreModel: Type Definitions (`Type.hs`)

**File:** `src/CPA/Application/State/CoreModel/Type.hs`

#### State Transition Definition

```haskell
data StateTransition =
    StartToRun
  | RunToStop
  deriving (Show, Eq)
```

#### Event GADT

Holds the type information of each event as the type parameter `r`. `EventW` is a wrapper via existential quantification, used to handle events uniformly without being aware of their kind.

```haskell
data Event r where
  EntryEvent    :: Event EntryEventData
  ExitEvent     :: Event ExitEventData
  TransitEvent  :: TransitEventData  -> Event TransitEventData
  AttackedEvent :: AttackedEventData -> Event AttackedEventData

-- Wrapper via existential quantification
data EventW = forall r. EventW (Event r)
```

`AttackedEvent` is an event corresponding to the `doActivity` of the Run state, representing a Projected Context call equivalent to the `attacked` action in Semantic / Ontological configurations.

#### AppState GADT and Monad Stack

```haskell
-- State kinds (type level)
data StartStateData = StartStateData deriving (Show)
data RunStateData   = RunStateData   deriving (Show)
data StopStateData  = StopStateData  deriving (Show)

-- State pattern via GADTs: type parameter distinguishes states at the type level
data AppState s where
  StartState :: AppState StartStateData
  RunState   :: AppState RunStateData
  StopState  :: AppState StopStateData

-- Wrapper via existential quantification (encapsulates IAppState constraint)
data AppStateW = forall s. (IAppState s, Show s) => AppStateW (AppState s)

-- Monad stack: collectively manages state holding, config reading, error handling, logging, IO
type AppStateContext =
  StateT AppStateW (ReaderT GlobalConfig (ExceptT String (LoggingT IO)))
```

**The role of `AppStateW`:**
The type parameter `s` of GADTs is only valid within individual pattern match clauses; multiple states cannot coexist in lists or fields. The existential quantification `forall s.` erases this constraint, allowing Start, Run, and Stop to be treated as the same type. This is the core mechanism for realizing OOP-style polymorphism of the state pattern in Haskell's type system.

#### Type Class Definitions

```haskell
-- Processing when state s receives event r (default: processes TransitEvent only)
class (Show s, Show r) => IStateActivity s r where
  action :: AppState s -> Event r -> AppStateContext (Maybe StateTransition)
  action _ (TransitEvent (TransitEventData t)) = return (Just t)
  action _ _                                   = return Nothing

-- State s dispatches EventW (existentially quantified event)
class IAppState s where
  actionS :: AppState s -> EventW -> AppStateContext (Maybe StateTransition)

-- AppStateW (existentially quantified state) dispatches EventW
class IAppStateW s where
  actionSW :: s -> EventW -> AppStateContext (Maybe StateTransition)

instance IAppStateW AppStateW where
  actionSW (AppStateW a) r = actionS a r
```

---

### B.4.5 CoreModel: Template Haskell (`TH.hs`)

**File:** `src/CPA/Application/State/CoreModel/TH.hs`

#### `instanceTH_IAppState`: Auto-generation of IAppState instances

Automatically generates clauses of `actionS` for every constructor of the Event GADT. When a new constructor is added to Event, each state file need not be modified — the response is handled automatically.

```haskell
-- Usage (Start.hs)
instanceTH_IAppState ''StartStateData

-- Generated code
instance IAppState StartStateData where
  actionS s (EventW r@EntryEvent{})    = action s r
  actionS s (EventW r@ExitEvent{})     = action s r
  actionS s (EventW r@TransitEvent{})  = action s r
  actionS s (EventW r@AttackedEvent{}) = action s r
```

#### `funcTH_transit`: Auto-generation of the transit function

Uses the naming convention of `StateTransition` constructors (`XxxToYyy` → transition from `XxxState` to `YyyState`) to auto-generate the transition function. **Invalid transitions are collected in the `Left` of `ExceptT` via `throwError`** (preventing leakage to the IO layer via `fail`).

```haskell
-- Generated code
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

**Design implications of `throwError` vs `fail`:**
`fail` is thrown as an IO exception via the `MonadFail` instance of `IO`, passing through `ExceptT` and leaking all the way to the IO layer. By using `throwError`, invalid transition errors are collected in the `Left` of `ExceptT String` and are contained within the `AppStateContext` layer. This is a demonstration that CPA's layer composition **is enforced at the type level**.

#### `changeTo`: State switching execution (`Utility.hs`)

```haskell
-- Switches state in the order: Exit → Entry → modify
changeTo :: AppStateW -> AppStateContext ()
changeTo nextSt = do
  curSt <- get
  _ <- actionSW curSt  (EventW ExitEvent)   -- Fire Exit of current state
  _ <- actionSW nextSt (EventW EntryEvent)  -- Fire Entry of next state
  modify (\_ -> nextSt)                     -- Update StateT state
```

---

### B.4.6 ApplicationBase: Implementation of Each State

#### Start State (`State/Start.hs`)

```haskell
-- IAppState StartStateData instance auto-generated by TH
instanceTH_IAppState ''StartStateData

instance IStateActivity StartStateData EntryEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: entry.")
    return noStateTransition

instance IStateActivity StartStateData ExitEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: exit.")
    return noStateTransition

-- TransitEventData: default implementation (accepts StartToRun)
instance IStateActivity StartStateData TransitEventData

-- AttackedEvent: not handled in Start state
instance IStateActivity StartStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Start: AttackedEvent not handled in this state.")
    return noStateTransition
```

#### Run State (`State/Run.hs`)

The `AttackedEvent` in the Run state is the `doActivity` corresponding to a Projected Context call. Log output substitutes here, but in an actual system, the `attacked` action of the Projected Context would be called from here.

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

-- TransitEventData: default implementation (accepts RunToStop)
instance IStateActivity RunStateData TransitEventData

-- AttackedEvent: doActivity (corresponds to Projected Context call)
instance IStateActivity RunStateData AttackedEventData where
  action _ _ = do
    $logDebugS (T.pack "CPA") (T.pack "Run: AttackedEvent - ProjectedContext called. (doActivity)")
    return noStateTransition
```

#### Stop State (`State/Stop.hs`)

The Stop state is a terminal state with no outgoing transitions. When it receives a `TransitEvent`, the TH-generated `transit` returns an error via `throwError`.

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

instance IStateActivity StopStateData TransitEventData  -- invalid transition → throwError
instance IStateActivity StopStateData AttackedEventData -- no-op
```

#### Event Loop and Execution Runner (`Control.hs`)

```haskell
-- Generate transit function via TH
funcTH_transit

-- Simple loop that processes an event list in order
-- No conduit; directly testable from HSpec
runAppBase :: [EventW] -> AppStateContext ()
runAppBase []     = return ()
runAppBase (e:es) = do
  st     <- get
  result <- actionSW st e
  case result of
    Nothing -> runAppBase es
    Just t  -> transit t >> runAppBase es

-- Boot-equivalent entry point (starts from initial state StartState)
run :: [EventW] -> IO (Either String ((), AppStateW))
run events = runAppState (AppStateW StartState) (runAppBase events)

-- Runner that peels AppStateContext down to IO
runAppState :: AppStateW -> AppStateContext a -> IO (Either String (a, AppStateW))
runAppState initSt ctx =
  runStderrLoggingT
    $ runExceptT
    $ flip runReaderT GlobalConfig
    $ runStateT ctx initSt
```

---

### B.4.7 Operational Verification (State Transition Demonstration via hspec)

**File:** `test/CPA/Application/State/ApplicationBase/ControlSpec.hs`

Passes an event list to the `run` function and verifies state transitions via the final state and return value.

```haskell
-- Helper: runs events and retrieves the final AppStateW
runEvents :: [EventW] -> IO (Either String AppStateW)
runEvents events = fmap (fmap snd) <$> ... -- extracts final state from run result

stateLabel :: AppStateW -> String
stateLabel (AppStateW StartState) = "Start"
stateLabel (AppStateW RunState)   = "Run"
stateLabel (AppStateW StopState)  = "Stop"
```

| Scenario | Input Event Sequence | Expected Result |
|---|---|---|
| 1: Start → Run | `[TransitEvent StartToRun]` | Final state is `"Run"` |
| 2: Start → Run → Stop | `[TransitEvent StartToRun, TransitEvent RunToStop]` | Final state is `"Stop"` |
| 3: doActivity in Run | `[TransitEvent StartToRun, AttackedEvent]` | No error · Final state is `"Run"` |
| 4: Invalid transition captured | `[TransitEvent RunToStop]` (from Start state) | Error collected in `Left` of `ExceptT` |

Verification code for Scenario 4:

```haskell
context "when RunToStop (invalid transition) is received in Start state" $ do
  it "should be captured by ExceptT" $ do
    let events = [ EventW (TransitEvent (TransitEventData RunToStop)) ]
    result <- runEvents events
    case result of
      Left  _  -> return ()   -- OK if collected in Left of ExceptT
      Right st -> expectationFailure $
        "Expected an error but succeeded. State: " ++ stateLabel st
```

```bash
cd cpa-application-state && cabal build && cabal test
# 4 examples, 0 failures
```

---

### B.4.8 Essential Characteristics of AppState Formalization

**Characteristic 1: Type safety of the state pattern via GADTs**
The type parameter `s` of `AppState s` distinguishes states at the type level. Start, Run, and Stop are treated as distinct types, and different `IStateActivity` instances can be defined per state.

**Characteristic 2: Achieving polymorphism via existential quantification**
With `AppStateW = forall s. (IAppState s, Show s) => AppStateW (AppState s)`, Start, Run, and Stop can be treated as the same type. This realizes OOP-style polymorphism at the type level while preserving the type safety of each state.

**Characteristic 3: Reduction of boilerplate and extensibility via Template Haskell**
`instanceTH_IAppState` auto-generates `actionS` clauses for every Event constructor, and `funcTH_transit` generates the `transit` function from the naming convention of transition names. When new constructors are added to Event or StateTransition, each state file need not be modified.

**Characteristic 4: Layer-internal error containment via `throwError` (type-level proof of CPA layer composition)**
By collecting invalid transitions in the `Left` of `ExceptT String` via `throwError`, errors are confined within the computational context of `AppStateContext`. Using `fail` would cause leakage to the IO layer, breaking CPA's layer boundaries. Scenario 4 of HSpec (`Left _ -> return ()`) demonstrates the correctness of this layer composition.

**Characteristic 5: Formalization independent of Semantic and Ontological Configurations**
AppState remains independent of either the Avatar/World configuration of B.1 (Semantic) or B.2 (Ontological). Application Base state management is defined with the same type structure regardless of the type of erosion (Outside-in or Inside-out). This demonstrates the independence of CPA's layer responsibilities.

---

### B.4.9 Supplementary Discussion: Data Sharing Between State Transitions

The GoF State pattern's original responsibility is to "encapsulate behavior per state." Therefore, **the mechanism for passing data from one state to the next is outside the standard scope of the pattern** and must be designed as an extension when needed.

Entry and Exit actions are hooks held by each state, and serve as natural insertion points for shared processing during transitions. The following organizes the three main design approaches for inter-state data sharing.

---

#### Approach 1: Internal Extension of the State Machine (Transition Hooks)

An approach in which a "transformation function" is inserted into the state transition trigger, allowing a user-defined function to be executed that takes the final data of the previous state and the initial data of the next state as arguments.

```
On changeTo execution:
  ExitAction(prev state)  →  transform(prev state data, next state data)  →  EntryAction(next state)
```

Type image in Haskell:

```haskell
-- Define a transformation function per transition
type TransitFn s1 s2 = AppState s1 -> AppState s2 -> AppStateContext ()

handleTransition :: (State s1, State s2) => AppState s1 -> AppState s2 -> AppStateContext ()
```

**Characteristics:** Transition logic is self-contained within the state machine, making it easy to maintain type safety. However, all transition patterns (state count squared) must be covered, which would be handled via Template Haskell auto-generation or a pattern of overriding default implementations. Integration into the existing `changeTo` / `funcTH_transit` requires separate consideration.

**Decision in `cpa-fractal`:** Not needed at present. The cost of covering all transitions outweighs the benefit gained.

---

#### Approach 2: Data Passing via Shared Storage

An approach in which a shared data area maintained across transitions is placed outside (or in an upper layer of) the state machine. Entry and Exit actions read and write this area to pass data between states.

The concrete storage medium does not matter. External files, RDB, in-memory extensible records, JSON (Aeson), etc. can be chosen according to system requirements. In Haskell, stacking another layer of `StateT` is a natural implementation.

```haskell
-- Image of holding a shared context by stacking StateT
data SharedContext = SharedContext { sharedData :: Map Text Value }

type AppStateContext =
  StateT SharedContext (StateT AppStateW (ReaderT GlobalConfig (ExceptT String (LoggingT IO))))

-- Write in ExitAction, read in EntryAction
onExit :: AppState s -> AppStateContext ()
onExit _ = modify (\ctx -> ctx { sharedData = ... })

onEntry :: AppState s -> AppStateContext ()
onEntry _ = gets sharedData >>= \d -> ...
```

When shared data is held as `Map Text Value` (Aeson), new fields can be added without modifying existing state definitions. The ability to log the contents of shared memory during debugging is also an advantage.

**Characteristics:** State classes need not know each other's internal structures, maintaining loose coupling. Coverage of all transition patterns is also unnecessary. However, access scope management is required to prevent the shared area from becoming a "anything goes" global variable.

**Decision in `cpa-fractal`:** Not needed at present. Data to be passed between states can be sufficiently handled by event notification via `MsgSetAvatar` (Approach 3).

---

#### Approach 3: External Management and Event Notification (Current Method in `cpa-fractal`)

An approach in which an external agent to the state machine holds and manages data, injecting information into each state via events (messages). **This is the design currently adopted by `cpa-fractal-app`.**

```
cpa-fractal-app (external agent)
  │
  │  MsgSetAvatar (Avatar data sent as event)
  ▼
cpa-semantic-world / cpa-ontological-world (state machine)
  EntryAction receives Avatar and incorporates it into internal state
```

Concretely, the Exit action of `fractal-app`'s Start state generates an initial Avatar and enqueues it as `MsgSetAvatar` into the TQueue of `semantic-world`. Also, when a MagicalCalamity (reincarnation) occurs, the extraction of the Avatar and sending `MsgSetAvatar` to the other world's TQueue is handled by the world side (the `doActivity` of the world that received it), while `fractal-app` simply sends a reincarnation instruction (`MsgMagicalCalamity`).

```haskell
-- ExitAction of Start state: inject initial Avatar into semantic-world
onExit StartState = do
  let avatar = Avatar { _nameAvatar = "Hero", ... }
  liftIO $ atomically $ writeTQueue semanticQueue (MsgSetAvatar avatar)

-- doActivity of the world that received MsgMagicalCalamity: extract Avatar and transfer to other world
handleMagicalCalamity = do
  avatar <- takeAvatar
  liftIO $ atomically $ writeTQueue otherWorldQueue (MsgSetAvatar avatar)
```

**Characteristics:** The coupling within the state machine is kept at zero. The owner of data (the external agent) is clear, and responsibility boundaries are unambiguous. Compatibility with asynchronous processing (TQueue) is also good. However, the design of "who sends data to whom and when" directly governs the overall system behavior, so event flow design is critical.

**Decision in `cpa-fractal`:** Currently adopted. Ownership and transfer responsibility of Avatar are clearly separated between `fractal-app` and the worlds, satisfying current requirements without excess or deficiency.

---

#### Comparison of Three Approaches

| Approach | Location of Data Management | Inter-state Coupling | Adoption in `cpa-fractal` |
|---|---|---|---|
| 1. Transition hooks | Inside state machine | Low–medium (only per transition pair) | Not needed |
| 2. Shared storage | Outside state machine (shared area) | Low (via shared area) | Not needed |
| 3. Event notification | External agent | Zero (only via events) | **Adopted** |

When inter-state data passing is needed beyond the pure scope of the GoF State pattern, a practical design would combine these three approaches according to the system's scale, asynchronous requirements, and priority given to type safety.

---

## B.5 CPA Fractal Structure (`cpa-fractal`)

### B.5.1 Positioning of This Section

In B.1 through B.3, Semantic Configuration and Ontological Configuration were independently formalized as standalone projects (`cpa-semantic`, `cpa-ontological`). In B.4, AppState-based state management was independently formalized as `cpa-application-state`.

`cpa-fractal` covered in this section is a demonstration application that **integrates and extends** these three formalizations. The most significant difference from the standalone versions is the "repetition of structure." Each of the Semantic world and Ontological world internally holds the **same layer composition of CoreModel → ProjectedContext → ApplicationBase → Interface → Boot**, while the whole is also assembled with the same layer composition. This is the meaning of "fractal" in this section's title.

This section (B.5) is a demonstration of Paper §6.6 "Fractal Recursiveness" (Fractal Recursion Axiom). It shows that Axiom 5 — "The Core Projection structure holds recursively at any scale" — is satisfied in both the entire system (macro) and the interior of each world package (micro) in the seven-package composition of `cpa-fractal`. Also, the type signatures of the Boot Layer (B.5.8) correspond as a concrete implementation example to Paper §8.6 "Type-Level Proof of the Retro-dependency Principle."

---

### B.5.2 What is the Fractal?

#### Definition of Fractal

"Fractal" in this section refers to **the same architectural unit appearing as an autonomous structure at different scales**. Like a mathematical fractal figure, each part constituting the whole has the same structure as the whole. The "same architectural unit" here is CPA's layer composition (CoreModel → ProjectedContext → ApplicationBase → Interface → Boot).

What is important in this definition is the phrase "as an autonomous structure." The fact that pipeline patterns and state pattern implementations are common across packages is design consistency, not fractal. Fractal means that **a given package internally encompasses CPA's layer composition on its own and can operate with the same structural logic as the entire system**.

#### CPA Layer Composition (5 Layers)

CPA consists of the following five layers:

```
Boot              ← Starting point for startup, configuration, and injection. Does not know upper layers.
Interface         ← Contact point with the external world. Input/output conversion.
ApplicationBase   ← Application substrate. State management and orchestration.
ProjectedContext  ← Projected context. Where domain operations are executed.
CoreModel         ← Central model. Depends on no other layer whatsoever.
```

The direction of dependency is one-way; Boot is the highest (knows the most), and CoreModel is the lowest (knows nothing).

#### Observation of Fractal Nature

In a typical hierarchical architecture, each layer "appears only once." In `cpa-fractal`, however, **this five-layer composition appears both in the entire system (macro) and within each world package's interior (micro)**.

```
[Entire Composition (Macro)]
Boot            : cpa-bootstrap
Interface       : cpa-request / cpa-response
ApplicationBase : cpa-fractal-app
ProjectedContext: cpa-semantic-world / cpa-ontological-world
CoreModel       : cpa-multiverse

[Interior of cpa-semantic-world (Micro)]
Boot            : ← cpa-bootstrap handles startup
Interface       : ← TQueue of GlobalContext (contact point with outside)
ApplicationBase : AppState management of cpa-semantic-world
ProjectedContext: Processing pipeline of cpa-semantic-world
CoreModel       : Avatar / Message of cpa-multiverse
```

Looking at the interior of `cpa-semantic-world`, which occupies the ProjectedContext layer of the whole, the same structure of CoreModel → ProjectedContext → ApplicationBase appears there too. The ProjectedContext of the whole operates according to the same structural logic as CPA's layer composition within itself. This property — where "parts have the same structure as the whole" — is the fractal nature.

The type-level evidence of fractal nature also appears in the following type signature:

```haskell
-- ProjectedContext of cpa-semantic-world
-- The ProjectedContext layer of the whole again holds a ProjectedContext stack internally
type SemanticWorldContext a =
  ReaderT GlobalConfig (StateT ContextualState (ConduitT Message Void IO)) a
```

---

### B.5.3 Seven-Package Composition and Layer Assignment

`cpa-fractal` consists of seven Haskell packages. The CPA layer position of each package is shown below:

```
[Boot Layer]
  Boot/cpa-bootstrap          ← Startup, configuration, thread management

[Interface Layer]
  Interface/cpa-request       ← stdin → RequestQueue (input side)
  Interface/cpa-response      ← ResponseQueue → stdout (output side)

[Application Base Layer]
  ApplicationBase/cpa-fractal-app   ← Reincarnation protocol · 4-state GADTs

[Projected Context Layer]
  ProjectedContext/cpa-semantic-world    ← Semantic world
  ProjectedContext/cpa-ontological-world ← Ontological world

[Core Model Layer]
  CoreModel/cpa-multiverse    ← Avatar / Message / Response / GlobalContext
```

The dependency direction of each package is one-way (bottom to top), and no circular references occur.

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

#### Necessity of Package Division and Fractal Structure

In large-scale software development, systems are divided into units of packages (or modules). There are practical reasons for this division. Each package exposes only a minimal public interface to the outside and hides internal implementation. This realizes "localization of change," in which internal changes to one package do not propagate to other packages. Package boundaries also correspond to development team and responsibility boundaries, forming units within which multiple teams can independently develop and release.

In CPA, this division can be interpreted as "the natural emergence of fractal structure." For each package to function as an autonomous unit, it needs to internally encompass the layer composition from CoreModel to Boot. As the number of packages grows, or as system scale increases, CPA's five-layer composition appears repeatedly at more and more scales. This shows that fractal structure is not a "design contrivance" but **the form that structure naturally takes in large-scale development**.

---

### B.5.4 Core Model: GlobalContext and TQueue Communication Channels

**Package:** `CoreModel/cpa-multiverse`

`cpa-multiverse` defines the "common language" of the entire system. The most important element is `GlobalContext`, which centrally holds inter-thread communication channels via four TQueues.

```haskell
-- GlobalContext of cpa-multiverse
-- Four TQueues form the messaging backbone of the entire system
data GlobalContext = GlobalContext
  { _requestQueueGlobalContext     :: TQueue Request    -- stdin → fractal-app
  , _semanticQueueGlobalContext    :: TQueue Message    -- fractal-app → semantic-world
  , _ontologicalQueueGlobalContext :: TQueue Message    -- fractal-app → ontological-world
  , _responseQueueGlobalContext    :: TQueue Response   -- any → stdout
  }
```

```haskell
-- Avatar: common entity across both worlds — Semantic (no world parameter) and Ontological (with world parameter)
data Avatar = Avatar
  { _nameAvatar  :: String
  , _levelAvatar :: Int
  , _hpAvatar    :: Int
  , _mpAvatar    :: Int
  }

-- Message: algebraic data type for commands that fractal-app sends to each world
-- The substance of the reincarnation protocol is expressed with this type
data Message
  = MsgAttacked Int        -- inflict damage
  | MsgHeal                -- heal
  | MsgSetAvatar Avatar    -- inject Avatar
  | MsgMagicalCalamity     -- reincarnation trigger (fractal-app → current world)
  | MsgQuit                -- thread termination instruction

-- Request: input command parsed from stdin
data Request
  = ReqAttacked Int
  | ReqHeal
  | ReqCalamity
  | ReqQuit
  | ReqUnknown String

-- Response: response output to stdout
data Response
  = ResAvatar Avatar       -- display Avatar state
  | ResMessage String      -- text message
  | ResQuit                -- termination signal
```

The `Message` type is designed as a **command pattern**, expressing instructions to each world as data. `MsgSetAvatar` (Avatar injection) and `MsgMagicalCalamity` (reincarnation trigger) are the core of the reincarnation protocol.

---

### B.5.5 Projected Context: World Engine of the Processing Pipeline

**Packages:** `ProjectedContext/cpa-semantic-world` · `ProjectedContext/cpa-ontological-world`

Each world operates as a pipeline that takes a TQueue as its source and executes actions each time a message is received.

```haskell
-- ApplicationBase.Control of cpa-semantic-world
run :: GlobalContext -> IO ()
run ctx = runSemanticWorldContext ctx $ do
  void $ actionSW (WorldStateW StartState) (EventW EntryEvent)
  transit StartToRun
  runConduit (src .| work .| sink)   -- ← pipeline-driven
  transit RunToStop
  void $ actionSW (WorldStateW StopState) (EventW ExitEvent)

-- src: dequeues Message from semanticQueue and yields it
src :: ConduitT () Message SemanticWorldContext ()
src = do
  ctx  <- lift $ lift $ lift ask
  msg  <- liftIO $ atomically $ readTQueue (_semanticQueueGlobalContext ctx)
  case msg of
    MsgQuit -> return ()    -- terminate pipeline
    _       -> yield msg >> src

-- work: converts Message to EventW
work :: ConduitT Message EventW SemanticWorldContext ()
work = awaitForever $ \msg -> yield (EventW (InputEvent (InputEventData msg)))

-- sink: sends EventW to the state pattern and processes action results
sink :: ConduitT EventW Void SemanticWorldContext ()
sink = await >>= \case
  Nothing -> return ()
  Just ev -> do
    stopped <- lift (go ev)
    if stopped then return () else sink
```

The pipeline `src .| work .| sink` connects `Message` flowing in from TQueue to the state pattern. The pipeline is closed by `MsgQuit`, and the world's thread terminates normally.

#### Structural Identity with the Ontological World

The control structure of `cpa-ontological-world` has the exact same `src .| work .| sink` pattern as `cpa-semantic-world`. The only differences are the type of Projected Context (the ontological version has the `World m` constraint) and the implementation of Avatar actions.

---

### B.5.6 Application Base: Reincarnation Protocol and 4-State GADTs

**Package:** `ApplicationBase/cpa-fractal-app`

`cpa-fractal-app` is the orchestrator of the entire system. It manages "which world" the Avatar is in using 4-state GADTs, and the world that receives `MsgMagicalCalamity` autonomously executes the reincarnation.

#### Type Expression of Mode of Existence via 4-State GADTs

```haskell
-- AppState GADT of fractal-app
-- 4 states: Start / Semantic (Avatar in semantic world) / Ontological (Avatar in ontological world) / Stop
data AppState s where
  StartState       :: AppState StartStateData
  SemanticState    :: AppState SemanticStateData     -- Avatar exists in semantic world
  OntologicalState :: AppState OntologicalStateData  -- Avatar exists in ontological world
  StopState        :: AppState StopStateData
```

The three states (Start/Run/Stop) of the standalone version (`cpa-application-state`) are developed in `cpa-fractal-app` into four states (Start/Semantic/Ontological/Stop) expressing "which world the Avatar exists in."

#### Reincarnation Protocol: Propagation of `MsgMagicalCalamity`

The reincarnation protocol is executed in the following steps:

```
1. User inputs "calamity"
2. Interface layer enqueues it in requestQueue as ReqCalamity
3. cpa-fractal-app receives ReqCalamity
4. fractal-app checks the current AppState and sends MsgMagicalCalamity to the current world's TQueue
5. The doActivity of the Run state of the receiving world (e.g., semantic-world) processes:
   a. Extracts (erases) its own Avatar
   b. Sends MsgSetAvatar (Avatar) to the other world's (ontological-world's) TQueue (injection)
   c. Returns ReqCalamity to fractal-app's requestQueue (prompting AppState transition)
6. cpa-fractal-app transitions AppState from SemanticState → OntologicalState
```

The core of this design is that "the responsibility for erasure and injection belongs to the world itself, not to fractal-app." fractal-app merely sends a reincarnation trigger `MsgMagicalCalamity` to the current world; the extraction and injection of Avatar is handled by that world's `doActivity`.

```haskell
-- Run state of semantic-world: MsgMagicalCalamity handler (conceptual image)
-- Extracts Avatar → injects into other world → notifies fractal-app of reincarnation completion
handleMagicalCalamity :: SemanticWorldContext ()
handleMagicalCalamity = do
  ctx    <- ask
  avatar <- gets currentAvatar
  -- 1. Inject Avatar into ontological world
  liftIO $ atomically $
    writeTQueue (_ontologicalQueueGlobalContext ctx) (MsgSetAvatar avatar)
  -- 2. Notify fractal-app of reincarnation completion (trigger for AppState transition)
  liftIO $ atomically $
    writeTQueue (_requestQueueGlobalContext ctx) (MsgCalamityDone)
```

---

### B.5.7 Interface Layer: External Contact Points of the Pipeline

**Packages:** `Interface/cpa-request` · `Interface/cpa-response`

The Interface layer is the contact point connecting the external world (stdin/stdout) to the internal TQueues. Both `cpa-request` and `cpa-response` are internally composed of the same `src .| work .| sink` pattern.

#### `cpa-request`: stdin → requestQueue

```haskell
run :: IO (Maybe T.Text) -> GlobalContext -> IO ()
run readLine ctx = runWorldStateContext ctx $ do
  void $ actionSW (WorldStateW StartState) (EventW EntryEvent)
  transit StartToRun
  runConduit (src readLine .| work .| sink)
  transit RunToStop
  void $ actionSW (WorldStateW StopState) (EventW ExitEvent)

-- src: reads one line at a time from stdin and yields
src :: IO (Maybe T.Text) -> ConduitT () T.Text WorldStateContext ()
src readLine = do
  mLine <- liftIO readLine
  case mLine of
    Nothing   -> return ()
    Just line -> yield line >> src readLine

-- work: converts text lines to InputEvent (EventW)
work :: ConduitT T.Text EventW WorldStateContext ()
work = awaitForever $ \line ->
  yield (EventW (InputEvent (InputEventData line)))
```

#### `cpa-response`: responseQueue → stdout

```haskell
run :: (T.Text -> IO ()) -> GlobalContext -> IO ()
run writeFn ctx = runWorldStateContext ctx $ do
  ...
  runConduit (src .| work writeFn .| sink)

-- src: reads Response from responseQueue and yields
-- Closes the pipeline when ResQuit is received
src :: ConduitT () Response WorldStateContext ()
src = do
  ctx  <- lift $ lift $ lift ask
  resp <- liftIO $ atomically $ readTQueue (_responseQueueGlobalContext ctx)
  case resp of
    ResQuit -> return ()
    _       -> yield resp >> src
```

---

### B.5.8 Boot Layer: GlobalContext Generation and Thread Startup

**Package:** `Boot/cpa-bootstrap`

Bootstrap is the ignition device of the entire system. It has three responsibilities: reading YAML configuration, generating GlobalContext, and starting all threads in parallel.

```haskell
-- Entry point of cpa-bootstrap
-- apps is a list of (GlobalContext -> IO ()) injected from Main
-- Control does not know the contents of the list (which packages to start)
run :: ArgData -> [GlobalContext -> IO ()] -> IO ()
run args apps = do
  conf             <- loadConf args           -- YAML or def
  resolvedLogDir   <- resolveLogDir (_logDirConfigData conf)
  ctx              <- makeGlobalContext (_logLevelConfigData conf) resolvedLogDir
  runAll ctx apps

-- GlobalContext generation: creates 4 TQueues and injects them into packages
makeGlobalContext :: LogLevel -> FilePath -> IO GlobalContext
makeGlobalContext logLevel logDir = do
  reqQ  <- newTQueueIO   -- stdin → fractal-app
  semQ  <- newTQueueIO   -- fractal-app → semantic-world
  ontQ  <- newTQueueIO   -- fractal-app → ontological-world
  resQ  <- newTQueueIO   -- any → stdout
  return GlobalContext { ... }

-- Parallel thread startup: cancels all threads if any one terminates
runAll :: GlobalContext -> [GlobalContext -> IO ()] -> IO ()
runAll ctx apps = do
  asyncs <- mapM (\f -> async (f ctx)) apps
  (_, result) <- waitAnyCatchCancel asyncs
  ...
```

Bootstrap receives the applications to start via the `apps` list, but does not know the internal implementation of each application. All Bootstrap knows is `GlobalContext` and `IO ()`. This is the type-level demonstration of CPA's Retro-dependency Principle (the Boot layer does not know of upper layers).

Paper §8.6 "Type-Level Proof of the Retro-dependency Principle" shows the asymmetry of `run` via `runReaderT` / `runState`, and this `run :: ArgData -> [GlobalContext -> IO ()] -> IO ()` type signature is a concrete implementation example of that. The type `[GlobalContext -> IO ()]` that Bootstrap receives functions as evidence that the Retro-dependency Principle — "Bootstrap does not know what each application does (does not reference the Interface)" — is enforced at the type level.

---

### B.5.9 Thread Composition and Overall Picture of TQueue Messaging

This system runs five threads in parallel:

```
┌────────────────────────────────────────────────────────────────┐
│  cpa-bootstrap (main thread)                                   │
│  Generates GlobalContext (4 TQueues), launches 5 threads via   │
│  withAsync. Monitors all threads via waitAnyCatchCancel.       │
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

TQueue flow:

```
stdin
  ↓ (readLine)
cpa-request.src
  ↓ pipeline
requestQueue ← Request (enqueue)
  ↓ (dequeue)
cpa-fractal-app (parsing and routing)
  ↓ MsgAttacked / MsgHeal / MsgMagicalCalamity / MsgQuit
semanticQueue or ontologicalQueue ← Message (enqueue)
  ↓ (dequeue)
cpa-*-world.src
  ↓ pipeline (action execution)
responseQueue ← Response (enqueue)
  ↓ (dequeue)
cpa-response.src
  ↓ pipeline
stdout
```

---

### B.5.10 The Essence of Fractal Nature and Design Consistency

#### The Essence of Fractal Nature: Self-similar Recursion of Layer Composition

The essence of fractal nature in `cpa-fractal` is that **CPA's five-layer composition (CoreModel → ProjectedContext → ApplicationBase → Interface → Boot) appears as an autonomous structure both in the entire system (macro) and within each world package's interior (micro)**.

Looking at the entire system, we have a five-layer composition with Boot = `cpa-bootstrap`, Interface = `cpa-request`/`cpa-response`, ApplicationBase = `cpa-fractal-app`, ProjectedContext = `cpa-semantic-world`/`cpa-ontological-world`, and CoreModel = `cpa-multiverse`. On the other hand, looking at the interior of `cpa-semantic-world`, which occupies the ProjectedContext layer, the same structure appears there too: Boot (bootstrap handles startup), Interface (TQueue contact point), ApplicationBase (AppState management), ProjectedContext (processing pipeline), and CoreModel (Avatar/Message).

This property — "parts have the same structure as the whole" — is the fractal. The more packages there are, or the larger the system scale, the more scales at which this five-layer structure will appear repeatedly.

#### Design Consistency Brought About by Fractal Structure

As a result of fractal nature being established, the following design consistency appears throughout `cpa-fractal`. These are not the definition of fractal itself, but properties naturally derived from fractal structure.

**Commonality of the pipeline pattern**

The pipeline pattern `src .| work .| sink` is used in common across all packages for input, output, and each world. Types differ but the structure is identical. This reflects the fact that each package has the same role of "receiving input, transforming it, and producing output," and corresponds to each unit at each scale in a fractal structure exhibiting the same behavior.

**Commonality of the state pattern**

The state pattern via GADTs and existential quantification (`WorldStateW`) is used in common across all packages. As a result of each package having an autonomous ApplicationBase, state management implementations take a common form.

**Thorough adherence to the Retro-dependency Principle**

CPA's Retro-dependency Principle (upper layers do not know of lower layers) holds both in the overall composition and within each world. The type-level constraint that Bootstrap knows only `[GlobalContext -> IO ()]` shows that this dependency principle is repeatedly enforced at each scale of the fractal structure.

---

### B.5.11 Operational Verification of `cpa-fractal`

```bash
cd cpa-fractal && cpa-bootstrap.exe -y ./cpa-fractal.yaml

# When the prompt appears, enter commands
>> attacked 10      # HP 100 → 90 (processed in semantic world)
>> heal             # HP 90 → 95, MP 50 → 40
>> calamity         # Reincarnation: Avatar moves from semantic-world to ontological-world
                    # AppState: SemanticState → OntologicalState
>> attacked 20      # HP 95 → 75 (processed in ontological world)
>> calamity         # Return: Avatar moves from ontological-world to semantic-world
                    # AppState: OntologicalState → SemanticState
>> quit             # All threads terminate
```

Before and after executing the `calamity` command, Avatar processing moves between the semantic world and the ontological world. From the user's perspective, Avatar continuity (hp and mp values) is maintained, and the change in "which world it is in" — the mode of existence — is handled transparently. This is the essential behavior of this application: "a single Avatar traversing through a fractal structure."
