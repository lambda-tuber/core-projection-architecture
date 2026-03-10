{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module CPA.Fractal.CoreModel.TH (
    funcTH_transit
  , instanceTH_IWorldState
  ) where

import qualified GHC.Show
import Control.Monad.Trans.State.Lazy
import Control.Monad.Trans.Class
import Control.Monad.Except           (throwError)
import Language.Haskell.TH
import Control.Monad
import qualified Data.Text as T

import CPA.Fractal.CoreModel.Type
import CPA.Fractal.CoreModel.Utility


-- | Template Haskell: IWorldState インスタンスを Event コンストラクタ数だけ自動生成する
--
-- 生成されるコード例（SemanticStateData の場合）:
--   instance IWorldState SemanticStateData where
--     actionS s (EventW r@EntryEvent{})           = action s r
--     actionS s (EventW r@ExitEvent{})            = action s r
--     actionS s (EventW r@TransitEvent{})         = action s r
--     actionS s (EventW r@AttackedEvent{})        = action s r
--     actionS s (EventW r@HealEvent{})            = action s r
--     actionS s (EventW r@SetAvatarEvent{})       = action s r
--     actionS s (EventW r@CalamityEvent{})        = action s r
--     actionS s (EventW r@QuitEvent{})            = action s r
--
instanceTH_IWorldState :: Name -> Q [Dec]
instanceTH_IWorldState stName = do
  ns <- getGadtsContNames ''Event
  clauseList <- mapM go ns
  return [InstanceD Nothing [] (AppT (ConT ''IWorldState) (ConT stName)) [FunD 'actionS clauseList]]

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
-- ExceptT が WorldStateContext の外側にあるため、
-- StateT 層へのアクセスは lift 経由で行う。
-- 不正遷移時は throwError で ExceptT に閉じ込める。
--
-- 引数なしコンストラクタ（全4状態）の場合：
--   cur パターン: WorldStateW CurState
--   nex 式      : WorldStateW NexState（ConE で直接参照）
--
-- 引数ありコンストラクタが将来追加された場合：
--   cur パターン: WorldStateW (CurState _)
--   nex 式      : WorldStateW initNexState（lookupValueName で動的解決）
--
-- 生成されるコード例:
--   transit :: StateTransition -> WorldStateContext ()
--   transit StartToSemantic = lift get >>= \case
--     WorldStateW StartState    -> changeTo $ WorldStateW SemanticState
--     WorldStateW x             -> throwError "invalid state transition. ..."
--   transit SemanticToOntological = lift get >>= \case
--     WorldStateW SemanticState -> changeTo $ WorldStateW OntologicalState
--     WorldStateW x             -> throwError "invalid state transition. ..."
--
funcTH_transit :: Q [Dec]
funcTH_transit = do
  fname <- newName "transit"
  cons  <- getContNames ''StateTransition
  clauses <- mapM makeClauses cons
  return
    [ SigD fname (AppT (AppT ArrowT (ConT ''StateTransition)) (AppT (ConT ''WorldStateContext) (TupleT 0)))
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

    makeClauses :: Name -> Q Clause
    makeClauses n = do
      x <- newName "x"
      (curPat, nexExpr) <- getStPat n
      let liftGet = AppE (VarE 'lift) (VarE 'get)
      let errExpr =
            AppE (VarE 'throwError) $
              foldl1 (\a b -> InfixE (Just a) (VarE '(++)) (Just b))
                [ LitE (StringL "invalid state transition. trans:")
                , AppE (VarE 'GHC.Show.show) (ConE n)
                , LitE (StringL ", curSt:")
                , AppE (VarE 'GHC.Show.show) (VarE x)
                ]
      return $ Clause
        [ConP n [] []]
        (NormalB
          (InfixE (Just liftGet) (VarE '(>>=))
            (Just (LamCaseE
              [ Match curPat
                  (NormalB (InfixE
                    (Just (VarE 'changeTo))
                    (VarE '($))
                    (Just (AppE (ConE 'WorldStateW) nexExpr))))
                  []
              , Match (ConP 'WorldStateW [] [VarP x])
                  (NormalB errExpr)
                  []
              ]))))
        []

    -- | "StartToSemantic" → (curPat, nexExpr) を返す
    --
    -- WorldState の GADT コンストラクタを reify して引数数を調べる。
    -- nameBase で比較することで修飾名の違いを吸収する。
    --   引数なし → cur: ConP 'WorldStateW [ConP curName []]
    --              nex: ConE nexName（コンストラクタを直接参照）
    --   引数あり（将来対応）→ cur: ConP 'WorldStateW [ConP curName [WildP]]
    --              nex: VarE initNexStateName（"init" ++ nexBase で動的解決）
    getStPat :: Name -> Q (Pat, Exp)
    getStPat n = do
      let modName = "CPA.Fractal.CoreModel.Type."
          stStrs  = T.splitOn "To" $ T.replace modName "" $ T.pack $ show n
      when (2 /= length stStrs) $ fail $ "[ERROR] invalid StateTransition constructor. " ++ show n
      let curBase = T.unpack $ head stStrs `T.append` "State"
          nexBase = T.unpack $ last stStrs `T.append` "State"
      curArity <- getConArityByBase ''WorldState curBase
      nexArity <- getConArityByBase ''WorldState nexBase
      curName  <- getConNameByBase  ''WorldState curBase
      nexName  <- getConNameByBase  ''WorldState nexBase
      let curPat = if curArity > 0
            then ConP 'WorldStateW [] [ConP curName [] [WildP]]
            else ConP 'WorldStateW [] [ConP curName [] []]
      nexExpr <- if nexArity > 0
            then do
              -- init関数名を "init" + nexBase から動的に構築する
              -- 例: nexBase = "RunState" → 探す関数名 = "initRunState"
              let initFuncStr = "init" ++ nexBase
              lookupValueName initFuncStr >>= \case
                Just nm -> return (VarE nm)
                Nothing -> fail $ "[ERROR] init function not found: " ++ initFuncStr
                             ++ ". Define 'init" ++ nexBase ++ " :: WorldState XxxStateData' in scope."
            else return (ConE nexName)
      return (curPat, nexExpr)

    -- | WorldState の DataD から nameBase が一致するコンストラクタを探して引数数を返す
    getConArityByBase :: Name -> String -> Q Int
    getConArityByBase datName base = reify datName >>= \case
      TyConI (DataD _ _ _ _ cs _) -> go cs
      x -> fail $ "[ERROR] can not reify data. " ++ show x
      where
        go [] = fail $ "[ERROR] constructor not found by base: " ++ base
        go (GadtC [n] args _ : rest)
          | nameBase n == base = return (length args)
          | otherwise          = go rest
        go (_ : rest) = go rest

    -- | WorldState の DataD から nameBase が一致するコンストラクタの Name を返す
    getConNameByBase :: Name -> String -> Q Name
    getConNameByBase datName base = reify datName >>= \case
      TyConI (DataD _ _ _ _ cs _) -> go cs
      x -> fail $ "[ERROR] can not reify data. " ++ show x
      where
        go [] = fail $ "[ERROR] constructor not found by base: " ++ base
        go (GadtC [n] _ _ : rest)
          | nameBase n == base = return n
          | otherwise          = go rest
        go (_ : rest) = go rest
