> [!IMPORTANT]
> This repository is part of a Codex-assisted rewrite experiment. All changes are manually reviewed, a human remains in the loop, and missing behavior is tracked explicitly rather than hidden. The project exists for fun, research, language learning, AI agent workflow/planning, interop experiments, and code review testing.
# haskell-stakeholder

Haskell parity target under `stakeholder-circus`.

## Status
- Validated wider-matrix repo held for publication.
- Imported Rust history is preserved for attribution and auditability.
- Classic-six and modern-core are implemented locally with a pure core pipeline and deterministic normalized JSON.
- Native validation passes via `ghcup run --ghc 9.6.7`.
- Docker image build, in-image test, and runtime smokes pass.
- Docker validation is the publishability gate for this repo.
- This repo remains local-only and is not for push until the program-wide 10-full-rewrites publication guardrail is met.

## Role
- Correctness-oracle parity target.
- Purpose: Pure-core parity lane used to validate the deterministic event model with IO constrained to CLI and test boundaries.
- Program category: correctness, research

## Commands
- `fourmolu -m check app src test`
- `hlint .`
- `ghcup run --ghc 9.6.7 -- cabal build all`
- `ghcup run --ghc 9.6.7 -- cabal test all`
- `docker build -t haskell-stakeholder .`
- `docker run --rm haskell-stakeholder --list-values`

## Documentation
- [AI disclosure](AI_DISCLOSURE.md)
- [Parity](PARITY.md)
- [Explicit gaps](GAPS.md)
- [Remotes](docs/remotes.md)
- [Provenance](docs/provenance.md)
- [Toolchain](docs/toolchain.md)
- [Traceability](docs/traceability/first-push-families.md)
