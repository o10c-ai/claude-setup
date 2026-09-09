# Seat — Regression (contract seat)

> One seat per file: read **only this file** when adjudicating this seat.
> Contract: [`../SKILL.md`](../SKILL.md). Present in every project, profile or not.
> Adjudication is always *independent of the author*; `❌`/findings are not self-dismissible.

- **Trigger:** always when the issue (or the PR) carries a `live:` line in `## Verify`;
  `N/A` with the reason when there is no live surface to drive.
- **Concern:** tests alone are not sufficient verification. The load-bearing scenario is
  driven on the real surface twice — at `base_ref` (trunk) and at head — and the two
  results are compared. This is pstack's regression lane, scaled to one project.
- **Rubric:**
  1. Take the issue's `live:` line verbatim as the scenario and its pass condition. Do not
     invent a friendlier scenario.
  2. Run it at head. Record the artifact the line names (a log line, a response field, a
     screenshot path, a measurement) to the evidence path in the profile's `## Report`.
  3. Run the same scenario at `base_ref` (a worktree or a checkout the profile's
     `## Isolation` allows; never by resetting the working tree of the implementing
     session). Record the artifact.
  4. **If trunk lacks the feature**, record that fact and gate instead on the behaviour
     the diff adds plus the end state the user waits for. Do not invent a trunk result.
  5. When the issue carries a `perf:` line that is not `n/a`, measure trunk first, then
     head, interleave probes if the metric is noisy, and compare against the failing
     number the line states. Unlike scenarios get absolute budgets, never a ratio.
  6. When the observation disagrees with expectation, suspect the observation method
     before the system, and say which one you checked.
- **Adjudication:** `✅` only when head meets the pass condition and trunk either meets
  the pre-change expectation or is recorded as lacking the feature. A head run that
  passes with a scenario different from the `live:` line is `❌` (wrong instrument).

## Evidence line

```
### Seat — regression: ✅ / ❌ / N/A  · evidence: live: "<verbatim line>" · head <sha>: <observed → pass|fail, artifact path> · base_ref <ref@sha>: <observed | "feature absent on trunk; gated on added behaviour"> · perf: <metric trunk=<v> head=<v> fails-at=<v> | n/a: <reason>>
```
