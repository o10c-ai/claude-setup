# /implement profile — Phoenix (devenv-managed)

## Read first

- `CLAUDE.md` and the `.claude/docs/` rows it routes to for the area you touch;
  rows marked READ FIRST are not optional.
- `CONTEXT.md` for vocabulary; `docs/adr/` for decisions in the area.

## Branch rules

- Feature branch off `main`, named `feat/<slug>` or `fix/<slug>`.
- Never commit on `main` or `staging`.
- Doc updates (`.claude/docs/`, moduledocs) ship in the same change as the code.

## Feedback loops

Run inside devenv, in this order, fixing until each is green:

1. `devenv shell -- mix lint`
2. `devenv shell -- mix test`

Do not add `@tag :skip`, `# credo:disable`, or lower a gate to pass; if a
guardrail must change, argue the case first (see the `code-quality-steelman`
skill when present).

## Commit

`devenv shell -- git commit` so the repo's git hooks run in the project
environment. No push, no PR unless asked.

## Review

Full committee, not a checkpoint, when the change touches more than one poncho
lib, adds LiveView event handlers, adds routes or nav, creates cross-domain
orchestration, or modifies auth. Otherwise `/review` runs as a checkpoint.
