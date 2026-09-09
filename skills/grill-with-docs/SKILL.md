---
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, settles empirical questions by running them, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Use when user wants to stress-test a plan against their project's language and documented decisions.
---

> OWN override of the vendored mattpocock-skills `grill-with-docs`. Upstream body
> kept; three rules added from pstack (classify before asking, design it twice,
> evidence in ADRs). Reference formats are bundled in this skill directory:
> `CONTEXT-FORMAT.md` and `ADR-FORMAT.md` (copies of the upstream files, which
> live at `vendor/mattpocock-skills/skills/engineering/grill-with-docs/` in the
> claude-setup checkout).

<what-to-do>

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, in prose, waiting for feedback on each question before continuing.

**Classify every question before asking it.** Three kinds:

1. Answerable by reading the codebase. Explore instead of asking.
2. Answerable by running something (behaviour, timing, layout, output, whether a test separates). Run it via the `prototype` skill, report the result with its branch or SHA, and treat that as the answer. Do not ask the human a question an experiment can settle.
3. A product or preference call no run can settle. Ask this one.

**Design it twice on one-way doors.** When a decision is hard to reverse or has a wide blast radius, produce two structurally distinct candidate shapes before recommending one, whole-shape alternatives rather than point fixes inside one shape. Prefer the candidate that hides more behind a smaller public surface. Reject candidates with shallow modules, pass-through layers, or leaked internals. Reversible decisions get one recommendation and move on.

</what-to-do>

<supporting-info>

## Domain awareness

During codebase exploration, also look for existing documentation:

### File structure

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily, only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account'. Do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up; capture them as they happen. Use the bundled `CONTEXT-FORMAT.md`.

`CONTEXT.md` should be totally devoid of implementation details. It is a glossary and nothing else.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse.** The cost of changing your mind later is meaningful.
2. **Surprising without context.** A future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off.** There were genuine alternatives and you picked one for specific reasons.

If any of the three is missing, skip the ADR. Use the bundled `ADR-FORMAT.md`. **Evidence, not prose:** when a prototype settled the decision, the ADR cites its branch or SHA and any screenshot or measurement path. When two candidate shapes were compared, the ADR lists both and the reason the loser lost.

### Hand-off

When the plan is grilled, the natural next step is `/to-prd`. Carry into it: the definition of done as a predicate, the data shape, the one-way-door decisions, and every prototype SHA.

</supporting-info>
