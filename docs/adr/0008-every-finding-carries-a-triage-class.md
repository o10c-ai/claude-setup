---
status: accepted
date: 2026-09-23
---

# Every finding carries a triage class; only blockers and product calls reach the operator

On the saaspaas reconciled-form Project, waves A–C ended with 17 questions for the
operator, which became wave D (24 slices), which ended with 7 new open questions and
~12 committee notes. Each batch spawned another wave. The questions came from three
sources — implementer `open:` fields, drift checks, `/review` seat notes — and none
carried a severity or a ship impact, so the orchestrator relayed all of them. Most
already had an obvious recommendation. The operator's diagnosis: tokens and iteration
time spent on questions that did not need him, against an imperative to ship.

## Decision

Every `open:` item, drift finding, and non-blocking review note is written with one
**triage class** by the agent that raises it, plus a recommendation:

| Class | Means | Route |
|---|---|---|
| **B** — blocks | merging would ship a defect, a security hole, or miss the Definition of Done | fixed before the run finishes; never deferred |
| **F** — fix | the recommendation is the obvious default and the change is reversible | done in-slice, or batched into ONE leftovers run at the end; no question |
| **D** — defer | real but not this PR's job | ONE backlog issue per run, listing all D items; no follow-up wave |
| **P** — product | a call no experiment settles and no default is obvious | surfaced to the operator with a recommendation; **the recommendation ships unless overridden** |

Only B (when it cannot be fixed autonomously) and P reach the operator. The run's exit
predicate is **ship**: the PR is mergeable with no B open. D and P never block.
A run surfaces at most **3 P items**; a fourth means one of them is really F or D,
and the orchestrator reclassifies before surfacing.

Routed extras (a small fix the orchestrator folds into a later slice) are written to
the synthesis as scope, and the drift check is told to judge them as scope, not drift.

## Considered options

- **Keep relaying every question, ask the operator to triage**: the status quo; it
  moves the triage cost onto the scarcest person and produced wave D.
- **Classify only at the orchestrator**: the raiser has the context; the
  orchestrator reads no code and would classify blind.
- **Zero-open-questions exit predicate**: rejected; it is what made each batch a wave.

## Consequences

- `orchestrate` fragment shape: `open:` becomes `findings:`, one `<class> · <finding> · rec: <default>` per line.
- `review` seats return ✅/❌ as before; every non-blocking note carries F or D.
- `autonomous-run` never stops for an F or D item; it stops `blocked` only on B it cannot fix or on P.
- A P item's recommendation is recorded in the trail as the shipped default, so an
  unanswered question is not an open one.
