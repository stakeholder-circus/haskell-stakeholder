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
- `flake.lock` has not been generated locally because `nix` is not installed in the current environment.
- The official multi-user macOS Nix installer still requires a live sudo-authenticated Codex PTY or a separate user-run install in a local terminal.
