# Toolchain contract

## Native commands
- `fourmolu -m check app src test`
- `hlint .`
- `ghcup run --ghc 9.6.7 -- cabal build all`
- `ghcup run --ghc 9.6.7 -- cabal test all`

## Docker commands
- `docker build -t haskell-stakeholder .`
- `docker run --rm haskell-stakeholder --list-values`
- `docker run --rm haskell-stakeholder --dev-type backend --complexity medium --seed docker-code --focus-family code_analyzer --output-format json`
- `docker run --rm haskell-stakeholder --dev-type dev-ops --complexity high --seed docker-delivery --focus-family delivery_preview_ops --output-format json`

## CI workflows
- `ci-native`
- `docker-smoke`
- `actionlint`
- `dependency-review`

## Current limitation
- `flake.lock` is now generated locally through the installed Nix toolchain.
- The official multi-user macOS Nix installer is already the chosen and installed path on this workstation.
