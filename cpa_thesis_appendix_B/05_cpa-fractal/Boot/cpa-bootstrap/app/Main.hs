module Main where

import System.IO
import System.Exit
import Options.Applicative
import Data.Version             (showVersion)
import qualified Control.Exception.Safe as E

import Paths_cpa_bootstrap      (version)
import CPA.Multiverse.CoreModel.Type     (GlobalContext)
import CPA.Bootstrap.CoreModel.Type
import qualified CPA.Bootstrap.ApplicationBase.Control    as Control

import qualified CPA.Fractal.ApplicationBase.Control          as Fractal
import qualified CPA.SemanticWorld.ApplicationBase.Control    as Semantic
import qualified CPA.OntologicalWorld.ApplicationBase.Control as Ontological
import qualified CPA.Request.Boot.Bootstrap                   as Request
import qualified CPA.Response.Boot.Bootstrap                  as Response

-- | エントリポイント
-- 各ライブラリの run を [GlobalContext -> IO ()] のリストに組み立てて Control.run に渡す。
-- Main のみが各ライブラリに依存する。Control は依存しない。
main :: IO ()
main = do
  hSetBuffering stderr LineBuffering
  args <- getArgs
  flip E.catchAny onException
    $ flip E.finally onFinalize
    $ Control.run args apps
  where
    apps :: [GlobalContext -> IO ()]
    apps =
      [ Fractal.run
      , Semantic.run
      , Ontological.run
      , Request.run
      , Response.run
      ]

    onFinalize :: IO ()
    onFinalize = do
      hPutStrLn stderr "-----------------------------------------------------------------------------"
      hPutStrLn stderr "[INFO] cpa-bootstrap: finalize."
      hPutStrLn stderr "-----------------------------------------------------------------------------"

    onException :: E.SomeException -> IO ()
    onException e = do
      hPutStrLn stderr "-----------------------------------------------------------------------------"
      hPutStrLn stderr "[ERROR] cpa-bootstrap: unhandled exception."
      hPutStrLn stderr $ show e
      hPutStrLn stderr "-----------------------------------------------------------------------------"
      exitFailure

--------------------------------------------------------------------------------
-- optparse-applicative
--------------------------------------------------------------------------------

getArgs :: IO ArgData
getArgs = execParser parseInfo

parseInfo :: ParserInfo ArgData
parseInfo = info (helper <*> verOpt <*> options) $ mconcat
  [ fullDesc
  , header   "cpa-bootstrap - CPA Fractal System Launcher"
  , progDesc "Launches all CPA fractal components (fractal-app, semantic-world, ontological-world, request, response)."
  , footer   "Copyright (c) 2025 Aska Lanclaude. All rights reserved."
  ]

verOpt :: Parser (a -> a)
verOpt = infoOption msg $ mconcat
  [ short 'v', long "version", help "Show version" ]
  where msg = "cpa-bootstrap-" ++ showVersion version

options :: Parser ArgData
options = ArgData
  <$> optional (strOption $ mconcat
        [ short 'y', long "yaml"
        , help "Path to YAML config file"
        , metavar "FILE"
        ])
