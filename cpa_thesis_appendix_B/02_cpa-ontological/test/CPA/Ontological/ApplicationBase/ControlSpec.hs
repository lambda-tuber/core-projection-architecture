{-# LANGUAGE KindSignatures #-}

module CPA.Ontological.ApplicationBase.ControlSpec (spec) where

import Test.Hspec
import Data.IORef

import CPA.Ontological.CoreModel.Type
  ( GlobalConfig (..)
  , ContextualState (..)
  , Avatar (..)
  , World (..)
  )
import qualified CPA.Ontological.ApplicationBase.Control as C

-- ===========================================================================
-- AnotherWorld：World m のインスタンス定義（Boot 層代替）
-- src 側には置かない。インスタンスの実装は Boot 層の責務（形式化スコープ外）
-- IORef が外部世界（Unity シーン等）を模倣する
-- ===========================================================================

newtype AnotherWorld a = AnotherWorld
  { runAnotherWorld :: IORef (Avatar AnotherWorld) -> IO a }

instance Functor AnotherWorld where
  fmap f (AnotherWorld g) = AnotherWorld $ \ref -> fmap f (g ref)

instance Applicative AnotherWorld where
  pure a = AnotherWorld $ \_ -> pure a
  AnotherWorld f <*> AnotherWorld x = AnotherWorld $ \ref -> f ref <*> x ref

instance Monad AnotherWorld where
  return = pure
  AnotherWorld x >>= f = AnotherWorld $ \ref -> do
    a <- x ref
    runAnotherWorld (f a) ref

instance World AnotherWorld where
  loadAvatar   = AnotherWorld $ \ref -> readIORef ref
  saveAvatar a = AnotherWorld $ \ref -> writeIORef ref a

-- | Boot 代替：AnotherWorld + 初期 Avatar を生成して実行するヘルパー
runWithAnotherWorld :: Avatar AnotherWorld -> AnotherWorld a -> IO a
runWithAnotherWorld initial action = do
  ref <- newIORef initial
  runAnotherWorld action ref

-- ===========================================================================
-- テスト用定数
-- ===========================================================================

heroAvatar :: Avatar AnotherWorld
heroAvatar = Avatar { avatarName = "Hero", level = 4, hp = 100, mp = 50 }

testConfig :: GlobalConfig
testConfig = GlobalConfig { configName = "TestWorld" }

testInitState :: ContextualState
testInitState = ContextualState { stateLog = [] }

-- ===========================================================================
-- Spec
-- ===========================================================================

spec :: Spec
spec = do

  -- -----------------------------------------------------------------------
  -- attacked
  -- -----------------------------------------------------------------------
  describe "attacked" $ do

    context "Hero が 30 ダメージを受けた場合" $ do
      it "hp が 30 減っていること" $ do
        (resultAvatar, _) <- runWithAnotherWorld heroAvatar $
          C.runAttacked testConfig testInitState 30
        hp resultAvatar `shouldBe` 70

      it "World 内の Avatar（saveAvatar 経由）の hp も 30 減っていること" $ do
        ref <- newIORef heroAvatar
        _ <- runAnotherWorld (C.runAttacked testConfig testInitState 30) ref
        saved <- readIORef ref
        hp saved `shouldBe` 70

      it "stateLog にダメージログが記録されていること" $ do
        (_, resultState) <- runWithAnotherWorld heroAvatar $
          C.runAttacked testConfig testInitState 30
        stateLog resultState `shouldBe`
          [ "Hero was attacked. hp: 100 -> 70" ]

  -- -----------------------------------------------------------------------
  -- heal
  -- -----------------------------------------------------------------------
  describe "heal" $ do

    context "Hero（level=4）がヒールを使った場合" $ do
      it "hp が level*5 = 20 回復していること" $ do
        (resultAvatar, _) <- runWithAnotherWorld heroAvatar $
          C.runHeal testConfig testInitState
        hp resultAvatar `shouldBe` 120

      it "mp が 10 消費されていること" $ do
        (resultAvatar, _) <- runWithAnotherWorld heroAvatar $
          C.runHeal testConfig testInitState
        mp resultAvatar `shouldBe` 40

      it "stateLog に回復ログが記録されていること" $ do
        (_, resultState) <- runWithAnotherWorld heroAvatar $
          C.runHeal testConfig testInitState
        stateLog resultState `shouldBe`
          [ "Hero used heal. hp: 100 -> 120, mp: 50 -> 40" ]

  -- -----------------------------------------------------------------------
  -- attacked → heal の連続アクション
  -- -----------------------------------------------------------------------
  describe "attacked → heal（連続アクション）" $ do

    context "攻撃を受けてからヒールした場合" $ do
      it "hp が -30 + 20 = 最終 90 になっていること" $ do
        ref <- newIORef heroAvatar
        (_, damagedState) <- runAnotherWorld
          (C.runAttacked testConfig testInitState 30) ref
        (healedAvatar, _) <- runAnotherWorld
          (C.runHeal testConfig damagedState) ref
        hp healedAvatar `shouldBe` 90

      it "stateLog に両方のログが順番に記録されていること" $ do
        ref <- newIORef heroAvatar
        (_, damagedState) <- runAnotherWorld
          (C.runAttacked testConfig testInitState 30) ref
        (_, finalState) <- runAnotherWorld
          (C.runHeal testConfig damagedState) ref
        stateLog finalState `shouldBe`
          [ "Hero was attacked. hp: 100 -> 70"
          , "Hero used heal. hp: 70 -> 90, mp: 50 -> 40"
          ]
