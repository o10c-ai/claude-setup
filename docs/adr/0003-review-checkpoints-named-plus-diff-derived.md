---
status: accepted
date: 2026-09-09
---

# Review checkpoints: named seats at slicing time plus diff-derived seats at run time, full committee only at gates

Every issue produced by `to-issues` ends with a `/review` checkpoint, never a
full committee by default. The issue's `## Verify` block carries a
`review: auto` or `review: auto + <seat>, …` line; `check-issue.sh` requires it
and validates seat names against the project profile's catalogue when one
exists. `autonomous-run` invokes `/review` at the end of the issue; `/review`
runs the named seats plus every seat whose trigger fires on the diff. The full
committee runs only on issues marked `Review gate: interaction` and on the last
slice, whose predicate is the PRD's Definition of Done, in both cases on the
merge-ready head SHA before merge.

Two seats live in the contract and run in every project regardless of
profile: an audit seat that reads the diff and the evidence pack and distrusts
the PR body, and a regression seat that runs the issue's `live:` line at
`base_ref` and at head.

## Considered options

- **Runtime only** (the Phoenix project `post-impl-review` today): seats fire on diff
  triggers alone. Rejected because the slicer knows the hazard shape before a
  diff exists and a diff trigger cannot see a cross-PR contract a slice sets up
  for a later slice. The chosen shape degrades to this when every line reads
  `review: auto`.
- **Slicing time only**: seat set fixed in the issue body. Rejected because
  the implementing diff routinely touches surfaces the slicer did not name.
- **Full committee after every issue**: rejected on cost; the Phoenix project
  calibration was ~28 min wall and ~540k subagent tokens for four
  seats.

## Consequences

- The issue template and `check-issue.sh` gain a `review:` line; existing
  issues without it fail the lint until edited.
- pstack's ten live lanes are not adopted as a count; the lane form
  (scenario, artifact, pass predicate) is the seat form, and the audit and
  regression seats are the two lanes kept unconditionally.
