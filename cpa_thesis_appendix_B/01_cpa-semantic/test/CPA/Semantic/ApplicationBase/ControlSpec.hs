module CPA.Semantic.ApplicationBase.ControlSpec (spec) where

import Test.Hspec
import Data.IORef

import CPA.Semantic.CoreModel.Type
  ( GlobalConfig (..)
  , ContextualState (..)
  , Avatar (..)
  , LoadAvatar
  , SaveAvatar
  )
import qualified CPA.Semantic.ApplicationBase.Control as C

-- | テスト用の固定 Avatar
heroAvatar :: Avatar
heroAvatar = Avatar { avatarName = "Hero", level = 4, hp = 100, mp = 50 }

-- | テスト用設定・初期状態
testConfig :: GlobalConfig
testConfig = GlobalConfig { configName = "TestWorld" }

testInitState :: ContextualState
testInitState = ContextualState { stateLog = [] }

-- | IORef を使った stub（Boot層のインジェクションを模倣）
-- Avatar は1インスタンス固定。ファイル永続化の代わりに IORef で保持。
makeStub :: Avatar -> IO (IORef Avatar, LoadAvatar, SaveAvatar)
makeStub initial = do
  ref <- newIORef initial
  let load = readIORef ref
      save = writeIORef ref
  pure (ref, load, save)

-- |
spec :: Spec
spec = do

  -- -----------------------------------------------------------------------
  -- attacked
  -- -----------------------------------------------------------------------
  describe "attacked" $ do

    context "Hero が 30 ダメージを受けた場合" $ do
      it "hp が 30 減っていること" $ do
        (_, load, save) <- makeStub heroAvatar
        (resultAvatar, _) <- C.runAttacked testConfig testInitState load save 30
        hp resultAvatar `shouldBe` 70

      it "saveAvatar 経由で永続化された Avatar の hp も 30 減っていること" $ do
        (ref, load, save) <- makeStub heroAvatar
        _ <- C.runAttacked testConfig testInitState load save 30
        saved <- readIORef ref
        hp saved `shouldBe` 70

      it "stateLog にダメージログが記録されていること" $ do
        (_, load, save) <- makeStub heroAvatar
        (_, resultState) <- C.runAttacked testConfig testInitState load save 30
        stateLog resultState `shouldBe`
          [ "Hero was attacked. hp: 100 -> 70" ]

  -- -----------------------------------------------------------------------
  -- heal
  -- -----------------------------------------------------------------------
  describe "heal" $ do

    context "Hero（level=4）がヒールを使った場合" $ do
      it "hp が level*5 = 20 回復していること" $ do
        (_, load, save) <- makeStub heroAvatar
        (resultAvatar, _) <- C.runHeal testConfig testInitState load save
        hp resultAvatar `shouldBe` 120

      it "mp が 10 消費されていること" $ do
        (_, load, save) <- makeStub heroAvatar
        (resultAvatar, _) <- C.runHeal testConfig testInitState load save
        mp resultAvatar `shouldBe` 40

      it "stateLog に回復ログが記録されていること" $ do
        (_, load, save) <- makeStub heroAvatar
        (_, resultState) <- C.runHeal testConfig testInitState load save
        stateLog resultState `shouldBe`
          [ "Hero used heal. hp: 100 -> 120, mp: 50 -> 40" ]

  -- -----------------------------------------------------------------------
  -- attacked → heal の連続アクション
  -- -----------------------------------------------------------------------
  describe "attacked → heal（連続アクション）" $ do

    context "攻撃を受けてからヒールした場合" $ do
      it "hp が -30 + 20 = 最終 90 になっていること" $ do
        -- IORef を共有することで saveAvatar → loadAvatar の連鎖が成立する
        (_, load, save) <- makeStub heroAvatar
        (_, damagedState) <- C.runAttacked testConfig testInitState load save 30
        (healedAvatar, _) <- C.runHeal testConfig damagedState load save
        hp healedAvatar `shouldBe` 90

      it "stateLog に両方のログが順番に記録されていること" $ do
        (_, load, save) <- makeStub heroAvatar
        (_, damagedState) <- C.runAttacked testConfig testInitState load save 30
        (_, finalState)   <- C.runHeal testConfig damagedState load save
        stateLog finalState `shouldBe`
          [ "Hero was attacked. hp: 100 -> 70"
          , "Hero used heal. hp: 70 -> 90, mp: 50 -> 40"
          ]
