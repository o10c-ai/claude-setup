---
name: orchestrate
description: Run a whole Linear Project to its Definition of Done from a thin conductor session. Spawns one fresh implementer subagent per issue (autonomous-run, turn-budgeted), keeps a synthesis of what the system now does, runs a clean-context drift check against the PRD after every fragment, and preempts and restarts implementers that overrun or drift. Use for "run the project", "orchestrate <project>", or any multi-issue autonomous run.
---

# Orchestrate

Contract skill. Stack-specific limits come from `.claude/orchestrate.md` (slots below);
without a profile the defaults in this file apply. Phase 0 runs
`~/.claude/skills/project-profile/scripts/check-profile.sh` for **all** contracts: every
implementer will invoke `implement` and `review`, so an `invalid` profile stops the run
here ("run `/project-profile`"), not after the first fragment. The **orchestrator** is this session.
It never reads code, never edits files outside `.audit/`, and never implements. Its whole
context is: the operational intent, the dependency graph, the synthesis, and the trail.

Vocabulary (CONTEXT.md): operational intent, implementer, fragment, synthesis, drift
check, preemption, turn budget.

## Launching (one session per Linear Project)

Parallel work across projects is N orchestrator sessions, each in its own worktree:

```
~/.claude/skills/orchestrate/scripts/launch.sh <project-slug> [--name <dir>] [--no-up] [--dry-run]
```

Run it from any checkout of the project. It reads the profile's `## Isolation` keys
(`hook:`, `base_ref:`, `worktrees:`), creates the worktree through the project's hook
(or plain `git worktree add`), captures the hook's env (ports, partitions), runs the
hook's `up` (services, first build), and opens a cmux workspace running `claude` with
`/orchestrate <slug>` as the first prompt and `linear.project=<slug>` on the telemetry
resource. Hook protocol is in the script header; `examples/phoenix/.claude/orchestrate.md`
shows a profile that names one. Within a project, implementers stay serial until
`## Concurrency` and an `## Isolation` recipe say otherwise.

## 0. Load the intent

1. `linear project view <slug>` and its PRD document; `linear issue list --project <slug>`
   with states and `blockedBy` edges. This is the **operational intent**. It is read-only
   for the whole run; no one edits issue bodies or the PRD mid-run.
2. Create `.audit/<project-slug>/` with `trail.tsv` (show-me-your-work rows) and
   `synthesis.md` (template below). First trail row: the Project's Definition of Done,
   taken from the PRD verbatim, as the run's exit predicate.
3. Order: riskiest-unknown first as `to-issues` left it; an issue is runnable when every
   blocker is `Done`. **Serial by default**: one implementer at a time. Parallel
   implementers require the profile's `## Isolation` recipe (worktree + state isolation
   per issue) and are opt-in.

## 1. Spawn an implementer

One fresh `general-purpose` subagent per issue, `run_in_background: true`. The brief is
self-contained and contains **only**:

- the issue body verbatim (Predicate, Verify, Review gate, Depends on, Prototype);
- the PRD's Definition of Done and Data Shape sections;
- the branch name and `base_ref`; the instruction to work in the current worktree;
- the turn budget and the checkpoint discipline;
- the instruction: "Run the `autonomous-run` skill, Run mode, for this issue. Return a
  **fragment** in the shape below and nothing else."

On a **restart** after preemption, append exactly one of: nothing (budget overrun), or
the drift check's finding for this issue (drift). Never the predecessor's fragment, trail
rows beyond SHAs, resume notes, or your own summary of its work.

The implementer's own opening phase (autonomous-run Run step 1) judges whatever is on the
branch against the predicate and reverts by commit what does not serve it. That is the
whole guard against a drifting predecessor: the code is data, the narrative never crosses.

**Turn budget.** Default 40 tool calls or 45 minutes per implementer, whichever first
(profile `## Budgets`). The implementer is told the budget; you do not trust it to stop.
Arm a `Monitor` on the issue's trail file (`tail -n0 -F .audit/<issue-id>.tsv`) and a
background `until` on wall time. A trail that has not grown for 15 minutes counts as
overrun.

## 2. Collect the fragment

Fragment shape (the implementer returns exactly this):

```
issue: <id>
head: <sha>            base: <base_ref>
predicate: met | not met | blocked
review: clean | ❌ <n> | not run
landed: <2-5 lines, behaviour not files>
decisions: <one line each, with trail row ts>
deviations: <anything done differently from the issue body, or "none">
facts: <new facts about the codebase worth carrying forward, or "none">
open: <questions needing a product call, or "none">
```

`blocked` with an `open:` question is the implementer's only way to ask; it cannot ask
mid-flight. Answer by re-briefing (spawn a fresh implementer with the answer appended) or,
for a product call, pause the run and surface it to the operator.

## 3. Update the synthesis, then run the drift check

Rewrite `synthesis.md` from the fragment (do not append; the file is the current state):

```
# <project> — synthesis   (updated <ts>, after <issue-id>)
## What the system now does        <cumulative, behaviour-level, 10-30 lines>
## Issues                          <table: id | state | head | predicate | review>
## Decisions                       <accumulated, one line each>
## Deviations                      <accumulated, with the issue that introduced each>
## Open                            <unanswered product questions>
```

Then spawn the **drift check**: a fresh `general-purpose` subagent whose brief is the
PRD document, the issue list with bodies, and `synthesis.md`. Nothing else, and it is
read-only. It answers:

```
execution drift: <issue-id>: <what the synthesis says was built that the issue did not ask for, or what the issue asked for that is missing> | none
intent drift: <where the issues, as built so far, no longer add up to the PRD's Definition of Done or Data Shape> | none
severity: low | high   (per finding)
```

Route the result: **execution drift** on an in-flight or just-finished issue → preempt or
re-brief that implementer with the finding (autonomous). **Intent drift** → pause the run,
write the finding to the trail, surface it to the operator; it is a product call. A
finding of `none` is the common case and gets one trail row.

## 4. Preempt

Preemption is a hard stop, never a handoff: `TaskStop` the implementer. Verified on
Claude Code 2.1.266: the stop kills the agent and its foreground shell command; the
worktree stays exactly as it was, committed and uncommitted edits included. Record the
head SHA and the reason in the trail. Then go to step 1 with a restart brief. Triggers:

- turn or time budget exceeded, or the trail silent for 15 minutes;
- an execution-drift finding naming the issue;
- a fragment with `predicate: met` but `review: ❌` twice in a row for the same seat.

Two restarts on the same issue without the predicate moving is a dead end: pause and
surface it, with both fragments and the drift findings, rather than a third spawn.

## 5. Finish

The run ends when every issue is `Done` and the last slice's `/review` full committee is
clean on its head. Final trail row: the Definition of Done predicate and its evidence.
`cmux clear-progress`, `cmux notify`. Reply with: issues run, restarts and why, drift
findings and how they were routed, open product questions, synthesis path.

## Profile slots (`.claude/orchestrate.md`)

| Slot | Contents | Default |
|---|---|---|
| `## Budgets` | per-implementer tool-call and wall-time caps; silence timeout | 40 calls / 45 min / 15 min silent |
| `## Isolation` | worktree + state recipe that makes two implementers safe at once (ports, DB partitions) | none → serial only |
| `## Concurrency` | max implementers in flight when Isolation is defined | 1 |
| `## Drift check` | extra project documents the checker must read (architecture invariants, glossary) | PRD + issues + synthesis only |

## Context discipline (why this shape)

The orchestrator's context is bounded by construction: intent once, one fragment per
issue, one synthesis rewrite, one drift verdict. Implementers are bounded by the turn
budget and by `to-issues` sizing. The drift check is bounded by reading only documents.
Nothing authored by a stopped implementer flows to its replacement. See ADR 0005.
