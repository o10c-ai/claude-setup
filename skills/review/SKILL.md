---
name: review
description: Post-implementation review run as a committee of independently adjudicated seats, driven by the project's `.claude/review.md` profile. Run it proactively at the end of every issue and before any commit that touches more than one layer — do not wait to be asked. Deterministic concerns are delegated to the profile's guards; the committee judges only what no guard can see. Works without a profile (two contract seats plus a generic quality pass) and says which example profile to copy.
---

# Review

Contract skill. The phases, invariants, and output shape below are fixed. Everything
stack-specific (guards, seat catalogue, evidence commands, isolation, report path) comes
from the project profile at `.claude/review.md`. Read that file first; it may begin with
`delegate: <skill>` (invoke that project skill and stop) or `status: not applicable`.

## Why this shape

A self-graded checklist lets the author close its own finding as "unreachable by
construction". That is how a cross-PR contract break reached production in the project
this contract was lifted from. Three structural fixes, not wording:

1. **Independent adjudication.** A seat's verdict is rendered by a reviewer that is not
   the implementing session. A `❌` cannot be closed by the author with "won't happen".
2. **Guard delegation.** Every concern a deterministic guard enforces is delegated to it.
   The green guard run *is* the evidence line; the committee never re-reviews it.
3. **Composable seats.** Each seat is one orthogonal concern with its own trigger, rubric,
   adjudication rule, and evidence line, independently invocable.

## Which seats run (the checkpoint rule)

Run set = seats named on the issue's `review:` line (in `## Verify`, written by
`/to-issues`) ∪ seats whose trigger fires on the diff ∪ the two **contract seats**
below. That is a *checkpoint*, the default at the end of every issue.

The **full committee** (every profile seat plus the contract seats, one head SHA) runs
only when: the issue says `Review gate: interaction`; the issue is the last slice (its
predicate is the PRD's Definition of Done); a profile `## Full committee triggers` rule
fires; or the operator asks. In every case the verdict binds to the merge-ready head SHA
before merge. A new head gets a fresh verdict.

Contract seats, present in every project, defined in this skill dir:

- [`seats/audit.md`](seats/audit.md) — reads the diff and the evidence pack and distrusts
  the PR body.
- [`seats/regression.md`](seats/regression.md) — runs the issue's `live:` line at
  `base_ref` and at head.

## Profile slots

| Slot | What the profile supplies |
|---|---|
| `## Guards` | table: concern → guard command. Green = evidence line, never re-reviewed. |
| `## Seats` | table: ★ \| seat \| fires when the diff… \| rubric path. One file per seat. |
| `## Evidence pack` | the exact commands whose raw output forms the pack. |
| `## Isolation` | how a seat that mutates shared state (DB, caches) isolates, and what not to use. |
| `## Full committee triggers` | project-level conditions that escalate a checkpoint to the full committee. |
| `## Report` | where the workpad and the evidence pack land. |

**No profile:** run the two contract seats plus one generic diff-scoped quality seat:
file pushed from under to over ~1k lines without a stated reason; new ad-hoc conditionals
bolted into unrelated flows; thin wrappers, casts, or optionality added to silence a type;
incidental complexity kept when a plausible simplification would delete it. Then say:
"No `.claude/review.md`; copy `examples/phoenix/.claude/review.md` from claude-setup to
onboard this project."

## Dispatch protocol

1. **Write the evidence pack before spawning.** Raw command output only, never
   conclusions: `git diff --stat` plus the changed-file list (including untracked), every
   guard from `## Guards` with its exact invocation, raw output, and exit code, the suite
   result, and whatever `## Evidence pack` adds. Every brief carries: *"The evidence pack
   at `<path>` records commands already run, with their raw output. Do not re-run them. If
   you believe one is insufficient, say so and why — do not silently repeat it."* Output
   is handed over, not verdicts; an author cannot fake an exit code.
2. **Isolate mutating seats at the right layer.** Follow `## Isolation`. Read-only seats
   parallelize freely and should.
3. **Two waves.** Wave 1 = ★ seats plus whichever seat the diff's specific hazard makes
   high-risk, plus the contract seats. Wave 2 = the rest, spawned while wave-1 findings
   are being fixed. Never sit blocked on the full set.
4. **Name the hazard; budget everything else.** The implementing session knows the
   change's specific risk shape; state it in the brief and spend exhaustiveness there
   only. Elsewhere give a tool-call budget (★ ≈ 40 calls, others ≈ 20) and an explicit
   "stop and report what you have".
5. **Assign ownership.** Each brief names what is *not* its concern (stale docs →
   documentation seat; missing tests → test-surface seat; caller contracts → contract
   seat). Duplicates are folded by the running session, not re-adjudicated.
6. **Tool discipline, in every brief and in the running session.** *Read your seat's
   rubric with the Read tool — it is one small self-contained file; do not `sed`/`awk` a
   range out of it.* *Run one command per Bash call; no `( … )`/`{ … }` groups or
   multi-line loops to label output.* Capture guard output by redirecting to a file, then
   `echo "exit: $?"`; `tail` the file in a second call.

Spawn seats with the Agent tool, `subagent_type: general-purpose`, all of a wave in one
message. A seat brief stands alone: the concern, the rubric path, the diff scope, the
evidence-pack path, the hazard, the budget, what is not its concern, and the evidence-line
template it must return.

## Output

Only seats that fired appear. Each seat's verdict is rendered by the adjudicator and
**must carry an evidence line**: the exact guard/grep/command/file invocation and its
result. A bare `✅ PASS` with no evidence is performative and fails the gate; the workpad
is rejected as incomplete.

```
## Review  (adjudicator: <fresh reviewer id> — NOT the implementing session)
### Head: <sha> · mode: checkpoint | full committee · issue: <id or none>

### Delegated guards
- `<guard invocation>` → <raw result / exit code>
- …

### Seat — audit: ✅ / ❌  · evidence: …
### Seat — regression: ✅ / ❌ / N/A  · evidence: …
### Seat — <profile seat>: ✅ / ❌ / N/A  · evidence: <per that seat file's "Evidence line">
### …
```

Fix `❌` items immediately — do not ask, fix and report. A `❌` turned `✅` must show the
*independent* re-adjudication (a fresh seat run on the new head), never an author
"unreachable by construction". Findings from a gate run go back to the owner; a new head
gets a fresh verdict.

## Relationship to the pipeline

`/to-issues` writes the `review:` line and the `Review gate`. `autonomous-run` calls
`/implement` for the work and this skill at the end of the issue. `/implement` also calls
this skill before its commit when the project profile says so.
