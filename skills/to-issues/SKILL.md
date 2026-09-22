---
name: to-issues
description: Break a PRD or plan into Linear issues where each issue is one runnable predicate and one autonomous-run session, all landing on the Project's single long-lived branch behind one PR. Vertical slices as child issues of a feature Project, ordered riskiest-unknown-first, wired with blockedBy, terminated by an integration issue and a human QA sign-off issue. Use when the user wants to convert a plan/PRD into implementation issues or break work into slices.
allowed-tools: Read, Write, Edit, Bash
---

# To Issues (Linear)

Break a PRD into vertical slices and publish them as Linear issues sized for one
coding-agent session each. This is an operator-side conception skill: run by a
human in conversation, before any implementation session starts.

> OWN override of the vendored mattpocock-skills `to-issues` (GitHub-flavored).
> Decomposition rules come from pstack (2026-09-09): **one issue is one predicate
> and one `autonomous-run` session.**
>
> **One issue is NOT one PR.** `f34d3c7` (2026-09-09) swapped the branch model to
> branch-per-slice as collateral in a larger refactor; `to-issues` said so for
> eight days and it cost a real project (O10C-343/344 built as an unpushed stack,
> neither slice landing). Restored 2026-09-17: **one Linear Project = one branch =
> one PR**, terminated by an integration issue and a human QA issue. The Symphony
> dispatch machinery (WORKFLOWS file, `ready-for-agent` label) stays gone —
> `orchestrate` dispatches now.

## Dependencies

- **`linear-cli` skill** for every Linear read and write. Prefer
  `--description-file` for bodies. Key commands: `linear project list|create`,
  `linear document create`, `linear issue create`, `linear issue relation add
  <id> blocked-by <id>`.
- **`scripts/check-issue.sh`** in this skill dir lints an issue body before
  publish. Publishing a body it rejects is a bug.
- Inputs from the PRD (`/to-prd`): Definition of Done, Data Shape, Verification
  Harness, Throughput Checkpoint, and the one-way-door marks.

## The model

A PRD = a Linear **Project** carrying the PRD as a **Project Document** (never an
issue). **The Project owns one long-lived branch, and that branch produces exactly
one PR.** Each **slice** is a child Issue whose session lands its work on that same
branch — it does not cut its own branch and does not open a PR. A terminal
**integration issue** (agent-runnable), `blockedBy` every slice, syncs `base_ref`
into the branch, runs full-feature validation, and opens the single
**branch → `target_ref`** PR. A terminal **QA issue** (human-only), `blockedBy` the
integration issue, is the true end of the DAG: it carries a human-runnable QA
script and gates the merge.

Why one PR: a slice is a tracer bullet, not a shippable increment. Slices share
schema, fixtures and seams, so reviewing them separately reviews half-built states,
and a stalled slice strands every slice stacked behind it. The review unit is the
feature; the session unit is the slice.

Each slice session commits its decision trail at `.audit/<issue-id>.tsv` on the
Project branch.

### Refs — confirm all three at the start

| Param | Meaning | Default |
|---|---|---|
| `base_ref` | what the branch is cut from, and the ref it syncs against | `main` |
| `target_ref` | what the integration issue's PR targets | `= base_ref` |
| `branch` | the Project's branch | derived `feat/<slug>`; an override names an **existing** branch (checked out, never created) |

`base_ref` is re-read from the Project for every slice. A session never inherits it
from whatever branch happens to be checked out — that is how a Project ends up
based on `staging` when it meant `main`.

Linear placement: team `<team>`. Initiative inferred from the target repo; confirm
if ambiguous.

## Process

### 1. Gather context

Work from the PRD in conversation context. If passed a Project or issue
reference, fetch it via `linear-cli` and read it fully. Establish the target
repo, Initiative, feature name, and the three refs (`base_ref`, `target_ref`,
`branch`).

### 2. Explore the codebase

Use the repo's `CONTEXT.md` glossary and respect ADRs in the area touched.
Issue titles and bodies use project vocabulary.

### 3. Bootstrap the Project and its branch (if missing)

`linear project list --team <team>`. If absent, propose:
`linear project create -n "<name>" -t <team> --initiative "<initiative>" --json`,
then attach the PRD:
`linear document create -t "<name> — PRD" --content-file <prd.md> --project <slug>`.

Then settle `branch`. Derived (`feat/<slug>`) means the first slice's session cuts
it from `base_ref`; an override means the branch already exists and is used as-is.
Record `branch`, `base_ref` and `target_ref` in the PRD document's header so every
later session reads them from one place instead of inferring them from a checkout.

### 4. Draft slices

Each slice is a **tracer bullet**: a thin but complete path through every layer
it touches, verifiable on its own. Prefer many thin slices over few thick ones.

**Sizing rule.** One slice has exactly one runnable predicate. Split when the
predicate needs more than one, or when ANY smart-zone trigger trips:

1. Estimated agent execution > ~1 hour (migrations, multi-module refactors, new
   cross-cutting abstractions count double).
2. More than ~5 acceptance criteria.
3. Touches more than ~3–4 distinct files.
4. Bundles an architectural pivot with feature work. Split the pivot out.
5. There is an earlier point where the suite passes and the system does
   something useful. Cut there.

**Ordering rule.**

- Riskiest unknown first. An unproven integration or an unmeasured cost is
  slice 1, not slice 5.
- Scaffold and the verification harness (from the PRD) land before features.
  The harness slice's predicate is "baseline captured".
- Within a slice, the failing test precedes the fix. Say so in the body when
  the order matters.
- Read the PRD's Throughput Checkpoint: blocking-first steps become the first
  slices; independent workstreams get no blockedBy edge between them; shared
  mutable state is split into separate slices rather than serialized.

**Review gate.** A slice that implements a one-way-door decision from the PRD,
or that changes a user-facing interaction, gets `Review gate: interaction`: its
session stops and shows the operator screenshots before moving on. Every other
slice is `Review gate: none` and runs fully autonomously. The gate pauses the
*slice*, not a PR — there is no PR until the integration issue.

**Named review seats.** Every slice ends with a `/review` checkpoint: the seats
whose triggers fire on the diff (`review: auto`) plus the two contract seats.
Name a seat (`review: auto + <seat>, <seat>`) only when you know a hazard the
diff cannot show: a cross-PR contract this slice sets up for a later slice, a
write path that already has another caller, a migration a later slice depends
on. Seat names come from the target repo's `.claude/review.md` `## Seats`
table; without a profile, only `auto` is valid. Do not name seats by reflex;
a checkpoint that runs the whole catalogue is a full committee by another name.

**Prototype evidence.** A decision settled by a prototype carries its branch or
SHA in the body. The implementing session starts from that, not from prose.

**Language — English prose, domain terms untranslated.** Issue titles and bodies
are written in **English**, whatever language the codebase, the PRD conversation
or the surrounding artefacts are in. The one exception is the **ubiquitous
language**: a domain term keeps the exact form the project uses, and that form is
authoritative — the project's `CONTEXT.md` glossary, the resource and action
names, the status atoms, the Gettext msgids, the UI labels an operator reads on
screen. Translating one of those invents a second name for a thing that already
has one, and the issue stops matching the code a session will grep.

So: *"the reprise flip refuses while an unresolved attempt exists"*, not *"the
takeover flip"*. Quote a UI label verbatim and in quotes — « Déjà facturée », not
"already billed". Same for a status (`:no_mandate`), an operator's own words, and
any string the implementation must match character for character.

If a term is genuinely ambiguous in the source language, name it once in the
project's form and gloss it in English in parentheses — do not replace it.

### 5. Operator review of the slice list

Present a numbered list. For each slice: **Title**, **Predicate** (one line),
**Review gate**, **Blocked by**, **Stories covered**. Then ask, in prose:

- Granularity right?
- Order right (riskiest first, harness before features)?
- Dependency edges correct or over-specified?
- Review gates right?
- Named seats justified by a hazard the diff cannot show?

Iterate until approved. This is the one human checkpoint a long run earns.
Publishing is a shared-state act: show the exact commands, get an explicit go.

### 6. Lint, then publish in dependency order

For every slice body: `bash <skill-dir>/scripts/check-issue.sh <body.md>`. Fix
every line it prints. Then, blockers first:

```
linear issue create \
  --team <team> --project "<project-slug>" \
  --title "<slice title>" \
  --description-file <slice-body.md> \
  --state Todo
```

Wire only the edges the operator kept (Linear inverse semantics: `blocked-by` on
the dependent):

```
linear issue relation add <slice-id> blocked-by <blocker-id>
```

Then **always append the integration issue**, `blockedBy` **every** slice:

```
linear issue create --team <team> --project "<project-slug>" \
  --title "Intégrer & promouvoir <feature>" \
  --description-file <integration-body.md> --state Todo
# then, for every slice:
linear issue relation add <integration-id> blocked-by <slice-id>
```

Its body spells out its duties: sync `base_ref` into `branch`, run full-feature
validation on the merged head, flip or verify any feature flag, run the `/review`
full committee, open the single **`branch` → `target_ref`** PR, and move the
Project to Human Review. Its predicate is the PRD's Definition of Done.

Then **always append the QA issue**, `blockedBy` the integration issue, as the true
end of the DAG. It is human-only — never dispatched, never given to an agent:

```
linear issue create --team <team> --project "<project-slug>" \
  --title "QA & validation <feature>" \
  --description-file <qa-body.md> --state Todo
linear issue relation add <qa-id> blocked-by <integration-id>
```

The QA issue is the merge gate: the operator runs its script against the open PR
and, on pass, merges and moves the Project to `Done`; on fail, files a rework issue
blocking it.

Do not modify the PRD document. Issues go to `Todo`.

### 7. Hand off

Reply with the Project link, the `branch` / `base_ref` / `target_ref` triple, and
the issue ids in order. Each slice issue is picked up in its own session with
`autonomous-run <issue-id>`, which reads the Predicate as its exit condition, runs
`/implement` for the unit, ends with a `/review` checkpoint (named + diff-fired +
contract seats), and commits `.audit/<issue-id>.tsv`. **Every slice works on the
Project's branch and none of them pushes a PR.** The integration issue is the only
one that opens a PR, and the QA issue is the only one a human runs.

## Slice issue body template

```
## What to build

End-to-end behavior of this slice, not layer-by-layer. No file paths or code
snippets that go stale. Exception: a prototype snippet that encodes a decision
(state machine, schema, type shape), trimmed, with its branch or SHA.

## Predicate

One runnable check that proves this slice is done: a test command, a curl and
its expected field, a pixel-diff, a measurement with a threshold. It must be
something the session can execute without asking.

## You see

One observable result on the real surface once the predicate passes: the log
line, the screen state, the API response.

## Verify

- unit: <test file and the case it gains, and the command>
- live: <how to drive the real surface, and the pass condition>
- perf: <metric, probe, trunk baseline, failing number> or "n/a: no hot path"
- review: auto | auto + <seat>, <seat>   (seat names from the target repo's `.claude/review.md` `## Seats` table)

## Review gate

none | interaction (screenshots to the operator before merge)

## Depends on

<issue id(s)>, or "None — can start immediately"

## Prototype

<branch or SHA>, or "none"
```
