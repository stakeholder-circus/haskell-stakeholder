# haskell-stakeholder AGENTS

1. Preserve imported Rust history and explicit provenance docs; do not present this repo as greenfield work.
2. This repo is in the active first-push implementation tranche, but it remains local-only until the program-level publication guardrail is met.
3. Required commands in this tranche:
   - `fourmolu -m check app src test`
   - `hlint .`
   - `cabal build all`
   - `cabal test all`
   - `docker build -t haskell-stakeholder .`
4. Keep `origin` intended for `stakeholder-circus/haskell-stakeholder` and `upstream` pointed at `https://github.com/giacomo-b/rust-stakeholder`.
5. Promotion work must preserve a pure core pipeline, deterministic normalized JSON, explicit fail-fast gaps, and traceability back to Rust, Java, and stakeholder-core.
6. Do not hide missing behavior behind placeholders; record it in `GAPS.md` instead.
