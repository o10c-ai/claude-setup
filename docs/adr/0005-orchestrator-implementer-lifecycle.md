---
status: accepted
date: 2026-09-09
---

# Multi-issue runs use a thin orchestrator, fresh implementers per issue, a synthesis, and clean-context drift checks

A flat `autonomous-run` session accumulates every file read and every failed attempt
until compaction drops the reasoning mid-cycle. For a whole Linear Project the run is
split: an **orchestrator** session that holds only the intent, the synthesis, and the
trail; one fresh **implementer** subagent per issue under a turn budget, returning a
fixed-shape **fragment**; a **drift check** subagent with clean context after every
fragment, comparing the synthesis against the PRD and issues; and **preemption** as a
hard stop plus restart. A replacement implementer starts in the same worktree on the
same branch with the tree as it was, judges the existing commits against the predicate
in its opening phase, and receives nothing authored by its predecessor except, on
drift, the drift check's finding.

## Considered options

- **Flat session plus compaction** (pstack's and our previous `autonomous-run`):
  no coordination cost, worst degradation on long issues, no drift signal.
- **Session chaining with an external driver**: cleanest context, but needs a
  driver loop outside Claude Code (pstack's `orch`), which we set aside.
- **Salvage step by a separate clean agent before restart**: rejected as
  redundant; the replacement implementer reads the branch against the spec
  anyway, and a separate agent only adds a spawn and a second diff read.
- **Reset to `base_ref` on restart**: rejected; the code is data, the
  narrative is the contamination. The replacement keeps what serves the
  predicate and reverts by commit what does not.

## Evidence (Claude Code 2.1.266, 2026-09-09)

- A `general-purpose` subagent has the `Agent` tool and can spawn its own
  subagent (Explore returned `PONG`), so an implementer can run `/review` seats.
- `Monitor` on `tail -n0 -F <trail>.tsv` fires on append within seconds.
- `TaskStop` on a running implementer killed the agent and its foreground
  shell loop (ticks stopped at the stop time) and left the worktree intact:
  the prior commit present, the uncommitted file present.

## Consequences

- Serial by default; parallel implementers need a profile `## Isolation`
  recipe (worktree plus state isolation) and are opt-in.
- Execution drift is handled autonomously (re-brief or preempt); intent drift
  pauses the run for the operator, because it is a product call.
- `docs/set-aside.md`'s orchestrate entry is superseded by this scaled form;
  file-boundary allocation, merge authority, and the audit tick stay set aside.
