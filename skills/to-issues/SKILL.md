---
name: to-issues
description: Break a plan, spec, or PRD into Symphony-dispatchable Linear issues — vertical tracer-bullet slices as child issues of a feature Project, wired into a blockedBy DAG, plus a mandatory terminal integration issue. Tailored for the Symphony feature-branch workflow (Linear, not GitHub). Use when the user wants to convert a plan/PRD into implementation issues, break work into slices, or set up a feature for Symphony to run.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# To Issues (Symphony / Linear)

Break a plan into independently-grabbable **vertical slices** and publish them as
**Linear** issues that the Symphony orchestrator can dispatch. This is an
**operator-side conception skill** — run by a human before dispatch, never inside
the agent container.

> This replaces the stock (GitHub-flavored) `to-issues`. It encodes the
> feature-branch model adopted 2026-06-10 (see
> `~/.config/nix/services/symphony-claude/.claude/skills/symphony-ops/references/decisions.md`
> → "Feature-branch model" + "Conception pipeline"). Defer to that for the *why*.

## Dependencies — reuse, don't reinvent

- **`linear-cli` skill** — all Linear reads/writes go through the `linear` CLI.
  Prefer `--description-file` / `--content-file` for markdown bodies (avoids shell
  escaping). Key commands: `linear project list|create`, `linear document create`,
  `linear issue create`, `linear issue relation add <id> blocked-by <id>`. Fall
  back to `linear api` only for what the CLI can't express.
- **Slice sizing heuristics** — adapted below from the retired `sym-ticket-split`.

## The model (what the issues must look like)

A PRD = a Linear **Project** (the feature container) carrying the PRD as a
**Project Document** (never an Issue — it must not be dispatchable). The Project
owns one long-lived **feature branch**. Each **slice** is a child Issue that lands
work on that branch. A single **terminal integration issue**, `blockedBy` every
slice, owns the merge to the target ref. Because Symphony only dispatches unblocked
issues, the integration issue becomes dispatchable exactly when all slices are done
— no completion-detection logic anywhere.

### Linear placement

- **Team**: `<team>`.
- **Initiative**: inferred from the target repo — `saasp_aas` → `saasp_aas`;
  `symphony-claude` → `Infinite Loop`. Confirm with the operator if ambiguous.
- **Project** = the feature. **Project Document** = the PRD.

### Ref parameterization

Three per-feature params, defaults reproduce today's behavior:

| Param | Meaning | Default |
|---|---|---|
| `base_ref` | branch cut-from + the ref the feature syncs against | `main` |
| `target_ref` | the integration issue's PR target | `= base_ref` |
| `branch` | the feature branch | derived `feat/<slug>`; override → an existing branch (checked out, never created) |

Confirm these with the operator at the start. (This first feature: corrections on
`feature/plv-subscription` off `staging` → `base_ref = target_ref = staging`,
`branch = feature/plv-subscription`.)

## Process

### 1. Gather context

Work from the plan/PRD in conversation context. If passed an issue/Project
reference, fetch it via `linear-cli` and read it fully. Establish the target repo,
the inferred Initiative, the feature name (bounded shipping arc, e.g.
`PLV subscription corrections`), and the three refs.

### 2. Explore the codebase (recommended)

Use the target repo's domain glossary (`CONTEXT.md`) and respect ADRs in the area
touched. Issue titles/descriptions should use project vocabulary.

### 3. Bootstrap the Project + WORKFLOWS file (if missing)

Symphony watches a Project only once a `WORKFLOWS/<slug>.md` exists for it.

a. **Linear Project** — `linear project list --team <team>` (or `--all-teams`). If the
   feature Project doesn't exist, **propose** creating it:
   `linear project create -n "<name>" -t <team> --initiative "<initiative>" --json`
   (capture the returned slug id). Attach the PRD as a Project Document:
   `linear document create -t "<name> — PRD" --content-file <prd.md> --project <slug>`.
   **No dispatch label on the PRD or Project — the PRD is a backdrop, never work.**

b. **`WORKFLOWS/<slug>.md`** in `~/.config/nix/services/symphony-claude/elixir/WORKFLOWS/`.
   If absent, template-generate it by **cloning the structure of an existing file**
   (`dpi-workspace-poc.md` is the reference — copy its `tracker` /
   `active_states` (incl. Merging, Rework) / `terminal_states` / `polling` /
   `hooks.timeout_ms` / `agent` / `claude.command` / `model` / gates verbatim),
   then change:
   - `tracker.project_slug` → the new Project's slug id.
   - add `tracker.required_labels: [ready-for-agent]` (the dispatch gate).
   - **`hooks.after_create`** — for **non-default refs**, replace the template's
     `git clone --depth 1 <repo> .` with a checkout of `branch` + a fetch of
     `base_ref`, e.g.:
     ```
     git clone --branch feature/plv-subscription https://github.com/<org>/<repo>.git .
     git fetch origin staging:staging
     ```
     (default `base_ref=main`, derived `branch` → keep the template's clone line.)

   This file is **committed + pushed to the symphony-claude submodule by the
   operator as a separate explicit act** (commit ≠ push). Symphony hot-reloads on
   the new file. Do not commit/push it yourself without an explicit go.

### 4. Draft vertical slices

Break the plan into **tracer-bullet** slices — each a thin but COMPLETE path
through every layer (schema → API → UI → tests), demoable/verifiable on its own.
Prefer many thin slices over few thick ones. Mark each **AFK** (agent can finish
unattended) or **HITL** (needs a human decision/review); prefer AFK.

**Sizing — split a slice if ANY of these trip** (the stop rule for "fits one
context window at comfortably-low utilization"):

1. Estimated agent execution > ~1 hour of work (migrations / multi-module refactors
   / new cross-cutting abstractions count double).
2. More than ~5 acceptance criteria.
3. Touches more than ~3–4 distinct files.
4. Bundles an architectural pivot ("introduce a new <abstraction>") with feature
   work — split the pivot out.
5. There's an earlier point where `mix test` would pass and the system does
   something useful — that's a slice boundary; cut there.

### 5. Quiz the operator

Present the breakdown as a numbered list. For each slice: **Title**, **Type**
(AFK/HITL), **Blocked by** (which slices), **Stories covered**. Then ask:

- Granularity right? (too coarse / too fine)
- Dependency edges correct?
- Merge/split any?
- AFK/HITL marks right?

Also surface the bootstrap plan from step 3 (Project create? WORKFLOWS file
diff?). Iterate until the operator approves. **Approval is the launch gate** —
slices go live in `Todo` and Symphony begins dispatching in `blockedBy` order.

> Publishing to Linear and committing the WORKFLOWS file are **shared-state
> acts** — get explicit operator approval before any `linear … create` or git
> commit/push. Show the exact commands first.

### 6. Publish (after approval), in dependency order

For each approved slice, blockers first so you can reference real IDs:

```
linear issue create \
  --team <team> --project "<project-slug>" \
  --title "<slice title>" \
  --description-file <slice-body.md> \
  --state Todo \
  --label ready-for-agent
```

Then wire dependencies (Linear inverse semantics — `blocked-by` on the dependent):

```
linear issue relation add <slice-id> blocked-by <blocker-id>
```

Finally, **always append the terminal integration issue** (AFK), `blockedBy`
**every** slice:

```
linear issue create --team <team> --project "<project-slug>" \
  --title "Integrate & promote <feature>" \
  --description-file <integration-body.md> \
  --state Todo --label ready-for-agent
# then, for every slice:
linear issue relation add <integration-id> blocked-by <slice-id>
```

The integration issue body must spell out its duties: sync `base_ref` →
feature branch, run full-feature validation, flip/verify the feature flag, open
the **feature → `target_ref`** PR, and move the **Project** to Human Review.

Do NOT close or modify the PRD/Project document. Issues are created live in
`Todo` (not `Backlog`) — the orchestrator's blocker gate only applies to `todo`
state, and slice "done" must land in a `terminal_states` value (`Done`) for
blockers to clear.

## Slice issue body template

```
## What to build

End-to-end behavior of this vertical slice (not layer-by-layer). Avoid file
paths/snippets that go stale — exception: a decision-encoding snippet from a
prototype (state machine, schema, type shape), trimmed to the decision-rich part.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- <issue identifier(s)>, or "None — can start immediately"
```

## Out of scope (flag, don't silently assume)

The current `WORKFLOW.md` / Elixir orchestrator do **not** yet implement the
feature-branch ensure-step, `base_ref`/`target_ref`, or the integration-issue
handling — for non-default refs the branch/ref handling rides on the hand-tuned
`after_create` (step 3b) plus explicit instructions in the issue bodies. If a run
must commit on an existing branch and PR to a non-`main` ref, confirm the
execution-side wiring with the operator before dispatch (a `WORKFLOW.md` change is
stop-Symphony → edit → commit → bump pin → restart).
