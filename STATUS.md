# haskell-stakeholder Status

Last updated: 2026-04-13 CEST

- Role: `validated-wider-matrix`
- Parity class: `full-parity-target`
- Phase target: `native-and-docker-validated-wider-matrix`
- Phase state: `complete`
- Phase completeness: `100%`
- Program state: `publication-held`
- Program completeness: `58%`
- Rewrite completeness: `58%`
- Functionality completeness: `54%`
- Branch: `main`
- Origin: `git@github.com:stakeholder-circus/haskell-stakeholder.git`
- Upstream: `https://github.com/giacomo-b/rust-stakeholder`

## Blockers
- `flake.lock` is now generated through the installed Nix toolchain.
- Remote creation/push is blocked by the program-level 10-full-rewrites publication guardrail.
- GitHub required-check binding is deferred until the repo has a remote and stable CI contexts.

## Next
- Keep later packet families fail-fast/grouped until their dedicated tranche.
- Keep the repo publication-held until the 10-rewrite threshold is met.

## Canonical references
- [`stakeholder-core/docs/program/rewrite-status-matrix.md`](/Users/davidsupan/shareholder/stakeholder-core/docs/program/rewrite-status-matrix.md)
- [`stakeholder-core/status/JOB_STATUS.md`](/Users/davidsupan/shareholder/stakeholder-core/status/JOB_STATUS.md)
