---
name: orchestrate
description: Run a whole Linear Project to a ship line fixed before the first spawn (DoD predicate, Out of Scope, run budget, frozen issue list) from a thin conductor session. Spawns one fresh implementer subagent per issue (autonomous-run, turn-budgeted), keeps a synthesis of what the system now does, runs a clean-context drift check against the PRD after every fragment, preempts and restarts implementers that overrun or drift, triages every finding and operator answer against the ship line, and leaves one deferred issue instead of a next wave. Use for "run the project", "orchestrate <project>", or any multi-issue autonomous run.
---

# Orchestrate

Contract skill. Stack-specific limits come from `.claude/orchestrate.md` (slots below);
without a profile the defaults in this file apply. Phase 0 runs
`~/.claude/skills/project-profile/scripts/check-profile.sh` for **all** contracts: every
implementer will invoke `implement` and `review`, so an `invalid` profile stops the run
here ("run `/project-profile`"), not after the first fragment. The **orchestrator** is this session.
It never reads code, never edits files outside `.audit/`, and never implements. Its whole
context is: the operational intent, the dependency graph, the synthesis, and the trail.

Vocabulary (CONTEXT.md): operational intent, ship line, implementer, fragment,
synthesis, drift check, preemption, turn budget, triage class, deferred issue.

**The run ships once.** A run ends at its ship line or it pauses on a decision brief;
it never ends with a list of questions, and nothing it produces opens another wave of
the same Project. Questions raised during the run are triaged against the ship line
(step 2); what falls outside it goes to one deferred issue (step 5) and re-enters
through `to-prd` / `to-issues` as part of the next Project, never through a drilling
session bolted onto this one. ADR 0009.

## Launching (one session per Linear Project)

Parallel work across projects is N orchestrator sessions, each in its own worktree:

```
~/.claude/skills/orchestrate/scripts/launch.sh <project-slug> [--name <dir>] [--title <words>] [--no-up] [--dry-run]
```

Run it from any checkout of the project. It reads the profile's `## Isolation` keys
(`hook:`, `base_ref:`, `worktrees:`, `workspace_prefix:`), creates the worktree through the project's hook
(or plain `git worktree add`), captures the hook's env (ports, partitions), runs the
hook's `up` (services, first build), and opens a cmux workspace running `claude` with
`/orchestrate <slug>` as the first prompt and `linear.project=<slug>` on the telemetry
resource. The workspace is titled `<workspace_prefix> · <title>`: `--title`, else the first
three words of the Linear Project's name. Hook protocol is in the script header; `examples/phoenix/.claude/orchestrate.md`
shows a profile that names one. Within a project, implementers stay serial until
`## Concurrency` and an `## Isolation` recipe say otherwise.

## 0. Load the intent

1. `linear project view <slug>` and its PRD document; `linear issue list --project <slug>`
   with states and `blockedBy` edges. This is the **operational intent**. It is read-only
   for the whole run; no one edits issue bodies or the PRD mid-run.
2. **Fix the ship line** before anything is spawned. It has four parts, and it is the
   first trail row and the first section of `synthesis.md`:
   - the PRD's **Definition of Done** predicate, verbatim: the run's exit predicate;
   - the PRD's **Out of Scope** list, verbatim: every item on it is class D by
     construction, whatever an implementer, a seat, or the operator later thinks of it;
   - the **run budget**: wall clock for the whole run (profile `## Budgets`, default
     1.5 × per-implementer cap × runnable issues), started now;
   - the **scope freeze**: the issue list is closed. No issue is added to the Project
     mid-run, no issue body or PRD section is edited, and nothing not covered by an
     issue body or the DoD is built. New scope is D.
   Stop here, not later, when the line cannot be drawn: a DoD that is prose rather
   than a command, test, diff or measurement, or a PRD with no Out of Scope section,
   means "run `/to-prd`". That is cheaper than discovering the gap at wave two.
3. Create `.audit/<project-slug>/` with `trail.tsv` (show-me-your-work rows) and
   `synthesis.md` (template below).
4. Order: riskiest-unknown first as `to-issues` left it; an issue is runnable when every
   blocker is `Done`. **Serial by default**: one implementer at a time. Parallel
   implementers require the profile's `## Isolation` recipe (worktree + state isolation
   per issue) and are opt-in.

## 1. Spawn an implementer

One fresh `general-purpose` subagent per issue, `run_in_background: true`. The brief is
self-contained and contains **only**:

- the issue body verbatim (Predicate, Verify, Review gate, Depends on, Prototype);
- the ship line (Definition of Done, Out of Scope) and the PRD's Data Shape section;
- the Project's branch name and `base_ref` (one Project = one branch = one PR — the
  implementer commits there and opens no PR); the instruction to work in the current worktree;
- the turn budget and the checkpoint discipline, and "commit through the hooks; never
  `--no-verify`" (a brief that said otherwise let lint debt pile up silently);
- the triage classes and the four-question procedure (below), and "fix F items in-slice;
  do not return them as questions; anything outside the ship line is D whatever its merit";
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
findings: <one per line: B|D|P · <finding> · rec: <default>; or "none">
```

**Triage classes** (ADR 0008). Every finding — an implementer's, a drift check's, a
review seat's non-blocking note — carries exactly one, set by whoever raises it:

| Class | Means | Route |
|---|---|---|
| **B** | merging would ship a defect, a security hole, or miss the DoD | fixed before Finish |
| **F** | the recommendation is the obvious, reversible default | done, never asked (in-slice, or the one leftovers run) |
| **D** | real, not this PR's job | one backlog issue for the whole run |
| **P** | product call, no obvious default | operator, with a recommendation that ships unless overridden |

**The procedure.** Whoever raises a finding classes it by asking these four questions
in order and stopping at the first yes. The orchestrator re-runs the same four on every
finding it receives and on every answer the operator gives; a class that survives the
re-run is final.

1. Without it, does the ship line's DoD predicate fail, or does the merge ship a
   defect or a security hole? → **B**.
2. Is it outside the ship line (on the Out of Scope list, or not covered by any issue
   body or the DoD)? → **D**. Merit does not move this answer; the deferred issue does.
3. Is there a default the raiser would pick, reversible by one commit? → **F**.
4. Otherwise → **P**, and the raiser writes the recommendation it would ship.

An implementer fixes its own F items, so its fragment carries B, D, and P only.
`predicate: blocked` with a B or P finding is the implementer's only way to ask; it
cannot ask mid-flight. A B is answered by re-briefing. A P that blocks the predicate is
paused on; a P that does not is recorded with its recommendation and the run goes on.

**Answers are findings too.** When the operator answers a P (or a paused B), the answer
goes through the same four questions: it becomes an F (the one leftovers run, or a
re-brief if the issue is in flight) or a D. An answer that would add scope, add an
issue, or change the DoD is not an answer to this run: record it as D with the
operator's wording, ship the recommendation that was on the table, and let the next
Project pick it up. No answer reopens the grill, redraws the ship line, or starts a
wave.

## 3. Update the synthesis, then run the drift check

Rewrite `synthesis.md` from the fragment (do not append; the file is the current state):

```
# <project> — synthesis   (updated <ts>, after <issue-id>)
## Ship line                       <DoD predicate · Out of Scope · run budget: elapsed/cap · scope frozen at <ts>>
## What the system now does        <cumulative, behaviour-level, 10-30 lines>
## Issues                          <table: id | state | head | predicate | review>
## Decisions                       <accumulated, one line each>
## Deviations                      <accumulated, with the issue that introduced each>
## Routed extras                   <small fixes folded into a later slice: what, from which issue, into which>
## Findings                        <by class: B (must be empty at Finish) · F (pending leftovers) · D · P with rec>
```

Then spawn the **drift check**: a fresh `general-purpose` subagent whose brief is the
PRD document, the issue list with bodies, and `synthesis.md`. Nothing else, and it is
read-only. It judges the **Routed extras** section as scope, not as drift, and does not
re-raise a finding already listed under **Findings**. It answers:

```
execution drift: <issue-id>: <what the synthesis says was built that the issue did not ask for, or what the issue asked for that is missing> | none
intent drift: <where the issues, as built so far, no longer add up to the PRD's Definition of Done or Data Shape> | none
class: B | F | D | P   (per finding, ADR 0008)
```

Route the result by class first: F and D findings go straight to **Findings** with no
pause and no re-brief unless the issue is still in flight. Then: **execution drift** on an in-flight or just-finished issue → preempt or
re-brief that implementer with the finding (autonomous). **Intent drift** → pause the run,
write the finding to the trail, surface it to the operator as a `decision-brief` whose
recommendation is always the same: **ship the DoD as written and defer the gap** (the
gap becomes a D item with the checker's wording). The other option is to close this run
at the ship line and open a new Project for the amended intent through `to-prd` and
`to-issues`; the operator picks it explicitly or the default ships. There is no third
option where this run absorbs the change. A finding of `none` is the common case and
gets one trail row.

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

**Run budget exhausted** (ship line, step 0) with slices still not `Done`: finish the
in-flight implementer, then pause on one `decision-brief`. Options are ship reduced
(name the slices that become D and whether the DoD still holds without them; if it
does not, this option is unavailable) or extend once by a stated amount. The
recommendation is whichever keeps the DoD; an extension is granted once per run.

## 5. Finish

The exit predicate is **ship**: every slice `Done`, no B finding open, the integration
issue has opened the single `branch` → `target_ref` PR with the `/review` full committee
clean on its head, and the human-only QA issue is surfaced to the operator as the merge
gate. Before that, in this order:

1. **F leftovers**: every pending F finding goes to ONE implementer run (one brief, one
   commit series), not to a new wave.
2. **D**: one **deferred issue** per run, outside the Project, in the team backlog,
   label `deferred`, title `Deferred: <Project name>`. Body: one table row per D item,
   columns `item | raised by (issue id, seat, drift check, or operator) | recommendation |
   why deferred (out of scope / not this PR's job / answer arrived past the ship line)`,
   plus the PR link. Link it from the PR body. Nothing else happens to it in this run:
   no follow-up wave, no second Project cut from it here. It is consumed by the next
   `to-prd` / `to-issues` for the area (those skills read open `deferred` issues at
   their first step and close the ones they absorb).
3. **P**: at most 3 reach the operator, each as a `decision-brief` whose recommendation is stated as
   "shipping <rec> unless you say otherwise". A fourth means one is really F or D:
   reclassify. Record each P's recommendation in the trail as the shipped default. An
   answer is triaged like any finding (step 2): F into the leftovers run, D into the
   deferred issue; never a new issue in this Project.

A run never ends by asking "what next?"; unanswered P items are already decided. Final trail row: the Definition of Done predicate and its evidence.
`cmux clear-progress`, `cmux notify`. Reply with: the ship line and whether it held,
run budget used, issues run, restarts and why, findings by class and where each went
(leftovers commits, the deferred issue id, the ≤3 P defaults), synthesis path.

## Profile slots (`.claude/orchestrate.md`)

| Slot | Contents | Default |
|---|---|---|
| `## Budgets` | per-implementer tool-call and wall-time caps; silence timeout; run budget (wall clock for the whole run) | 40 calls / 45 min / 15 min silent / 1.5 × cap × runnable issues |
| `## Isolation` | worktree + state recipe that makes two implementers safe at once (ports, DB partitions) | none → serial only |
| `## Concurrency` | max implementers in flight when Isolation is defined | 1 |
| `## Drift check` | extra project documents the checker must read (architecture invariants, glossary) | PRD + issues + synthesis only |

## Context discipline (why this shape)

The orchestrator's context is bounded by construction: intent once, one fragment per
issue, one synthesis rewrite, one drift verdict. Implementers are bounded by the turn
budget and by `to-issues` sizing. The drift check is bounded by reading only documents.
Nothing authored by a stopped implementer flows to its replacement. See ADR 0005.

The run's *scope* is bounded the same way: the ship line is fixed before the first
spawn and every finding, drift verdict and operator answer is classed against it, so
the only ways a run can grow are a one-time budget extension and a re-brief of an
in-flight issue. Everything else leaves through the deferred issue. See ADR 0009.
