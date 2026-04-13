module Main (main) where

import Stakeholder.App (runCli)
import System.Environment (getArgs)

main :: IO ()
main = getArgs >>= runCli
