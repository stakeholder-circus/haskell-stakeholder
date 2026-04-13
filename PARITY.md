# Parity

## Role

Correctness-oracle parity target.

## Parity class

- full-parity-target

## Current tranche

- classic-six plus modern-core implemented locally
- later packet families remain grouped fallback with explicit gaps
- local-only until the program-level publication guardrail is met

## Method and Review Model

- Codex-assisted
- Manually reviewed
- Human in the loop
- Derived from giacomo-b/rust-stakeholder where applicable
- Missing behavior must fail fast and be recorded explicitly in GAPS.md

## Implementation policy

- pure core pipeline
- IO only at CLI and test boundaries
- deterministic normalized JSON output
- exact CLI-schema reuse via stakeholder-core contract notes and traceability references
