---
status: accepted
date: 2026-09-17
---

# One Linear Project = one branch = one PR; slices are sessions, not shippable increments

A Linear Project owns one long-lived branch cut from `base_ref`. Every slice issue
lands its commits on that branch and opens no PR. A terminal **integration issue**,
`blockedBy` every slice, syncs `base_ref` in, runs the `/review` full committee on
the merged head, and opens the single `branch` → `target_ref` PR. A terminal
**QA issue**, human-only and `blockedBy` the integration issue, is the merge gate.

One issue remains one predicate and one `autonomous-run` session. What it is not is
one PR.

## Why this is an ADR and not a revert

The model was already this until `f34d3c7` (2026-09-09), which rewrote `to-issues`
around pstack's decomposition rules and swapped in branch-per-slice as collateral —
the commit message names "one issue = one predicate = one PR = one autonomous-run"
in a clause and says nothing about dropping the feature branch, the integration
issue or the QA issue. It stood for eight days.

Observed cost, on the Sellsy quote-row-rewrite Project: O10C-345 followed the new
model and landed (PR #438). O10C-343 and O10C-344 were built as a stack — 344 based
on 343 rather than on `base_ref`, 343 itself based on `staging` rather than `main` —
and **neither was ever pushed**. Two gate-passing slices sat local and invisible
because no step in the new model forced a push, and the stack could not be landed
piecewise anyway.

## Considered options

- **Keep branch-per-slice, add a landing gate** ("a slice is not done until pushed
  with an open PR against `base_ref`"). Rejected: it fixes the pushing but not the
  reviewing. Slices are tracer bullets sharing schema, fixtures and seams, so a
  per-slice PR reviews a half-built state, and a stalled slice strands everything
  stacked behind it. The gate also cannot prevent `base_ref` drift, which is what
  actually made 344 unlandable.
- **Branch-per-slice with squash-merge to the Project branch, one PR at the end.**
  Rejected as the same thing with extra branches: the merge conflicts arrive at
  integration either way, and the per-slice branch buys isolation no slice wants.
- **No integration issue; the last slice opens the PR.** Rejected: "last" is a DAG
  property that changes when slices are added, and the last slice's session is
  already spending its budget on its own predicate. Integration is its own unit of
  work with its own predicate — the PRD's Definition of Done.

## Consequences

- `autonomous-run` reads `branch` / `base_ref` from the Project, never from the
  checked-out branch, and is explicitly forbidden from cutting a branch or opening
  a PR. `orchestrate` briefs implementers with the Project's branch and ends the run
  at the integration PR plus the surfaced QA issue.
- `to-issues` always appends two terminal issues. A Project with no integration
  issue is malformed.
- `check-issue.sh` is unchanged: it lints issue bodies, which are branch-agnostic.
- The Symphony dispatch machinery (`WORKFLOWS/<slug>.md`, `ready-for-agent` label)
  stays retired. `orchestrate` dispatches.
- Review latency rises: nothing is reviewable until integration. That is accepted —
  the review unit is the feature, and per-slice `/review` checkpoints already catch
  what a diff can show.
