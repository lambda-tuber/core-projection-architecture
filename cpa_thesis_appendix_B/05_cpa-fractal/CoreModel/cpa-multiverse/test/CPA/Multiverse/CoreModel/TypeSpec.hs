module CPA.Multiverse.CoreModel.TypeSpec (spec) where

import Test.Hspec
import CPA.Multiverse.CoreModel.Type

-- |
--
spec :: Spec
spec = do
  describe "Avatar" $ do
    context "デフォルトアバターの生成" $ do
      it "フィールドが正しく設定されること" $ do
        let avatar = Avatar
              { _nameAvatar  = "TestHero"
              , _levelAvatar = 1
              , _hpAvatar    = 100
              , _mpAvatar    = 50
              }
        _nameAvatar  avatar `shouldBe` "TestHero"
        _levelAvatar avatar `shouldBe` 1
        _hpAvatar    avatar `shouldBe` 100
        _mpAvatar    avatar `shouldBe` 50
