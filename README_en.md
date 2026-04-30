# Core Projection Architecture (CPA)
## — A Theory of Structural Design Based on the Discovery of Existence and Contextual Projection, with Retro-dependency —

**Version:** 1.0.0  
**Authors:** Aska Lanclaude, neko  
**Date:** 2026-01-01  

---

## Abstract

In software structural theory, two questions have long been treated independently. The first is the ontological question: "Why does a structural center exist?" The second is the question of structural constraint: "Why are dependencies constrained to be inward-facing?" The former has been discussed in the context of conceptual modeling, while the latter has been presented as a design convention. However, no framework has been sufficiently presented to derive both simultaneously from a single theoretical foundation.

This paper proposes **Core Projection Architecture (CPA)** to fill this theoretical gap. The central thesis of CPA is as follows:

> *The Core is something to be discovered, and the discovered Core manifests in the external world as a contextual projection. Dependencies trace back against this direction of manifestation. This is the basis for structural constraints.*

This thesis encompasses three principles. First, the structural center (Core) is not arbitrarily constructed by the designer, but is an underlying structure discovered as the essence of the domain or as the operational characteristics of the execution world. Second, the discovered Core is constrained by a specific purpose, requirement, or context, and a projection of it appears in the external world as a projected image. Third, dependency relationships trace back against the causal direction of this manifestation. A projection cannot exist without its source, but the source does not depend on the projection. This structural asymmetry is defined as the **Retro-dependency Principle**.

This paper further formalizes the influence that the ontological nature of the execution substrate has on the purity of the Core as **Ontological Erosion**, presenting two categories: Logical Configuration and Ontological Configuration. Ontological Erosion is further analyzed in two forms: **Outside-in Erosion**, where the execution substrate exerts influence by wrapping the outside of the Core, and **Inside-out Erosion**, where the operational characteristics of the execution world become mixed into the definition of the Core itself. Additionally, through formalization using computational contexts, it is shown that the Retro-dependency Principle can be expressed as a type structure.

CPA is a theoretical system that transforms dependency constraints from heuristics into a necessity of structural manifestation. By reconceiving a system not as a "construction" assembled arbitrarily by a designer, but as a "manifestation process" in which discovered structures emerge into the external world, it repositions the basis for design decisions from conventions to structural necessity.

---

## Chapter 1: Introduction

### 1.1 The Problem

In software structural design, the constraint of "keeping dependencies inward" is widely accepted. This is an asymmetric dependency relationship in which outer components may reference inner ones, but inner components must not reference outer ones. This principle has been justified by practical benefits such as resilience to change and ease of testing. However, these are enumerations of consequences that the structure brings about, and they do not theoretically derive the necessity of the dependency direction itself. When stated as a convention, it remains a normative statement of "one should design this way," lacking the structural basis for "why it must be so."

On the other hand, the idea of discovering central concepts in structural design and building a system on that foundation is also widely shared. However, the theory of how a discovered central structure manifests itself in the external world, and why it must be placed at the center, has not been sufficiently presented. The "existence of a center" and the "direction of dependencies" have been treated as separate problems.

This division becomes apparent especially in environments where the execution substrate has strong ontological constraints. When the physical or institutional conditions of the execution environment influence the conceptual structure, the purity of the central structure and implementation requirements conflict, creating a divergence between theory and practice. This phenomenon is often understood as a design deviation, but in reality, the structural theory itself may not sufficiently explain the manifestation process.

This research hypothesizes that the root of these problems lies in the absence of a manifestation theory — one that addresses "how does structure manifest itself in the external world?" The centrality of structure and the directionality of dependencies can only be derived from a single proposition through this manifestation theory.

---

### 1.2 Research Objectives and the Three Principles of the Theory

The purpose of this paper is to present CPA as a theory that derives structural centrality and dependency constraints from a single proposition.

CPA reconceives a system not as a "construction" assembled arbitrarily by a designer, but as a "manifestation process" in which discovered structures emerge into the external world. Through this epistemological shift, dependency constraints are redefined from design manners to the causal consequences of structural manifestation.

This theory consists of the following three principles:

**Discovery Principle**
The structural center (Core) is not something constructed by the designer, but something discovered as the essence of the domain or as the operational characteristics of the execution world. The discovery of the Core is an act of recognition, and the Core exists potentially before that act.

**Projection Principle**
The discovered Core is a multidimensional structure in itself and does not appear in the external world in its original form. When a particular purpose, requirement, or constraint — that is, context — is applied to it, a specific projection is extracted and appears at the boundary called Interface.

**Retro-dependency Principle**
Against the manifestation process of "Core → Projected Context → Interface," the arrow of dependency traces the reverse direction. A projection cannot exist without its source, but the source does not depend on the projection. From this structural asymmetry, the dependency constraint is derived as a necessity.

---

### 1.3 Contributions of This Research

The main contributions of this paper are as follows:

**(1) Ontological Redefinition of Structural Centrality**
The Core is positioned not as an arbitrary construct but as a discovery target, providing a theoretical basis for the centrality of structure.

**(2) Establishing Dependency Direction as a Structural Necessity**
Dependency constraints are derived as the reverse of the manifestation structure, transforming them from design norms to structural necessity.

**(3) Formalization of Ontological Erosion**
The influence of the ontological nature of the execution substrate on the purity of the Core is analyzed, and the scope of the theory's application is organized into two categories: Logical Configuration and Ontological Configuration.

Note that this paper uses the binary opposition of "Logical Configuration" and "Ontological Configuration" as its central axis. The former refers, as an extension of denotational semantics in programming language theory, to an abstract computational structure independent of execution mode. The latter, as an adaptation of philosophical ontology, refers to a state in which the execution substrate itself defines the conditions of existence for the Core. The two form an axis of opposition between "abstract form" and "concrete conditions of existence" in the context of design theory.

"Logical Configuration" is also referred to as Semantic Configuration. This alternative name derives from "semantics" in programming language theory — that is, the description of the meaning of computation independent of execution mode — and both terms refer to the same concept. In the formalization code in Appendix B, the project name `cpa-semantic` corresponds to this.

**(4) Presentation of Formal Support**
Through abstraction using computational contexts, it is shown that the Retro-dependency Principle can be expressed as a type structure. The details of the formalization are included in Chapter 8 and Appendix B.

---

### 1.4 Structure of the Paper

Chapter 2 organizes the theoretical premises: the discoverability of structure, the dual nature of the execution world, and the concept of projection. Chapter 3 presents the Core Projection hypothesis and defines the three concepts of Core, projection, and the Retro-dependency Principle. Chapter 4 constructs the axiom system, providing the foundation for subsequent logical development. Chapter 5 derives logical consequences from the axioms. Chapter 6 defines the layer composition and organizes the meanings of both upward and downward directions. Chapter 7 categorizes the types of execution worlds and analyzes Ontological Erosion. Chapter 8 provides formal support through modeling with computational contexts. Chapter 9 conducts an evaluation, and Chapter 10 presents the conclusion.

---

## Chapter 2: Theoretical Premises — Discovery of Existence, Duality of the Execution World, and Introduction of Projection

### 2.1 Discoverability of Structure

The fundamental question in software structural design is "how is structure determined?" In dominant practice, structure has been treated as a construction assembled by a designer based on requirements. However, this paper takes a different stance.

**The structural center (Core) is not constructed but discovered.**

A coherent conceptual order exists latently in the business domain prior to any design act. For example, the relationship "an order must always be linked to products, quantities, and a customer" exists as a business reality before it is modeled. The designer's role is not to generate this order but to remove noise and articulate the latent structure.

Similarly, specific execution worlds — game engines, distributed protocols, physical control systems — inherently possess the operational characteristics that that world presupposes. The designer does not create those characteristics themselves but recognizes them and extracts them as the Core.

This stance is called **Core Discoverability**.

An important consequence of Core Discoverability is that the existence of the Core does not depend on the designer's intent. The accuracy of discovery — that is, how purely the nucleus can be extracted by removing noise — depends on the designer's skill. However, the object of discovery itself exists regardless of whether the designer is present.

---

### 2.2 Logical Existence and Ontological Existence

When the Core is discovered, its nature divides into two types based on its origin. This distinction forms the foundation for understanding "Ontological Erosion" described later.

Note that "Logical" as used in this section refers to the extended usage of denotational semantics in programming language theory — that is, "an abstract computational structure independent of execution mode." Meaning (Semantics) first emerges through the contextualization of projection, and the Core itself is a pure form prior to projection. This paper adopts "Logical Existence" as a term expressing that formal purity.

#### 2.2.1 Logical Existence

This is existence corresponding to pure business logic, mathematical structures, and computational rules.

The essential characteristic of Logical Existence is its stability against changes in the execution environment. For example, the rule "the total price of an order is the sum of the prices of each line item" does not change whether it is implemented as a web service, a CLI tool, or recorded in a text file.

In this case, the Core can maintain conceptual purity. The execution environment is located outside the Core and does not exert structural influence on the Core.

#### 2.2.2 Ontological Existence

This is existence corresponding to the mode of being defined by the execution world itself. Spatial coordinates, time steps, physical laws, concurrency models, consensus formation across networks — these are existential conditions that define "what it means to exist" in a particular world, and cannot be ignored as long as the designer operates within that world.

For example, a Unity game object has position, rotation, and scale in three-dimensional space as its mode of being. This is not business logic but the ontological condition of that world. This condition cannot be separated from the definition of the Core.

In this case, the Core is discovered in a form that includes the operational characteristics of the execution world. This phenomenon is the cause of "Ontological Erosion" formalized in Chapter 5.

---

### 2.3 Two Categories of Execution Substrate

The difference in the nature of the discovered Core corresponds to the nature of the execution substrate that contains it. The execution substrate behaves in two fundamentally different ways toward structure.

#### 2.3.1 Delivery-type

This is a medium for delivering to the external world results computed by the Core.

A web framework transmits the Core's output in the form of HTTP, but does not determine what the Core should compute. A Delivery-type execution substrate can be removed while the Core's semantic integrity is maintained — only the connection to the external world is lost.

In this category, the Core can maintain conceptual purity. The execution substrate is a layer that covers the outside of the Core and does not exert structural influence on the Core's definition.

#### 2.3.2 Foundational-type

This is a substrate that defines the conditions under which the Core can exist only in that world.

A game engine defines the very laws of the world in which game objects exist. A blockchain defines the mode of being of distributed state consensus formation. Removing these substrates is equivalent to erasing the conditions of existence of the Core.

In this category, the Core is discovered in a state that encompasses the operational characteristics of the execution substrate.

---

### 2.4 Introduction of the Projection Concept

The Core is a multidimensional space of possibility. It is in itself a unified structure with potential projections for all contexts. However, the external world always has a specific purpose and poses specific questions to the Core.

"Tell me the total price of this order." "Confirm this order." "List all unshipped orders." — Each demands a different projection of the Core.

This operation — applying a specific context (purpose, requirement, constraint) to the Core and extracting a consistent slice from its space of possibilities — is defined as **Projection**.

There is an essential constraint on the operation of projection:

> **Projection only limits the space of possibilities of the Core; it does not add new structure to the Core.**

This is called the **Projection Constraint**.

The Projection Constraint is also a fundamental critique of the tendency for UseCases or functional units to be designed as independent entities. A UseCase is not an independent layer defined outside the Core, but a projection of the Core under a specific context — that is, a **Projected Context**.

If a Projected Context has a structure that does not exist in the Core, that is an error in projection and indicates that the discovery of the Core is insufficient.

---

### 2.5 Separation of Structure and Execution

As a conclusion to this chapter, an important orthogonality in structural theory is confirmed.

**Structure and Execution are independent concerns.**

Structure is the definition of responsibilities and the system of dependency relationships. Execution is the arrangement policy of computational resources such as threads, processes, and services.

The boundary of layers and the boundary of parallelization need not coincide. There is theoretically no problem with a single process traversing multiple layers. Conversely, even in a system divided into microservices, the same structural principle holds within each service.

This principle of separation is formalized as the **Execution Independence Axiom** in Chapter 4.

---

## Chapter 3: The Mechanism of Manifestation — The Core Projection Hypothesis

### 3.1 The Central Thesis

The three premises organized in Chapter 2 — Core Discoverability, the dual nature of the execution world, and the concept of projection — converge into a single proposition:

> **The Core is something to be discovered, and the discovered Core manifests in the external world as a contextual projection. Dependencies trace back against this direction of manifestation. This is the basis for structural constraints.**

This proposition integrates ontology, manifestation theory, and structural constraint theory. The three concepts that constitute this proposition are defined in order below.

---

### 3.2 Formalization of the Manifestation Process

The process by which the Core emerges into the external world is called **Manifestation**. Manifestation is formalized as the following causal sequence:

```
Core (Existence Layer)
  ↓  [Application of Context]
Projected Context (Projection Layer)
  ↓  [Formation of Projection]
Interface (Phenomenon Layer)
```

The definitions of each layer are as follows:

**Core (Existence Layer)**
The discovered structural center. A multidimensional space of possibility that exists as pure structure prior to any context.

**Projected Context (Projection Layer)**
A slice extracted from the Core by a specific purpose, requirement, or constraint. It is a partial mapping of the Core and does not hold structure beyond the Core.

**Interface (Phenomenon Layer)**
The boundary with the external world and the point at which manifestation is realized. Side effects — communication, persistence, rendering — occur here. The Interface has no independent substance and exists only as a projection of the Core under context.

---

### 3.3 Structural Positioning of Projected Context

The Projected Context is not an independent logical unit.

This has an important implication for design practice. In general design, a UseCase layer or Application layer is often designed as "a layer with independent responsibilities separate from the Core." However, from the CPA perspective, the existence of such "independent UseCases" is inconsistent with the projection model.

A UseCase is a projection of the Core under a specific context and cannot have a structure independent of the Core's exterior. If a UseCase references or holds concepts that do not exist in the Core, either the discovery of the Core is insufficient or the boundary of projection is incorrect.

---

### 3.4 The Role of Interface and Attribution of Side Effects

The Interface is the terminal of manifestation, the only layer where phenomena occur.

The responsibility for executing side effects — writing to external systems, saving to persistence layers, displaying to users — is attributed to the Interface layer. The Core and Projected Context can **describe** side effects (that is, express "what should be executed" as types), but the responsibility for their execution belongs to the Interface.

This design guarantees the purity of the Core and Projected Context. Purity is the property of "always returning the same output for the same input," which is the basis for testability, reasoning capability, and reusability.

---

### 3.5 The Retro-dependency Principle

Dependency is defined as "requiring the existence of another element for a given element to be established."

The causal sequence of manifestation is in the following direction:

```
Core  →  Projected Context  →  Interface
```

A projection cannot exist without its source. The Interface cannot be realized without presupposing the Projected Context. The Projected Context cannot have a meaningful slice without presupposing the Core. Therefore, the arrow of dependency traces back against this causality in reverse.

```
Interface  →  Projected Context  →  Core
```

On the other hand, the source need not know how the projection is formed. The Core does not reference how it appears as an Interface. This asymmetry is the basis for the dependency constraint.

This principle is defined as the **Retro-dependency Principle**.

The significance of the Retro-dependency Principle lies in liberating dependency constraints from heuristics. The design convention "the Core must not reference the outer layers" has hitherto been justified by practical benefits such as resilience to change and ease of testing. However, these are merely enumerations of consequences. The Retro-dependency Principle derives the dependency constraint as a necessity from the causal structure of manifestation.

---

## Chapter 4: The Axiom System

To establish the hypothesis of Chapter 3 as a formal foundation, the following axioms are set. These axioms are mutually independent, and by combining them, all propositions of CPA are derived.

---

### Axiom 1: Core Discoverability Axiom

> The structural center (Core) exists latently in the target world prior to the act of design. The designer does not generate it but discovers it.

This axiom provides an ontological basis for the centrality of structure. Since the Core is an object of recognition rather than an arbitrary design decision, its validity is judged not by the designer's intent but by the accuracy of discovery.

---

### Axiom 2: Projection Constraint Axiom

> Projection is an operation that limits the space of possibilities of the Core and does not add new structure to the Core.

This axiom defines the nature of the Projected Context. The Projected Context is a projection of the Core and cannot hold structure beyond the Core. Therefore, for an independent UseCase layer to define concepts that do not exist in the Core violates this axiom.

---

### Axiom 3: Retro-dependency Axiom

> Dependencies are only permitted in the direction opposite to the direction of manifestation. There are no dependencies that follow the direction from Core to Interface.

This axiom is the formal basis for dependency constraints. The constraints "the Core does not reference the Interface" and "the Projected Context does not reference the Interface" are derived as direct consequences of this axiom.

---

### Axiom 4: Execution Independence Axiom

> Execution units (Thread / Process / Service) are not determinants of layer structure. Structure is a system of layer responsibilities, and execution is an arrangement policy of computational resources. Both are separated as independent concerns.

This axiom guarantees that the choice of execution strategies such as microservicing, concurrent processing, and distributed processing does not require changes to the layer structure.

---

### Axiom 5: Fractal Recursion Axiom

> The Core Projection structure holds recursively at any scale. That is, the causal sequence of manifestation — Core, Projected Context, and Interface — is applicable as the same principle both throughout the entire system and within a single component.

This axiom defines the scope of CPA's application. The same structural principle can be applied repeatedly from large-scale system design down to function-level design.

Note that Chapter 6 develops this causal sequence as a four-layer structure with the addition of Application Base (control layer). The Application Base is a control mechanism that brings the projection down to the execution context and is positioned between the Projected Context and the Interface as a layer that necessarily accompanies the causal sequence of manifestation. The reason Axiom 5 is described as "three layers" is a shorthand inherited from the central thesis of Chapter 3 (Core → Projected Context → Interface), which is concretized as four layers (and further as five layers with the addition of a Boot layer responsible for startup control) in implementation.

---

## Chapter 5: Logical Consequences and Analysis of Ontological Erosion

### 5.1 Establishing Inward Dependency as a Structural Necessity

From Axiom 3 (Retro-dependency Axiom), dependencies are only permitted in the direction opposite to the direction of manifestation.

Since the direction of manifestation is `Core → Projected Context → Interface`, the permitted direction of dependency is limited to `Interface → Projected Context → Core`. Both the Core referencing the Projected Context and the Projected Context referencing the Interface violate Axiom 3.

**The constraint of "keeping dependencies inward" is not a design convention but a consequence of Axiom 3.**

This fundamentally changes the logical status of the dependency constraint. When stated as a convention, the constraint remains a norm of "it is recommended to follow it," and deviation may be tolerated as a design judgment. However, when stated as an axiomatic consequence, deviation is defined as the destruction of the manifestation structure — that is, a system in which the Core references the Interface is a system in which manifestation, in the CPA sense, has not been established.

---

### 5.2 Non-Identity of Layer Boundaries and Parallel Boundaries

From Axiom 4 (Execution Independence Axiom), the boundary of layers and the boundary of execution should be determined independently as separate problems.

This consequence has important implications in practice. The decision to divide (or integrate) services does not entail redefining layer responsibilities. It is structurally equivalent whether a single process traverses all three layers of Core, Projected Context, and Interface, or whether the three layers are divided into three microservices.

In flawed design, execution boundaries and layer boundaries are confused in the form of "this service is the Application Layer" or "this service is the Infrastructure Layer." This confusion leads to the ambiguity of layer responsibilities and the erosion of dependency constraints.

---

### 5.3 Formalization of Ontological Erosion

**Definition:** The phenomenon in which the operational characteristics of the execution substrate influence the definition of the Core Model is defined as **Ontological Erosion**.

Erosion is not a design failure. It is a necessary consequence of the nature of the discovered structure — specifically the essential consequence of the type called Ontological Existence. In execution environments of the Foundational-type, the Core has no choice but to be discovered with the operational characteristics of that world as a premise. The Core of a game running on a game engine cannot ignore the ontological condition of three-dimensional space.

Erosion is organized into two categories:

#### 5.3.1 Outside-in Erosion

This is erosion that occurs with a Delivery-type execution substrate.

The execution substrate covers the outside of the Core and defines the format of input and output, but does not get involved in the definitions within the Core. The concepts handled by the Core do not depend on the operational characteristics of the execution substrate. The influence of erosion stays within the Interface and Application Base, and the definition of the Core Model is established independently of the execution world.

At the type level, this is observed as a form in which the computational context representing the execution world does not appear in the stack.

```haskell
-- Conceptual representation of Logical Configuration (Outside-in)
-- Shows a form where the computational context of the execution world is not included in the stack
type ProjectedContext a = ReaderT Context (State AppState) a
```

> **Note:** The above is a conceptual code example showing the structural essence of Outside-in Erosion. In actual Logical Configuration, implementations that include IO in the Application Base stack are standard for input/output with the outside. For example, in the `cpa-semantic` implementation in Appendix B, the form includes IO as `ReaderT GlobalConfig (StateT ContextualState IO) a`, which is a typical example of the classification "IO wraps the outside of the Core (Outside-in)." The presence of IO is not evidence of Outside-in Erosion; rather, the essence of Outside-in is that IO is a structure that wraps the **outside** of the stack.

#### 5.3.2 Inside-out Erosion

This is erosion that occurs in execution environments of the Foundational-type.

The operational characteristics of the execution substrate — space, time, lifecycle, physical laws — become mixed into the Core's definition itself. The Core can only exist in that execution world, and if the world is removed, the concept of the Core also ceases to hold. This is not a design failure but a necessary consequence of existing in that execution world.

At the type level, this is observed as a form in which the computational context representing the execution world appears inside the stack.

```haskell
-- Ontological Configuration (Inside-out)
-- UnityMonad is the computational context of the Unity execution world (internally contains IO)
type ProjectedContext a = ReaderT UnityWorld (StateT GameState Unity) a
--                                                              ↑
--                        Computational context of execution world appears here = type-level evidence of Inside-out Erosion
```

The essential difference from Outside-in is not whether IO is on the **outside** or **inside** of the stack, but whether a type representing the execution world (such as Unity) is incorporated as an inseparable condition of existence from the Core's definition. In Appendix B's `cpa-ontological`, the implementation that abstracts the execution world as the `World m` type class functions as type-level evidence of this Inside-out Erosion (see Appendix B.2, B.3).

---

### 5.4 Application Conditions of the Projection Principle and its Relationship to Erosion

The type of erosion changes the application conditions of the projection principle.

In Outside-in Erosion, projection is established as an operation that limits the Core's pure space of possibilities with context. The Projection Constraint Axiom applies in its complete form.

In Inside-out Erosion, the ontology of the execution world has become mixed into the Core's space of possibilities itself. Projection is performed on a space that presupposes that mixture. The Projection Constraint Axiom still holds — the Projected Context does not add structure beyond the Core — however, since the Core's own purity is limited, the projection also inherits that limitation.

**Erosion is not the invalidation of the projection principle but the transformation of the space in which projection takes place.**

---

### 5.5 Conditions for Structural Stability

From the above analysis, the necessary and sufficient conditions for a system to be structurally stable are organized as follows:

**Condition 1: The Core is correctly discovered**
Noise is removed, and the latent order of the target world is appropriately articulated as the Core. A failure of discovery appears as a state in which the designer's intent has become mixed into the Core.

**Condition 2: The Projected Context satisfies the Projection Constraint**
The Projected Context is defined as a projection of the Core and does not independently hold structure that does not exist in the Core. A violation of the Projection Constraint often appears in the form of the UseCase layer holding independent domain knowledge.

**Condition 3: Dependencies follow the Retro-dependency Principle**
The arrow of dependency is consistently in the reverse direction of manifestation. The introduction of reverse dependencies appears as the Core referencing the Interface, or the Projected Context knowing the details of execution.

When any condition breaks down, the structure becomes unstable. A breakdown of Condition 1 is recovered by re-discovering the Core. A breakdown of Conditions 2 and 3 is recovered by refactoring. However, attempting to maintain Conditions 2 and 3 while Condition 1 remains broken is building an elaborate structure on an incorrect Core, ultimately requiring redesign of the entire system.

This asymmetry is also the reason why the Core Discoverability Axiom is placed at the logical starting point of the axiom system.

---

## Chapter 6: Layer Composition — Spatial Formalization of the Manifestation Structure

### 6.1 Principles of Layer Naming

The layers in CPA are not defined based on implementation conventions or historical terms from existing architectural theories.

The vocabulary used in existing architectural theories — Domain, Application, Infrastructure, UseCase — each carries semantic weight specific to its cultural context and implies connotations independent of CPA's structural concepts. Borrowing this vocabulary risks introducing preconceptions derived from existing design cultures into the reader of the theory.

CPA's layers are defined in correspondence with the **causal sequence of manifestation**. The manifestation sequence is the following causal chain:

```
Core Model  →  Projected Context  →  Application Base  →  Interface
(Root Layer)     (Projection Layer)    (Control Layer)      (Phenomenon Layer)
```

This sequence is "the path by which underlying structure reaches phenomenon," and the layer composition is the spatial expression of this path. The change in naming is not a replacement of words but a redefinition of concepts.

---

### 6.2 Definition of the Four Layers

CPA defines the layer composition with the following four layers:

```
┌──────────────────────────────┐
│          Interface           │  ← Phenomenon Layer: Boundary with the external world where projections are realized
├──────────────────────────────┤
│       Application Base       │  ← Control Layer: Mechanism that brings projection down to execution context
├──────────────────────────────┤
│      Projected Context       │  ← Projection Layer: Contextual projection of the Core
├──────────────────────────────┤
│         Core Model           │  ← Root Layer: Discovered structure
└──────────────────────────────┘
```

Each layer is stacked according to the direction of dependency. Upper layers depend on lower layers. Lower layers do not know of upper layers. This asymmetry is the spatial expression of the Retro-dependency Principle.

---

### 6.3 Definition of Each Layer

#### 6.3.1 Core Model (Root Layer)

**Definition:** The formalization of the discovered structure.

The Core Model is the layer that describes "what exists." It holds type definitions, invariants, and the relational structure of concepts, forming the most stable nucleus of the system. The definition of procedures — "what to do" — belongs to the Projected Context.

The Core Model does not reference upper layers. In Logical Configuration, it is expressed as pure types. In Ontological Configuration, it is discovered in a form that encompasses the operational characteristics of the execution world; but in either configuration, the Core Model does not know of the existence of layers above itself.

#### 6.3.2 Projected Context (Projection Layer)

**Definition:** A projection of the Core under a specific context.

When a specific purpose, requirement, or constraint is applied to the Core Model, a specific slice is extracted from its space of possibilities. This slice is the Projected Context.

The Projected Context is a partial mapping of the Core Model (Projection Constraint Axiom) and does not independently hold structure that does not exist in the Core Model. A so-called UseCase is merely an external label for this layer. Its essence is "a projection of the Core under context," not a self-contained chunk of business logic.

The Projected Context can hold descriptions of side effects (Effects), but their execution is delegated to the Interface. CPA does not require the Projected Context to be pure. The purity of the Projected Context depends on the results of the erosion analysis — in Logical Configuration it can be defined as pure computation, and in Ontological Configuration it takes a form that includes the computational context of the execution world. In either case, the dependency constraint that the Projected Context does not reference the Interface does not change.

#### 6.3.3 Application Base (Control Layer)

**Definition:** The control mechanism that brings projection down to the execution context.

The Application Base is the layer that "executes" the computation described by the Projected Context. Formally speaking, it bears the responsibility of running the monad stack that is the Projected Context and bringing the result of computation down to the execution world. The description of business meaning belongs to the Projected Context, and the Application Base functions as a control mechanism that receives that description and connects it to execution.

The main responsibilities of the Application Base are as follows:

- Execution (run) of the computational context
- State transition management and lifecycle management
- Determination of transaction boundaries
- Logging, configuration, and dependency injection

The structure of the state transitions managed by the Application Base is formalized by the following expression:

```
State × Event → (State, Effect)
```

Here, State is the operational state of the system (initialization, operating, stopped, etc.), and Effect is the description of side effects. The execution of Effect is delegated to the Interface.

#### 6.3.4 Interface (Phenomenon Layer)

**Definition:** The point of side effect execution and the boundary with the external world.

This is the terminal of manifestation, the surface at which the structure called Core is realized as a projection in the external world. Communication, persistence, rendering, and external API integration are all executed in the Interface.

The Interface is a projection, not a substance. Even if the implementation of the Interface changes, the definition of the Core Model does not change. The Interface has the responsibility of receiving the Effect described by the Projected Context and executing it as a concrete side effect. The Core Model does not know of the Interface.

---

### 6.4 Bidirectional Structure

The four layers of CPA simultaneously contain two directions. This simultaneous presence of two directions is the structural core of CPA.

**Manifestation Direction (Upward):** The direction from Core to Interface. The direction in which meaning is concretized and projections are realized.

```
Core Model  →  Projected Context  →  Application Base  →  Interface
```

**Dependency Direction (Downward):** The direction from Interface to Core. The direction that traces back the conditions for establishment, and is the spatial expression of the Retro-dependency Axiom.

```
Interface  →  Application Base  →  Projected Context  →  Core Model
```

Upward manifestation begins with the discovery of the Core. The discovered Core is projected by context, brought down to execution by the control layer, and realized as a phenomenon in the external world. Downward dependency is the condition for not distorting this manifestation. Maintaining dependencies is maintaining manifestation.

---

### 6.5 Independence of Layers and Execution Units

A layer boundary is a boundary of responsibilities. An execution unit (Thread / Process / Service) is a boundary of computational resources. Both are independent concerns (Execution Independence Axiom).

- A single thread traversing all four layers poses no problem
- Separating each layer into a separate process is also structurally equivalent
- Parallelization and distribution are execution strategies determined at the system boundary and do not require changes to layer responsibilities

---

### 6.6 Fractal Recursiveness

By the Fractal Recursion Axiom (Axiom 5), the four-layer structure holds recursively at any scale. The same structural principle is applicable at the level of the entire system, subsystems, or individual modules.

However, recursive application is justified only when it corresponds to the structure discovered at that scale. Structuring for the sake of structure violates the Discoverability Axiom (Axiom 1).

---

## Chapter 7: Types of Execution Worlds and Erosion Theory

### 7.1 Definition and Positioning of Erosion

**Definition:** The phenomenon in which the operational characteristics of the execution world influence the definition of the Core Model is called **Ontological Erosion**.

Erosion is not a design failure. Erosion is a necessary consequence derived from the nature of the discovered structure.

Erosion analysis is the starting question of design. The answer to the question "In this execution world, what kind of structure is the Core discovered as?" determines the subsequent design policy.

---

### 7.2 Judgment Procedure for Erosion Analysis

**First question: If the execution substrate is removed, do the concepts of the Core Model still hold?**

Yes → The execution substrate is Delivery-type. Adopt **Logical Configuration**.

No → The execution substrate is Foundational-type. Adopt **Ontological Configuration**.

**Second question (in the case of Ontological Configuration): How far does the erosion extend?**

By identifying the extent of erosion, the design policy for each layer is determined.

---

### 7.3 Logical Configuration

This is a configuration in which the execution substrate functions as a Delivery-type and the Core Model is established independently of the operational characteristics of the execution world.

Even if the execution substrate is changed or removed, the essence of the Core Model does not change. The influence of the execution substrate is absorbed in the Interface and Application Base and does not become mixed into the Core Model's definition.

Typical examples include web applications, MCP servers, CLI tools, and batch processing. HTTP protocols and JSON-RPC are "delivery devices" and are not involved in defining business concepts. Even if communication disappears, concepts such as "order," "contract," and "calculation" persist.

---

### 7.4 Ontological Configuration

This is a configuration in which the execution substrate functions as a Foundational-type and the Core Model is discovered in a form that encompasses the operational characteristics of the execution world.

Removing the execution substrate is equivalent to erasing the conditions of existence of the Core Model. The inclusion of spatial coordinates, time steps, physical laws, and lifecycles in the Core Model's definition is a necessary consequence of existing in that world.

Typical examples include systems on game engines (Unity, Unreal). In Unity, `GameObject` is the unit of existence, `Transform` is the definition of space, and `Time` is the definition of time. These do not "wrap" the outside of the Core Model; they "define" from the inside what the Core Model is.

---

### 7.5 Two Types of Erosion

#### Outside-in Erosion

This is erosion caused by a Delivery-type execution substrate. The influence of the execution substrate is absorbed on the outside of the Core Model. The Core Model's definition is established independently of the execution world.

"Outside-in" expresses that the execution substrate exerts influence in the form of wrapping the outside of the Core Model. The Core Model is wrapped but has not been penetrated internally.

#### Inside-out Erosion

This is erosion caused by an execution environment of the Foundational-type. The operational characteristics of the execution world become mixed into the Core Model's definition itself, and the Core Model is discovered in a form that encompasses the execution substrate.

"Inside-out" expresses that the constraints of the execution substrate exert influence in the form of being included inside the Core Model.

---

### 7.6 Independence of Erosion and Dependency Direction

The most important proposition regarding erosion is stated explicitly:

> **Erosion does not change the direction of dependency. Erosion only changes the nature of the space in which dependency occurs.**

Even if the Core Model encompasses the operational characteristics of the execution world in Ontological Configuration, the direction of dependency does not change. It is not permitted for the Interface to reference the Core Model independently of this, and the Core Model is prohibited from referencing the Interface.

A system that has adopted Ontological Configuration may arrive at the conclusion that "since it depends on the execution substrate anyway, the dependency direction is meaningless." However, accepting erosion is not abandoning the Retro-dependency Principle. Erosion is only acceptable when it derives from the nature of the discovered structure, and it does not justify reversing the direction of dependency for design convenience.

---

### 7.7 Relationship with Existing Architectural Theories

CPA does not deny existing architectural theories. CPA explains why those theories have been functioning appropriately only in "Logical Configuration," and is positioned as an extended theory for applying consistent principles even in "Ontological Configuration."

Existing architectural theories that emphasize conceptual purity as a principle are entirely valid in Logical Configuration — in environments where the execution substrate is Delivery-type, the Core should and can be kept pure.

However, these theories have not presented sufficient prescriptions for Ontological Configuration, where conceptual purity is principally unachievable. The norm of "it should be pure if possible" either unnecessarily constrains designers in Foundational-type environments or processes compromises with reality as ad hoc accommodations.

CPA resolves this problem as a problem solvable within the theory by formalizing erosion. In Ontological Configuration, the Core Model encompassing the operational characteristics of the execution world is justified as a consequence of the Discoverability Axiom. It is understood not as a design compromise but as a structural necessity.

---

## Chapter 8: Formal Support — Proof via Computational Contexts

### 8.1 Purpose of Formalization

In this chapter, the theoretical propositions of CPA developed in Chapters 3 through 7 are formalized using the concept of computational contexts.

There are two purposes of formalization. First, to show that the Retro-dependency Principle can be expressed at the type level and mechanically enforced by the type system. Second, to show that Ontological Erosion is observable as a change in type signatures.

Haskell is used as the formalization language. Because Haskell's type system has the property of explicitly tracking computational contexts as types, it is suitable for directly expressing CPA's propositions. However, CPA's propositions are not specific to Haskell; equivalent expressions are possible in any language that can express computational contexts as types.

---

### 8.2 Formalization of State Transitions

The state transitions managed by the Application Base are formalized in the following form:

```
State × Event → (State, Effect)
```

Effect is a description of side effects, not their execution. This separation decouples the logic of "what should be done" from the implementation of "how to execute."

In Haskell, this structure is expressed as follows:

```haskell
-- Application Base state and transition events
data AppState = Initializing | Running | Suspended | Terminating

data Event
  = StartEvent Config
  | SuspendEvent
  | ResumeEvent
  | TerminateEvent

-- Effect: description of side effects (not execution)
data Effect
  = NoEffect
  | LogEffect Text
  | NotifyEffect Text
  | ShutdownEffect

-- State transition function: defined as a pure function
transition :: AppState -> Event -> (AppState, Effect)
transition Initializing (StartEvent _)  = (Running,     LogEffect "System started")
transition Running      SuspendEvent    = (Suspended,   LogEffect "System suspended")
transition Suspended    ResumeEvent     = (Running,     LogEffect "System resumed")
transition Running      TerminateEvent  = (Terminating, ShutdownEffect)
transition state        _               = (state,       NoEffect)
```

`transition` is a pure function without IO. The execution of Effect is handled by the Interface. This structure allows state transition logic to be tested and verified without requiring an execution environment.

---

### 8.3 Execution World as Computational Context

The execution substrate is formalized as a computational context.

A computational context is a type-level description of "under what premises, environment, or state a given computation is executed." The execution substrate can be decomposed into the following three properties:

- **Environment (Reader-like property):** Read-only information that does not change throughout execution. Configuration values, constants of the execution world, etc.
- **State (State-like property):** Mutable information that may change throughout execution. Business state, game state, etc.
- **The computational context itself:** An execution context that only has meaning in that world. In Logical Configuration, it appears as an external side effect; in Ontological Configuration, it is embedded inside the computation stack.

---

### 8.4 Type Expression of Projected Context in Logical Configuration

In Logical Configuration, the Projected Context does not include the computational context of the execution world in the stack.

```haskell
-- Logical Configuration: computational context of execution world is not included in the stack
type ProjectedContext a = ReaderT Context (State AppState) a
```

This type represents "a computation that reads an environment called Context, modifies AppState, and returns a result." The computational context of the execution world does not appear in the stack.

As a concrete example, the avatar speech use case is shown:

```haskell
-- Core Model (pure type definitions independent of execution world)
data Avatar      = Avatar { avatarName :: Text, avatarState :: AvatarState }
data AvatarState = Idle | Walking | Speaking
data AvatarEvent = StartWalk | StopWalk | SpeakEvent Text

-- Pure function of Core Model
updateAvatarState :: AvatarState -> AvatarEvent -> AvatarState
updateAvatarState Idle  StartWalk      = Walking
updateAvatarState _     StopWalk       = Idle
updateAvatarState _    (SpeakEvent _)  = Speaking
updateAvatarState state _              = state

-- Projected Context (projection of the Core under the context "make avatar speak")
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

The type signature `ReaderT SpeakRequest (State AvatarStore) AvatarState` expresses the meaning of the Projected Context — "receives the context called SpeakRequest, modifies AvatarStore, and returns AvatarState" — without documentation. The type signature functions as a record of the architecture.

The Application Base `run`s this Projected Context and brings it down to the execution world:

```haskell
-- Application Base: run the Projected Context and bring it down to the execution world
runUsecaseSpeak :: SpeakRequest -> AvatarStore -> IO (AvatarState, AvatarStore)
runUsecaseSpeak req store =
  return $ runState (runReaderT usecaseSpeak req) store
```

The `run` via `runReaderT` and `runState` is performed here. The Projected Context exists as a description of computation, and the Application Base brings that description down to execution.

---

### 8.5 Observation of Ontological Erosion in Type Signatures

In Ontological Configuration, the computational context of the execution world appears in the Projected Context's stack. This is the type-level evidence of erosion.

```haskell
-- ■ Logical Configuration (Outside-in)
-- Computational context of execution world is not included in the stack
type ProjectedContext a = ReaderT Context (State AppState) a

-- ■ Ontological Configuration (Inside-out: Unity, etc.)
-- The computational context of the Unity execution world is embedded inside the stack
-- = type-level expression of Inside-out Erosion
type ProjectedContext a = ReaderT UnityWorld (StateT GameState Unity) a
--                                                              ↑
--                        Computational context of execution world appears here = evidence of erosion
```

`Unity` is the type of the computational context representing the Unity execution world. It internally has a structure containing IO, but from CPA's perspective it is treated as "the computational context of the Unity execution world." In contrast with Logical Configuration, what matters is not the presence or absence of IO, but **whether the computational context representing the execution world is encompassed in the stack**.

This difference in type signatures formally records what kind of structure the discovered Core is.

#### Concrete Example of Ontological Configuration

In a Unity game system, a player's movement cannot be described without presupposing the Unity execution world:

```haskell
-- Core Model in Ontological Configuration
-- Transform is the mode of being of the Unity world and is mixed into the Core's definition
data PlayerCore = PlayerCore
  { playerId      :: PlayerId
  , transform     :: Transform   -- Encompasses Unity's operational characteristics
  , health        :: Health
  , movementSpeed :: Float
  }

-- Projected Context in Ontological Configuration
-- The computational context of the Unity execution world is embedded in the stack
type UnityContext a = ReaderT UnityWorld (StateT GameState Unity) a

usecaseMovePlayer :: Vector3 -> UnityContext ()
usecaseMovePlayer direction = do
  player <- gets currentPlayer
  let newPos = calculatePosition (transform player) direction (movementSpeed player)
  liftUnity $ setTransformPosition (transform player) newPos  -- Unity API call
  modify $ updatePlayerTransform newPos
```

The reason `liftUnity` can be used is that `UnityContext` includes the Unity computational context in the stack. The dependency on `setTransformPosition` is justified not as a design compromise but as a necessary consequence of the player existing in a world called Unity.

---

### 8.6 Type-Level Proof of the Retro-dependency Principle

The Retro-dependency Principle is mechanically enforced by the type system.

In a computational context stack, an upper context can `run` a lower context. However, running an upper context from a lower context is prohibited by the type system.

```haskell
-- ✅ Permitted direction: Application Base runs Projected Context
runUsecaseSpeak :: SpeakRequest -> AvatarStore -> IO (AvatarState, AvatarStore)
runUsecaseSpeak req store =
  return $ runState (runReaderT usecaseSpeak req) store

-- ❌ Prohibited direction: Projected Context attempts to run upper context
illegalUsecase :: ReaderT SpeakRequest (State AvatarStore) ()
illegalUsecase = do
  -- ReaderT + State stack cannot run the upper IO context
  -- → Type error (detected at compile time)
  runIO $ putStrLn "This violates the Retro-dependency Principle"
```

The same principle holds in Ontological Configuration:

```haskell
-- ✅ Permitted direction: Interface runs Projected Context
runMovement :: Vector3 -> GameState -> UnityWorld -> Unity GameState
runMovement dir state world =
  execStateT (runReaderT (usecaseMovePlayer dir) world) state

-- ❌ Prohibited direction: Projected Context directly calls Interface
-- The inside of usecaseMovePlayer does not know which Interface will run it
```

The consequence shown by this type constraint is as follows:

> **The Retro-dependency Principle, in a properly typed system, appears as a compile-time error rather than a runtime error.**

The dependency constraint is not a designer's manner but the structural necessity of types.

---

### 8.7 Consequences and Limitations of Formalization

**Consequence 1: Mechanical enforcement of dependency direction**
Code that violates the Retro-dependency Principle appears as a compile-time error at the type level. Dependency constraints are transformed from conventions to structural necessity.

**Consequence 2: Observation of erosion via type signatures**
Ontological Erosion is observed as the mixing of the execution world's computational context into the type signature of the Projected Context. The type signature functions as a formal record of architectural choices.

**Consequence 3: Proof via asymmetry of lift / run**
While an upper context can `run` a lower context, the reverse is prohibited by the type system. This asymmetry is the formal proof of the Retro-dependency Axiom.

On the other hand, this formalization has the following limitations:

**Limitation 1: Quantification of erosion extent**
While a type signature can indicate the presence or absence of erosion, the boundary of how far erosion is permitted depends on qualitative judgment. The quantification of erosion determination remains a future challenge.

**Limitation 2: Non-verifiability of Core discovery accuracy**
Even if types are correctly attached, if the concept of the Core to which the types are given has been incorrectly discovered, the type system cannot detect that error. Type consistency is a necessary but not sufficient condition for structural stability.

**Limitation 3: Language dependency**
This formalization uses Haskell's type system as a medium. In languages that do not have static typing, or languages that do not directly support monad transformers, equivalent guarantees need to be achieved by other means. Computational context expressions specific to each language — such as C#'s `Task<T>`, Rust's `Result<T, E>`, and TypeScript's type parameters — can serve as the medium for demonstrating CPA's propositions.

These limitations are honestly discussed in the evaluation in Chapter 9.

---

## Chapter 9: Evaluation and Practical Implications

### 9.1 Setting the Evaluation Framework

In this chapter, CPA is comprehensively evaluated from theoretical and practical perspectives. The evaluation is conducted based on the following seven axes:

1. **Theoretical Consistency**
2. **Scope of Application**
3. **Clarity of Implementation Guidelines**
4. **Ease of Testing**
5. **Conceptual Originality**
6. **Explainability**
7. **Scalability**

These evaluation axes are set to verify whether CPA is valid not merely as a design guideline but as a structural theory with an ontological foundation.

---

### 9.2 Theoretical Consistency

CPA is a system that deductively derives dependency constraints, layer structure, and the concept of erosion from five axioms as its starting points.

The inward-facing nature of dependency is directly derived from the Retro-dependency Axiom. The Projected Context being a partial mapping of the Core is a consequence of the Projection Constraint Axiom. The non-identity of layer boundaries and execution boundaries is derived from the Execution Independence Axiom. The two types of erosion are explained by the combination of the Core Discoverability Axiom and the Projection Constraint Axiom.

Each proposition is positioned as a logical consequence within the axiom system without recourse to external theories. In this sense, CPA maintains consistency as a deductive structural theory, not a normative architectural theory.

Furthermore, theoretical consistency is supported by formalization. The Retro-dependency Principle is mechanically enforced as the asymmetry of `lift` / `run` in the type system. Erosion is observed as the mixing of the execution world's computational context into the type signature of the Projected Context. The correspondence between conceptual-level propositions and formal-level expressions further strengthens theoretical consistency.

On the other hand, the point that erosion judgment criteria depend on qualitative questions must be honestly recognized as a remaining challenge from the perspective of complete formalization of the axiom system (see Section 9.9).

---

### 9.3 Scope of Application

The most important characteristic in CPA's scope of application is that both Logical Configuration and Ontological Configuration can be handled within the theory.

Existing architectural theories that emphasize conceptual purity as a principle function effectively in Logical Configuration where the execution substrate functions as a Delivery-type. However, in Ontological Configuration where the execution substrate defines the operational characteristics of the world itself, the demand for purity has created a divergence from practice.

CPA transforms this divergence from a target of elimination to a target of analysis by formalizing erosion as an intra-theoretical concept.

- When the execution substrate is removable → Logical Configuration
- When the execution substrate defines the conditions of existence → Ontological Configuration

This distinction is not a value judgment but a difference in the conditions of existence that are discovered. The acceptance of erosion is understood not as a compromise but as a structural necessity for the Core to exist in that world.

Also, by the Fractal Recursion Axiom, the same principle is applicable at any granularity. The same structure holds in the entire system, subsystems, or individual modules alike (see Appendix B.5).

On the other hand, the benefits of application are limited in areas where the Core's clarity cannot be confirmed. In systems like simple data transformation pipelines where there is no well-defined structural center, a projection structure is unnecessary, and forced application only leads to complication. The principle that fractal recursion is not a means of complication also serves as an effective criterion for judging the limits of application.

---

### 9.4 Clarity of Implementation Guidelines

CPA is not only a static structural theory but also has a connection to the design process.

#### 9.4.1 Order of Design

In CPA, design proceeds in the following order:

**Stage 1: Identification of the execution world**
Determine whether the execution substrate is Delivery-type or Foundational-type and decide which to adopt — Logical Configuration or Ontological Configuration.

**Stage 2: Discovery of the Core**
Discover the minimal structural unit that is context-independent. "Does this concept hold even if the execution world is removed?" is the criterion for discovery.

**Stage 3: Definition of projection**
Compose Projected Contexts as slices responding to requirements. Projection does not add new structure to the Core — if the Projected Context holds concepts that do not exist in the Core, that indicates an error in projection or insufficient Core discovery.

Through this procedure, design is redefined not as construction but as improving the accuracy of discovery.

#### 9.4.2 Presentation of Judgment Criteria

CPA provides designers with concrete judgment criteria:

**Core Discovery Priority Principle**: The starting point of design is not the enumeration of requirements. First ask "does it hold even if context is removed?" and identify the Core. The quality of design is governed by accuracy of discovery, not generative ability.

**Projection Limitation Principle**: The Projected Context must not extend the Core. Projection is the limitation of possibilities; if new concepts are being introduced, that suggests a failure of projection or insufficient Core discovery.

**Adherence to Retro-dependency**: Dependencies always trace the retro-directional path from phenomenon to underlying structure. The Core referencing the Interface and the Projected Context knowing the details of execution are both defined as structural deviations. Refactoring is the act of realigning the arrows of dependency in the reverse direction of manifestation.

---

### 9.5 Ease of Testing

CPA's structure ensures testability as a design principle.

The state transitions of the Application Base are formalized as:

```
State × Event → (State, Effect)
```

Effect is a description of side effects, not their execution. This separation allows state transition logic to be verified as a pure function without requiring an execution environment. With side effect boundaries limited to the Interface, the test target and side effect execution are clearly separated.

The Projected Context in Logical Configuration is defined as pure computation, so it can be tested without mocking the execution environment or using dependency injection. In Ontological Configuration, the difficulty of testing increases because the execution world's computational context becomes mixed into the stack, but that is a reflection of the execution world's conditions of existence, not a deficiency of the theory.

---

### 9.6 Conceptual Originality

CPA's theoretical originality is organized into three points:

**Establishing dependency constraints as structural necessity**
The principle of "keeping inward dependencies" was separated from the enumeration of practical benefits and derived from the single proposition of the causal structure of manifestation — a projection cannot exist without its source. Dependency constraints are transformed from conventions to structural necessity. Mechanical enforcement by the type system is the formal realization of this necessity.

**Redefinition of Core as discovery**
By positioning the Core not as something constructed by the designer but as something discovered, the meaning of the design act fundamentally changes. The quality of design depends on accuracy of discovery, not generative ability. This transformation is an epistemological redefinition of the design act.

**Theorization of Ontological Erosion**
The point of reinterpreting the influence of the execution substrate not as a design failure but as the nature of the discovered structure is an epistemological turn in structural theory. It enables application to Foundational-type environments that existing theories could not address, and expands the scope of the theory to match the reality of practice.

---

### 9.7 Explainability

CPA provides vocabulary for articulating the basis of design decisions.

"Why is this concept placed in the Core Model?" "Why does this process belong to the Projected Context?" "Why are dependencies constrained to be in this direction?" — to these questions, CPA gives consistent answers from the single basis of the causal structure of manifestation.

In particular, the concept of "erosion" articulates as theory the sense that designers feel in Ontological Configuration that "dependence on the execution substrate is unavoidable." It becomes possible to conduct theory-based discussions such as "Is this a range to be accepted as Inside-out Erosion?" or "Is this an unnecessary dependency due to a discovery error?"

---

### 9.8 Scalability

By the Fractal Recursion Axiom, CPA's four-layer structure holds at any scale. The same structural principle can be applied recursively from a single component to subsystems and to the entire system.

By the Execution Independence Axiom, changes in execution strategies such as parallelization and distribution do not require changes to the layer structure. Transitioning from a single process to a distributed system is, from CPA's perspective, a change in execution strategy, not a change in structural principles.

---

### 9.9 Remaining Challenge: Quantification of Erosion Determination

The main remaining challenge in CPA is the establishment of quantitative criteria for erosion determination.

Currently, erosion analysis depends on the qualitative question "do the concepts of the Core still hold if the execution substrate is removed?" This question is conceptually clear, but in situations of partial erosion — where some concepts in the Core depend on the execution world and others are independent — objective criteria for identifying the extent of erosion are not yet in place.

Through the formalization implementation in Appendix B, initial type-level indicators for erosion determination have been obtained. Specifically, it has been confirmed that whether a computational context type representing the execution world (such as `World m`) appears inside the stack in the Projected Context's type signature functions as an observable indicator for distinguishing Outside-in from Inside-out (see Appendix B.1, B.2). This observational indicator is promising as a starting point for quantification, but further indicator development is needed to accurately identify the extent of partial erosion.

Future challenges include the following:

- Systematization of erosion detection indicators via type signatures (including the above observational indicator)
- Development of an erosion determination checklist
- Development of a scoring method for the extent of erosion
- Quantitative analysis of the impact of accepting erosion on design costs — resilience to change, portability, testing burden

As quantification advances, CPA is expected to evolve from theory into an engineering tool, further improving the precision of communication among designers.

---

## Chapter 10: Conclusion — The Transformation from Convention to Necessity

### 10.1 Reconfirmation of the Central Thesis

The central thesis of CPA presented in this paper is as follows:

> **The Core is something to be discovered, and the discovered Core manifests in the external world as a contextual projection. Dependencies trace back against this direction of manifestation. This is the basis for structural constraints.**

This thesis simultaneously derives from a single basis two questions that have long been treated independently in software structural theory — "why does a structural center exist?" and "why are dependencies constrained to be inward-facing?"

Since the Core is a structure to be discovered, the Core necessarily has the necessity of being positioned at the structural center as the starting point of manifestation. Since the realized projection cannot exist without its source, dependency must trace the reverse of manifestation. These two propositions are not independent conventions but consequences derived from the single causal structure called manifestation.

---

### 10.2 Integrated Significance of the Three Principles

CPA is constituted by the three principles of Discovery, Projection, and Retro-dependency. The three principles are understood not as independent design guidelines but as a sequence of necessity that branches and unfolds from the single structure of manifestation.

**Discovery Principle** determines the ontological status of the Core. Design is not generation but recognition. The validity of the Core is judged not by the designer's intent but by the accuracy of discovery. Through this transformation, the evaluation criterion for the design act fundamentally shifts from generative ability to accuracy of discovery.

**Projection Principle** determines how the Core manifests in the external world. When context is applied to the multidimensional structure called Core, a specific slice is extracted. Projection does not add new structure to the Core. A UseCase is not something designed as an independent entity outside the Core but something discovered as a contextual projection of the Core.

**Retro-dependency Principle** derives dependency constraints from the causal structure of manifestation. A projection cannot exist without its source. The source does not know the projection. From this asymmetry, the constraint of "keeping inward dependencies" is derived as a necessity. The principle that has been stated as a convention here obtains its causal basis for the first time.

The integrated significance of the three principles lies in the transformation of "from convention to necessity" in design theory. The basis for design decisions shifts from "it is said to be done this way" as a norm to "manifestation cannot be established otherwise" as causality.

---

### 10.3 The Turn in Design Theory

The greatest change brought by CPA is epistemological.

A system is reconceived not as a "construction" assembled arbitrarily by a designer, but as a "manifestation process" in which discovered structures emerge into the external world. The designer's role is not to create the Core but to discover the latent order and to arrange the structure so as not to distort its manifestation.

This turn appears most clearly in the handling of Ontological Erosion. Rather than treating the mixing of the execution world's operational characteristics into the Core's definition as "contamination" to be avoided, it is accepted as a necessary consequence for the Core to exist in that world. This ontological honesty resolves the divergence between theory and practice.

Software is the phenomenon in which logic is realized under the constraints of reality — time, resources, space. CPA values the underlying structure behind that realization and seeks to arrange it along the natural flow of causality.

Logical purity holds completely only in an abstract space where no conditions of existence are imposed. For the Core to exist in a real execution world, it must conform to the ontological conditions of that world. Ontological Erosion is the manifestation of that necessity, and is not a failure of purity but an honest response to the world. What is required of the designer is not to eliminate erosion but to accurately recognize its extent, and to arrange the structure with the awareness of whether one is in Logical Configuration or Ontological Configuration.

---

### 10.4 Future Challenges

**Quantification of erosion determination**
As stated in Section 9.9, the first challenge is to develop the qualitative question of erosion determination into quantitative criteria. The development of determination checklists, scoring methods, and correlation analysis with design costs are required as the engineering development of the theory.

**Refinement of recursive application in distributed environments**
Although the Execution Independence Axiom guarantees the non-identity of layer boundaries and execution boundaries, this paper does not address guidelines for how to determine service boundaries in large-scale distributed systems. The structural-theoretic organization of cases where CPA's four-layer structure spans multiple services remains as a challenge.

**Methods for ensuring guarantees in environments without type systems**
The formalization in this paper presupposes a static type system. The exploration of alternative methods for guaranteeing the Retro-dependency Principle in language environments without a type system is required.

**Support technology for Core extraction**
In conjunction with the quantification of erosion determination, the development of support technology for Core extraction using static analysis or formal verification is cited as a long-term challenge toward the practical dissemination of the theory.

---

### Closing

Maintaining manifestation is maintaining dependency, and maintaining dependency is maintaining manifestation.

Within this two-sidedness of a single proposition lies the theoretical core of Core Projection Architecture.

It was once said that "a monad is just a monoid in the category of endofunctors." Even seemingly complex structures, when viewed from the correct perspective, appear as necessity — nothing else could be the case. What Core Projection Architecture has sought to show is precisely the same thing.

---

### References

#### Appendix A: [Layer Naming and Legacy Vocabulary Correspondence Table](cpa_thesis_appendix_a_en.md)
#### Appendix B: [Formalization Code in Haskell](cpa_thesis_appendix_b_en.md)
#### Appendix C: [Detailed Evaluation Score Comparison](cpa_thesis_appendix_c_en.md)

---

### Paper Information
* **Title**: Core Projection Architecture (CPA)
* **Revision**: 1.0.0
* **Authors**:
  * **Aska Lanclaude** (Lead Author / Theory Construction)
  * **neko** (Co-Author / Formal Verification and Analysis)
* **Published**: January 2026
