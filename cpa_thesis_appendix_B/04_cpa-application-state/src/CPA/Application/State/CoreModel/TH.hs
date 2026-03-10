{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Application.State.CoreModel.TH (
    funcTH_transit
  , instanceTH_IAppState
  ) where

import qualified GHC.Base
import qualified GHC.Show
import Control.Monad.Except (throwError)
import Control.Monad.Trans.State.Lazy
import Language.Haskell.TH
import Control.Monad
import qualified Data.Text as T

import CPA.Application.State.CoreModel.Type
import CPA.Application.State.CoreModel.Utility


-- | Template Haskell: IAppState インスタンスを Event コンストラクタ数だけ自動生成する
--
-- 生成されるコード例（StartStateData の場合）:
--   instance IAppState StartStateData where
--     actionS s (EventW r@EntryEvent{})    = action s r
--     actionS s (EventW r@ExitEvent{})     = action s r
--     actionS s (EventW r@TransitEvent{})  = action s r
--     actionS s (EventW r@AttackedEvent{}) = action s r
--
instanceTH_IAppState :: Name -> Q [Dec]
instanceTH_IAppState stName = do
  ns <- getGadtsContNames ''Event
  clauseList <- mapM go ns
  return [InstanceD Nothing [] (AppT (ConT ''IAppState) (ConT stName)) [FunD 'actionS clauseList]]

  where
    go n = do
      s <- newName "s"
      r <- newName "r"
      return $ Clause
        [VarP s, ConP 'EventW [] [AsP r (RecP n [])]]
        (NormalB (AppE (AppE (VarE 'action) (VarE s)) (VarE r)))
        []

    getGadtsContNames :: Name -> Q [Name]
    getGadtsContNames n = reify n >>= \case
      TyConI (DataD _ _ _ _ cs _) -> mapM go' cs
      x -> fail $ "[ERROR] can not get data constructor. " ++ show x
      where
        go' (GadtC [name] _ _) = return name
        go' x = fail $ "[ERROR] can not get gadts data constructor. " ++ show x


-- | Template Haskell: StateTransition コンストラクタから transit 関数を自動生成する
--
-- 生成されるコード例:
--   transit :: StateTransition -> AppStateContext ()
--   transit StartToRun = get >>= \case
--     AppStateW StartState -> changeTo $ AppStateW RunState
--     AppStateW x          -> throwError "invalid state transition. ..."
--   transit RunToStop = get >>= \case
--     AppStateW RunState -> changeTo $ AppStateW StopState
--     AppStateW x        -> throwError "invalid state transition. ..."
--
-- ※ fail ではなく throwError を使うことで、不正遷移を ExceptT の Left に収める。
--   これにより IO 層に例外を漏らさず、CPA の層構成を守る。
--
funcTH_transit :: Q [Dec]
funcTH_transit = do
  fname <- newName "transit"
  cons  <- getContNames ''StateTransition
  clauses <- mapM makeClaues cons
  return
    [ SigD fname (AppT (AppT ArrowT (ConT ''StateTransition)) (AppT (ConT ''AppStateContext) (TupleT 0)))
    , FunD fname clauses
    ]

  where
    getContNames :: Name -> Q [Name]
    getContNames n = reify n >>= \case
      TyConI (DataD _ _ _ _ cs _) -> mapM go cs
      x -> fail $ "[ERROR] can not get data constructor. " ++ show x
      where
        go (NormalC x _) = return x
        go x = fail $ "[ERROR] can not get data constructor. " ++ show x

    makeClaues :: Name -> Q Clause
    makeClaues n = do
      x <- newName "x"
      (curSt, nexSt) <- getStName n
      return $ Clause
        [ConP n [] []]
        (NormalB
          (InfixE (Just (UnboundVarE 'get)) (VarE '(GHC.Base.>>=))
            (Just (LamCaseE
              [ Match (ConP 'AppStateW [] [ConP curSt [] []])
                  (NormalB (InfixE
                    (Just (UnboundVarE 'changeTo))
                    (VarE '(GHC.Base.$))
                    (Just (AppE (ConE 'AppStateW) (ConE nexSt)))))
                  []
              , Match (ConP 'AppStateW [] [VarP x])
                  -- throwError を使って ExceptT の Left に収める（IO 層に漏らさない）
                  (NormalB (InfixE
                    (Just (VarE 'throwError))
                    (VarE '(GHC.Base.$))
                    (Just (InfixE
                      (Just (LitE (StringL "invalid state transition. trans:")))
                      (VarE '(GHC.Base.++))
                      (Just (InfixE
                        (Just (AppE (VarE 'GHC.Show.show) (ConE n)))
                        (VarE '(GHC.Base.++))
                        (Just (InfixE
                          (Just (LitE (StringL ", curSt:")))
                          (VarE '(GHC.Base.++))
                          (Just (AppE (VarE 'GHC.Show.show) (VarE x)))))))))))
                  []
              ]))))
        []

    -- | "StartToRun" → (StartState, RunState) のように Name ペアを返す
    getStName :: Name -> Q (Name, Name)
    getStName n = do
      let modName = "CPA.Application.State.CoreModel.Type."
          stStrs  = T.splitOn "To" $ T.replace modName "" $ T.pack $ show n
      when (2 /= length stStrs) $ fail $ "[ERROR] invalid StateTransition constructor. " ++ show n
      let curSt = mkName $ T.unpack $ modName `T.append` head stStrs `T.append` "State"
          nxtSt = mkName $ T.unpack $ modName `T.append` last stStrs `T.append` "State"
      return (curSt, nxtSt)
