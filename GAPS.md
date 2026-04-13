> [!NOTE]
> Missing or deferred behavior must fail fast and be tracked explicitly. No placeholder behavior should mask absent parity work.

# Haskell Gaps

## Current explicit gaps
- `haskell-stakeholder.ai-governance-fallback`: AI-governance families still use grouped fallback renderers.
- `haskell-stakeholder.security-blockchain-fallback`: security/blockchain families still use grouped fallback renderers.
- `haskell-stakeholder.health-protocol-fallback`: health/protocol families still use grouped fallback renderers.
- `haskell-stakeholder.overlay-quantum-fallback`: overlay/quantum families still use grouped fallback renderers.
- `haskell-stakeholder.live-provider-pending`: experimental provider flags are parsed and fail fast; live-provider integration is not implemented.
- `haskell-stakeholder.github-required-check-binding-pending`: exact required GitHub checks stay deferred until the repo has a remote and stable CI contexts.
- `haskell-stakeholder.flake-lock-pending`: `flake.nix` is present, but `flake.lock` remains pending until `nix` is installed locally.

## Guardrail
- This repo must not be pushed or published until the program-level guardrail of 10 new full rewrites with tests is met.
