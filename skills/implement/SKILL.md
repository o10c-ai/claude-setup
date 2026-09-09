---
name: implement
description: Carry one unit of work from intent to a committed, gate-passing change — understand, tracer bullet, red-green-refactor slices, the project's feedback loops, a /review checkpoint, commit. Reads the project profile at .claude/implement.md for stack commands. Use when handed a discrete task ("do X", "implement Y", "fix Z") or as the inner loop of autonomous-run; skip for questions or exploration.
---

# Implement

A **contract skill**: the phases below are fixed; the stack-specific parts come
from the **project profile** at `.claude/implement.md` (format: `docs/profiles.md`
in the claude-setup repo). Read the profile first. If its first line is
`delegate: <skill>`, invoke that project skill and stop. If it is
`status: not applicable` or the file is missing, use the fallback at the end.

## 1. Understand

Read the plan, PRD, or issue you were pointed at. Consult the profile's
`## Read first` rows for the area you touch, **narrowly**: a document over a
few hundred lines goes to an `Explore` subagent that returns the rules that
apply, and you keep the rules, not the file. Read the code you are about to
change, not the module around it. Your context is the budget for the whole
unit; spend it on the tracer bullet and the red-green cycles.
Restate the unit of work in one sentence: what changes, and the check that
proves it. If the work came from `/to-issues`, that check is the issue's
`## Predicate`.

## 2. Plan only if unplanned

An issue, PRD, or approved multi-phase plan is already a plan; go to step 3.
Otherwise write the plan in prose, three to eight lines: layers touched, seams
tested, order of slices. Plan mode is denied in the lean preset, so there is no
`EnterPlanMode`; state the plan and proceed.

## 3. Implement

Work on a branch per the profile's `## Branch rules`; never on the trunk.

**Tracer bullet first.** Name the layers the unit touches. Write one failing
test that drives the thinnest complete slice through all of them, and make it
green with skeletal wiring. If it will not go green, the design is wrong: stop
and rethink before adding behaviour.

**Then widen, one behaviour at a time**, in red-green-refactor slices per the
`tdd` skill: one failing test against the public interface, the minimal code
to pass it, refactor only while green. Never write all tests then all code.

Doc updates that the change makes necessary ship in the same change.

## 4. Validate

Run the profile's `## Feedback loops` in the order listed, fixing until each
is green. Never weaken a gate to make it pass: no skipped test, no disabled
lint rule, no lowered threshold. If a gate is wrong, say so and fix the cause.

## 5. Review

Run `/review`. A **checkpoint** by default: the seats the issue names in its
`review:` line, plus the seats whose triggers fire on the diff, plus the two
contract seats. Run the **full committee** when the issue says
`Review gate: interaction`, when it is the last slice of its Project, or when
a trigger in the profile's `## Review` section fires. Fix every ❌ and have it
re-adjudicated before committing.

Under `autonomous-run`, the issue-end checkpoint (its step 6) **is** this
review; do not run a second one per commit unless a profile `## Review`
trigger fires on the unit itself. Standalone `/implement` (no issue) runs the
checkpoint here, before its commit.

## 6. Commit

Commit with the command in the profile's `## Commit` section so hooks fire.
Do not push or open a PR unless asked.

**Reply:** the unit in one sentence, the branch, the tests added, the feedback
loop results, the `/review` verdict, and the commit hash.

## Profile slots

| Slot | Contents |
|---|---|
| `## Read first` | Documents to read before touching the area |
| `## Branch rules` | Branch naming, protected branches, base ref |
| `## Feedback loops` | Ordered commands (lint, test, typecheck), with their wrappers |
| `## Commit` | The commit command and why (hooks, wrappers) |
| `## Review` | Project triggers that upgrade a checkpoint to the full committee |

## Fallback (no profile)

Detect the stack from the repo root and use its obvious loops: `mix format
--check-formatted && mix test` (Elixir), `npm test` or `pnpm test` (Node),
`cargo test` (Rust), `pytest` (Python), `go test ./...` (Go). Branch off
`main`, commit with plain `git commit`. Say in the reply that no profile was
found and name the example to copy: `examples/<stack>/.claude/implement.md`
in the claude-setup repo.
