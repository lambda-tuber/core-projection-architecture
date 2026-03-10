{-# LANGUAGE GADTs #-}

module CPA.Application.State.ApplicationBase.ControlSpec (spec) where

import Test.Hspec

import CPA.Application.State.CoreModel.Type
import CPA.Application.State.ApplicationBase.Control

--------------------------------------------------------------------------------
-- ヘルパー
--------------------------------------------------------------------------------

runEvents :: [EventW] -> IO (Either String AppStateW)
runEvents events = do
  result <- run events
  return $ case result of
    Left  err          -> Left err
    Right (_, finalSt) -> Right finalSt

stateLabel :: AppStateW -> String
stateLabel (AppStateW StartState) = "Start"
stateLabel (AppStateW RunState)   = "Run"
stateLabel (AppStateW StopState)  = "Stop"

--------------------------------------------------------------------------------
-- Spec
--------------------------------------------------------------------------------

spec :: Spec
spec = do
  runIO $ putStrLn "=== ApplicationBase.ControlSpec ==="

  describe "AppState 状態遷移" $ do

    -- シナリオ1：Start → Run
    context "Start 状態で StartToRun イベントを受け取ったとき" $ do
      it "Run 状態に遷移すること" $ do
        let events = [ EventW (TransitEvent (TransitEventData StartToRun)) ]
        result <- runEvents events
        case result of
          Left  err -> expectationFailure $ "Error: " ++ err
          Right st  -> stateLabel st `shouldBe` "Run"

    -- シナリオ2：Start → Run → Stop
    context "Start → Run → Stop の順にイベントを受け取ったとき" $ do
      it "Stop 状態まで遷移すること" $ do
        let events = [ EventW (TransitEvent (TransitEventData StartToRun))
                     , EventW (TransitEvent (TransitEventData RunToStop))
                     ]
        result <- runEvents events
        case result of
          Left  err -> expectationFailure $ "Error: " ++ err
          Right st  -> stateLabel st `shouldBe` "Stop"

    -- シナリオ3：Run 状態で AttackedEvent が処理されること
    context "Run 状態で AttackedEvent を受け取ったとき" $ do
      it "エラーなく処理されて Run 状態のままであること（ProjectedContext doActivity）" $ do
        let events = [ EventW (TransitEvent (TransitEventData StartToRun))
                     , EventW (AttackedEvent AttackedEventData)
                     ]
        result <- runEvents events
        case result of
          Left  err -> expectationFailure $ "Error: " ++ err
          Right st  -> stateLabel st `shouldBe` "Run"

    -- シナリオ4：不正遷移は ExceptT の Left に収まること
    context "Start 状態で RunToStop（不正遷移）を受け取ったとき" $ do
      it "ExceptT でエラーが捕捉されること" $ do
        let events = [ EventW (TransitEvent (TransitEventData RunToStop)) ]
        result <- runEvents events
        case result of
          Left  _  -> return ()
          Right st -> expectationFailure $
            "エラーになるべきところが成功した。状態: " ++ stateLabel st
