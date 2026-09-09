---
name: to-issues
description: Break a PRD or plan into Linear issues where each issue is one runnable predicate, one PR, and one autonomous-run session. Vertical slices as child issues of a feature Project, ordered riskiest-unknown-first, optionally wired with blockedBy. Use when the user wants to convert a plan/PRD into implementation issues or break work into slices.
allowed-tools: Read, Write, Edit, Bash
---

# To Issues (Linear)

Break a PRD into vertical slices and publish them as Linear issues sized for one
coding-agent session each. This is an operator-side conception skill: run by a
human in conversation, before any implementation session starts.

> OWN override of the vendored mattpocock-skills `to-issues` (GitHub-flavored).
> Rewritten 2026-09-09 around pstack's decomposition rules: **one issue is one
> predicate, one PR, one `autonomous-run`.** The earlier Symphony-dispatch
> variant (WORKFLOWS file, integration issue, QA issue, dispatch label) is gone.

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
issue). Each **slice** is a child Issue. Each slice is worked in its own branch
off `base_ref`, opens its own PR, and its session commits a decision trail at
`.audit/<issue-id>.tsv` on that branch. There is no integration issue; the last
slice's predicate is the PRD's Definition of Done.

Linear placement: team `<team>`. Initiative inferred from the target repo; confirm
if ambiguous. Confirm `base_ref` (default `main`) at the start.

## Process

### 1. Gather context

Work from the PRD in conversation context. If passed a Project or issue
reference, fetch it via `linear-cli` and read it fully. Establish the target
repo, Initiative, feature name, and `base_ref`.

### 2. Explore the codebase

Use the repo's `CONTEXT.md` glossary and respect ADRs in the area touched.
Issue titles and bodies use project vocabulary.

### 3. Bootstrap the Project (if missing)

`linear project list --team <team>`. If absent, propose:
`linear project create -n "<name>" -t <team> --initiative "<initiative>" --json`,
then attach the PRD:
`linear document create -t "<name> — PRD" --content-file <prd.md> --project <slug>`.

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
or that changes a user-facing interaction, gets `Review gate: interaction`. Its
PR waits for the operator to review screenshots before merge. Every other slice
is `Review gate: none` and runs fully autonomously.

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

Do not modify the PRD document. Issues go to `Todo`.

### 7. Hand off

Reply with the Project link and the issue ids in order. Each issue is picked up
in its own session with `autonomous-run <issue-id>`, which reads the Predicate as
its exit condition, runs `/implement` for the unit, ends the issue with a
`/review` checkpoint (named + diff-fired + contract seats), and commits
`.audit/<issue-id>.tsv` on the slice branch. Issues marked `Review gate:
interaction` and the last slice of the Project get the full committee on the
merge-ready head instead of a checkpoint.

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
