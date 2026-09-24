---
status: accepted
date: 2026-09-24
---

# A run ships at a ship line fixed before its first spawn; deferred work has one home and one re-entry

ADR 0008 classed every finding so that only blockers and product calls reach the
operator. On the saaspaas reconciled-form Project the waves still came: the operator
answered the P items in a drilling session, the answers added scope, the added scope
became a new wave of the same Project, and that wave ended with its own questions.
Three gaps: the run had no line it was allowed to ship at, an operator's answer was
not itself triaged, and a D item had nowhere to go except the next wave.

## Decision

1. **Ship line.** `orchestrate` fixes, before spawning anything, the PRD's Definition
   of Done predicate, its Out of Scope list, a run budget, and a scope freeze on the
   issue list. It is the first trail row and the first synthesis section. A prose DoD
   or a missing Out of Scope section stops the run at phase 0 ("run `/to-prd`").
2. **Four questions, in order, for every finding and every answer.** Fails the DoD or
   ships a defect → B. Outside the ship line → D, merit notwithstanding. Obvious
   reversible default → F. Else P, with the recommendation that will ship. The
   orchestrator re-runs the four on what it receives, including the operator's
   answers: an answer is an F or a D, never a new issue, a redrawn line, or a wave.
3. **Intent drift and budget exhaustion pause on one decision brief each**, whose
   default is always "ship the DoD as written, defer the gap" (or "extend once"). An
   amended intent is a new Project through `to-prd` and `to-issues`, not this run.
4. **One deferred issue per run**, outside the Project, label `deferred`, a table of
   D items with source and recommendation. The run does nothing else with it.
5. **Re-entry is the pipeline's first step.** `to-prd` reads the open deferred issues
   for the area and decides each item once: absorbed into the Solution, or named on
   the Out of Scope list. `to-issues` places absorbed items in slices and closes a
   deferred issue once every item is absorbed or named out. `to-prd`'s Out of Scope
   section now names items one per line, including the adjacent work a session will
   be tempted to pull in, because each named item is D downstream by construction.

## Considered options

- **Zero-scope-growth by prohibition only** ("do not add issues mid-run"): rejected;
  without a home for the deferred items the prohibition is what the drilling session
  routed around.
- **Let the orchestrator absorb small operator answers into new slices**: rejected;
  that is a wave with a smaller name, and the drift check would have to learn a
  moving intent.
- **A per-run time box with no reduced-ship option**: rejected; a box that can only
  extend is not a box. The reduced-ship option exists only while the DoD still holds
  without the dropped slices, so the line is never relaxed to declare victory.
- **A separate backlog-grooming skill**: rejected for now; the re-entry point already
  exists in `to-prd` step 1 and adding a stage would be one more place to forget.

## Consequences

- `orchestrate`: phase 0 draws the ship line; step 2 carries the four questions and
  the answers rule; step 3's intent-drift pause and step 4's budget pause are
  decision briefs with a shipping default; step 5 writes the deferred issue.
- `autonomous-run`: an implementer classes anything outside the brief's ship line as
  D and neither builds nor asks about it.
- `to-prd`: reads deferred issues first; Out of Scope is a named list.
- `to-issues`: places absorbed deferred items and closes consumed deferred issues;
  the published issue list is frozen for the run.
- Profile `## Budgets` gains a run budget (default 1.5 × per-implementer cap ×
  runnable issues).
- The cost accepted: a good idea raised late waits one Project. That is the price of
  a run that ends.
