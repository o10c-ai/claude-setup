---
name: autonomous-run
description: "Drive a long task to a checkable exit predicate without stopping, pause it cleanly, or resume a prior agent's run. Use for 'run until done', 'going to bed', 'keep going', 'be fully autonomous', 'pause here', or picking up in-flight work from a transcript or pushed branch."
---

# Autonomous run

Distilled from pstack's `autonomous-run`, `pause-safely`, and `session-pickup`
playbooks (`vendor/pstack-claude/plugins/pstack/skills/poteto-mode/playbooks/` in the claude-setup checkout),
adapted to this setup: no `/loop`, no `AskUserQuestion`, decision trail committed.

Three modes. Pick the one the request names.

## Run

**You own the exit condition. Define done, then drive to it without stopping.**

1. State the exit condition as a checkable predicate before the first iteration
   (tests green, repro fixed, all N PRs merged, pixel-diff zero). Write it as the
   first row of the decision trail. **Given a Linear issue id** (from
   `/to-issues`): fetch it via `linear-cli`, take its `## Predicate` section
   verbatim as the exit condition, its `## Verify` lines as the per-iteration
   checks, its `## Prototype` SHA as the starting point, and its `## Review
   gate` as the only allowed pause (screenshots to the operator before merge).
   Branch off the issue's `base_ref`, one PR per issue, trail at
   `.audit/<issue-id>.tsv`.
   **Opening phase, every time** (first run or a restart after preemption by
   `orchestrate`): `git status` and `git log/diff base_ref..HEAD`. Judge what is
   already there against the predicate. Keep what serves it; revert by commit
   what does not, one trail row per revert with the SHA. Nothing is discarded by
   default and nothing is kept on faith. Do not read a predecessor's notes; you
   have none, by design.
2. Pick the wake mechanism. An event to watch (CI, a merge, a ref advancing, a
   log line) gets a `Monitor` whose filter covers every terminal state, success
   and failure. A single condition gets `Bash` with `run_in_background` and an
   `until` loop. No event gets a fixed-interval poll sized to when the result is
   worth re-checking. `/loop` is disabled by `disableBundledSkills`; if it is
   ever re-enabled it replaces the poll case only.
3. Run `/implement` for the unit. Each iteration makes the smallest change the
   evidence justifies, verifies it against the predicate on the real artifact,
   commits if it advanced, reverts what did not help. Belt-and-suspenders that
   "might help" gets reverted, not left to ride. Verify each unit before
   starting the next.
4. Mid-run discoveries are yours. Fix broken tooling, related bugs, flaky
   verifiers, and drift yourself. Out-of-band fixes go in their own commit or
   PR. Do not park reversible work for the human. Surface only irreversible
   actions, product or preference calls no experiment can settle, or a real
   dead end. If a fork can be answered by running something, run it. Return to
   the predicate after each side fix.
5. Checkpoint every iteration via the **show-me-your-work** skill, one row for
   what changed and whether the predicate moved. Milestones also go to
   `cmux set-progress <0-1> --label "…"`.
6. When the predicate is met, run `/review` on the head before opening the PR.
   A checkpoint by default: the issue's named seats, the seats whose triggers
   fire on the diff, and the two contract seats. The full committee when the
   issue's Review gate is `interaction` or the issue is the last slice of its
   Project. The verdict and the head SHA go in the trail. A ❌ is fixed and
   re-adjudicated by a fresh reviewer, never closed by the author; a new head
   gets a new verdict.
7. Stop when the predicate is met and the review verdict is clean. A plateau
   is not a stop; pivot the approach. Surface a genuine dead end rather than
   spinning. Never relax the predicate to declare victory. On completion
   `cmux clear-progress` and `cmux notify`.

**Reply:** the exit condition, iterations run, what landed, what was discarded,
final predicate state, trail path, and the Attention section from the trail
review. **When spawned by `orchestrate`**, reply with the fragment shape from
that skill instead, and nothing else. You cannot ask mid-flight: a question
that needs a product call ends the run with `predicate: blocked` and the
question under `open:`.

**Turn budget.** When the brief names one, respect it: commit wip at every green
cycle so a hard stop loses at most one cycle, and write a trail row at least
every few tool calls so the orchestrator can see you are alive.

## Pause

**You own a clean stop. Leave a checkpoint a cold-start agent can resume from.**
Explicit only. On "keep going", "going to bed", or "don't stop", do not pause.

1. Stop at a safe boundary. Finish the current atomic step or back it out.
   Never stop mid-edit in a known-broken state. Start nothing new. Stop any
   background subagents and monitors and confirm they stopped.
2. Take no irreversible action to pause. No PR and no push unless one was
   already out.
3. Make the work durable. Commit uncommitted edits as one `wip:` commit on the
   current branch. If the tree is broken, say so in the commit body in one line.
4. Write the resume note off-context to `/tmp/<slug>-resume.md`: intent, what
   you were doing, what is verified, current state, next steps, key files,
   gotchas. If a decision trail exists, point at it instead of duplicating it.

**Reply:** where you are in the loop, what is on disk versus still in your
head (paths, no diff dumps), the commits made and whether the tree is clean,
and the first action on resume. This is a pause, not a final report.

## Pickup

**You own the resume point. Read the prior trail, don't redo it.**

1. Locate the prior trail: the committed `decisions.tsv`, a `/tmp/<slug>-resume.md`,
   a pushed branch, or the transcript under
   `~/.claude/projects/<encoded-cwd>/*.jsonl` (cwd with `/` → `-`; never glob
   across other projects). Read the last messages first, then scan back for
   decision points. Parse a long transcript in a subagent and keep the reduced
   timeline in the main thread.
2. Reconstruct operational state: branch and worktree, what landed (`git log`,
   `git diff` against base), open todos, decisions made. The prior trail is
   authoritative input. Resist re-deriving it.
3. Diff done vs pending. Name the resume point. Do not re-run the prior repro
   or redo completed work.
4. Route the remaining work: continue the run, ship a finished recommendation,
   ratify or override a prior conclusion, or postmortem a failed run.
5. Verify the inherited claims against the original goal on the real artifact.
   A passing prior self-report is not the proof.

**Reply:** where the prior agent stopped, what you inherited vs redid (ideally
nothing redone), the resume point, and the outcome.

## Decision trail policy (this setup)

The trail is **committed by default**, at `.audit/<task-slug>.tsv` in the repo
(`<issue-id>` when the run came from a Linear issue),
so later debugging can replay the run. Append rows with
`~/.claude/skills/show-me-your-work/scripts/log.sh`. Keep it local only when
the repo is not yours to commit to.

## For very large or shapeless work

When the run is a large migration or a multi-part change with no obvious
sequence, design the playbook first via the **figure-it-out** skill, then run
it under the Run mode above. figure-it-out references pstack skills that are
not installed here. Map them: `architect` → `grill-with-docs` (design it twice on
one-way doors), `arena` → `prototype` (race the candidates, keep the SHA),
`poteto-mode` principles → the Autonomy section of CLAUDE.md. Multi-issue work
goes to `orchestrate`, not to a single run.
