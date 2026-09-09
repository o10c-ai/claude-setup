## Budgets

- 40 tool calls or 45 minutes per implementer, whichever first.
- Trail silent for 15 minutes counts as overrun.
- Migrations and multi-lib refactors: 60 calls / 60 minutes (the issue body says
  which; `to-issues` sizing already counts them double).

## Isolation

Serial only until this section names a recipe. When parallel is wanted:

- one git worktree per issue under `../<repo>-<issue-id>/`, created from `base_ref`;
- a port slot per worktree for the dev server (`PORT=4000 + slot`);
- `MIX_TEST_PARTITION=<issue-id>` so each implementer's `mix test` owns its database;
- `_build` is worktree-local: the first `mix` call recompiles, budget for it.

## Concurrency

1

## Drift check

In addition to the PRD, the issue list, and the synthesis, the checker reads
`CONTEXT.md` (glossary) and `docs/adr/` titles, so a synthesis that renames a domain
term or contradicts an accepted ADR is reported as intent drift.
