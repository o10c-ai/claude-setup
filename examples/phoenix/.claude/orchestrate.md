## Budgets

- 40 tool calls or 45 minutes per implementer, whichever first.
- Trail silent for 15 minutes counts as overrun.
- Migrations and multi-lib refactors: 60 calls / 60 minutes (the issue body says
  which; `to-issues` sizing already counts them double).

## Isolation

One worktree per Linear Project, created by `launch.sh` through the hook below;
implementers inside a project run serially until `## Concurrency` says otherwise.

- hook: `.claude/scripts/orchestrate-isolate.sh` — implements `add <branch> <base_ref>`
  (create the worktree, last stdout line = its path), `env` (KEY=VALUE lines: `PORT`,
  `MIX_TEST_PARTITION`, …), `up` (services + first build). Wrap the project's own
  worktree tooling; do not duplicate it.
- base_ref: `origin/main`
- one git worktree per project (or per issue when parallel) under `../<repo>-<name>/`;
- a port slot per worktree for the dev server (`PORT=4000 + slot`);
- `MIX_TEST_PARTITION=<issue-id>` so each implementer's `mix test` owns its database;
- `_build` is worktree-local: the first `mix` call recompiles, budget for it.

## Concurrency

1

## Drift check

In addition to the PRD, the issue list, and the synthesis, the checker reads
`CONTEXT.md` (glossary) and `docs/adr/` titles, so a synthesis that renames a domain
term or contradicts an accepted ADR is reported as intent drift.
