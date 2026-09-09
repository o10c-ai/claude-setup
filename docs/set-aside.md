# Set aside, not rejected

pstack (`vendor/pstack-claude`) ships far more than the autonomy layer adopted
here. The pieces below were read, judged useful, and deliberately not wired in.
Each entry: what it does, why not now, and the trigger that reopens it.

## orchestrate / autopilot playbooks and the `orch` CLI — partly adopted (2026-09-09)

**What.** `poteto-mode/playbooks/orchestrate.md`, `autopilot-full.md`,
`autopilot-stack.md`: a lead session that owns a queue of PRs, spawns one owner
per PR, allocates file boundaries, holds merge authority, and runs standing
orders on an audit tick. `orch` is the CLI that tracks the fleet.
**Adopted, scaled to one Project.** `skills/orchestrate` (ADR 0005): a thin
orchestrator, one fresh implementer per issue under a turn budget, a synthesis,
a clean-context drift check after every fragment, preemption as a hard stop.
Serial by default; the reason was context lifecycle, not fleet throughput.
**Still set aside.** File-boundary allocation, merge authority, standing orders
on an audit tick, and the `orch` CLI.
**Revisit when.** Parallel implementers are enabled through a profile
`## Isolation` recipe and merge ordering becomes a manual chore.

## Ten live lanes and the mandatory perf gate

**What.** `multi-phase-plan.md`'s verification rule: every PR proves unit +
live + perf; the live block is ten swarm lanes at the head SHA, each a
scenario, a screenshot, and a pass predicate; perf is dual-sided against
trunk.
**Why not now.** Ten parallel lanes is fleet-sized. The lane *form* survived:
the `/review` seat (trigger, rubric, evidence line) and the two contract seats
(audit, regression) are the lanes kept unconditionally (ADR 0003). Perf runs
only when an issue's `perf:` line names a hot path.
**Revisit when.** A project has a real screenshot harness and a live surface
where regressions escape unit tests; scale the count from the issue, not to
ten.

## `architect` / `arena` / `interrogate` multi-model panels

**What.** `architect` designs a change twice from first principles; `arena`
races several models on one brief; `interrogate` runs N readonly reviewers,
one per model, and synthesises Act on / Consider / Noted / Dismissed.
**Why not now.** The signal in all three is model diversity, which costs N
full contexts per call. `grill-with-docs` already designs one-way doors twice
in one context, and `/review` seats give independent adjudication with one
fresh subagent per seat.
**Revisit when.** A `/review` seat verdict is overturned after merge more
than once, or a design ADR is reversed within a quarter. Then `interrogate`'s
lead-judgment filters and `rubric.md` are the first thing to port.

## `babysit` / `fix-ci`

**What.** `babysit` watches a PR through CI, review bots, and merge; `fix-ci`
diagnoses a red pipeline and pushes the fix.
**Why not now.** No CI bot posts review comments on the active projects, and
`autonomous-run` already picks its wake mechanism (`Monitor` / background
`until`) for the CI-green case.
**Revisit when.** A bot (Bugbot or similar) starts posting on PRs; port
`references/bugbot-triage.md` (fix / dismiss / ask, versioned skip patterns)
with it.

## 30-minute audit tick and `/loop`

**What.** Orchestrate's standing order to re-audit the fleet every 30 minutes,
implemented on `/loop`.
**Why not now.** `/loop` is off with `disableBundledSkills`; the wake
mechanisms in `autonomous-run` cover single-condition waits. A periodic tick
without a fleet re-reads nothing new.
**Revisit when.** `/loop` is re-enabled (flip `disableBundledSkills`, use
`skillOverrides` per skill); it then replaces only the fixed-interval poll case.

## `setup-pstack` model sheet

**What.** `~/.claude/pstack-models.md`: a per-role model table (swarm workers,
interrogate reviewers, …) read at runtime.
**Why not now.** Every adopted skill runs on the session's model or a single
subagent default; there is no role table to fill.
**Revisit when.** Any panel skill above is adopted.

## AskUserQuestion and plan mode

**What.** Several pstack playbooks pause on `AskUserQuestion` or enter plan
mode for sign-off.
**Why not now.** The lean preset denies both (`permissions.deny`), on purpose:
questions are asked in prose, one at a time, and plans are stated then
executed. The adopted skills were rewritten to that posture.
**Revisit when.** Never as a default; re-enable per tool by removing it from
the deny list if a specific workflow needs the structured prompt.
