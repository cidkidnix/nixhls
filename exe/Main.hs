{-# LANGUAGE TemplateHaskell #-}

module Main where

import Distribution.PackageDescription.Configuration
import Distribution.Types.GenericPackageDescription
import Distribution.Types.PackageName
import Distribution.Verbosity
import SimpleCabal
import System.Posix.Files
import System.Posix.Types
import System.Process
import System.Which

checkAndReload :: FilePath -> ProcessHandle -> EpochTime -> IO ()
checkAndReload cabal pro modtime = do
  filestat <- getFileStatus cabal
  let modtime' = modificationTime filestat
  if modtime /= modtime'
    then do
      putStrLn ("Cabal " <> cabal <> " has changed. Reloading!")
      terminateProcess pro
      impl
    else checkAndReload cabal pro modtime'

nixShellExe :: FilePath
nixShellExe = $(staticWhich "nix-shell")

getGenPackageDesc :: FilePath -> IO GenericPackageDescription
getGenPackageDesc = readGenericPackageDescription silent

getDependenciesOfCabal :: GenericPackageDescription -> [String]
getDependenciesOfCabal desc = do
  let deps = buildDependencies (flattenPackageDescription desc)
  map unPackageName deps

runShell :: [String] -> IO ProcessHandle
runShell v = do
  let deps = unwords v
      depslist = "(haskellPackages.ghcWithPackages (p: with p; " <> "[ " <> deps <> " " <> "haskell-language-server " <> "cabal-install" <> "]))"
  spawnProcess nixShellExe ["-p", depslist, "--run", "haskell-language-server-wrapper --lsp"]

impl :: IO ()
impl = do
  filepath <- findCabalFile
  x <- getGenPackageDesc filepath
  let packagenames = getDependenciesOfCabal x
  shell' <- runShell packagenames
  filestat' <- getFileStatus filepath
  let modtime'' = modificationTime filestat'
  checkAndReload filepath shell' modtime''

main :: IO ()
main = impl
