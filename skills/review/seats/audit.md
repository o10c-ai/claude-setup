# Seat — Audit (contract seat)

> One seat per file: read **only this file** when adjudicating this seat.
> Contract: [`../SKILL.md`](../SKILL.md). Present in every project, profile or not.
> Adjudication is always *independent of the author*; `❌`/findings are not self-dismissible.

- **Trigger:** always. Runs in every checkpoint and every full committee.
- **Concern:** the PR body, the commit messages, and the implementing session's summary
  are claims. This seat reads the artifacts and checks that the claims are earned.
- **Rubric:**
  1. **Trust artifacts, not self-reports.** Read the diff, not the description of the
     diff. For every claim in the PR body ("adds X", "tests cover Y", "no behaviour
     change"), find the hunk or the test that makes it true, or write the gap.
  2. **The evidence pack is raw output.** Each guard line must show an invocation, raw
     output, and an exit code. A line that is a conclusion ("lint clean") with no output
     is missing evidence — say so; do not re-run it silently.
  3. **Red is a colour, not a measurement.** A failing check cited as proof that a test
     "catches the bug" only counts if the failure content matches the predicted
     disagreement. Quote the assertion diff, not the assertion text.
  4. **Convergence claims key on behaviour.** A probe that a deploy or restart "picked up
     the change" must observe something only the new artifact produces, never an identity
     field (a same-SHA restart reports the new SHA with the old code).
  5. **Scope drift.** Files changed that the issue's "What to build" does not account for
     are listed, each with one line: in scope, out-of-band fix (own commit?), or
     unexplained.
  6. **Reversions and belt-and-suspenders.** Changes that "might help" and were left to
     ride are a finding; the contract for autonomous work is revert what did not help.
- **Adjudication:** a claim without an artifact is `❌` until the artifact exists. The
  author cannot answer "it's obviously fine"; the fix is to add the test, the output, or
  the sentence in the PR body that retracts the claim.

## Evidence line

```
### Seat — audit: ✅ / ❌  · evidence: <N claims in PR body/summary → N located in diff/tests (list gaps file:line or "claim: <text> → no artifact")>; evidence pack: <M guard lines, all with raw output + exit | lines missing output: …>; scope: <files outside "What to build": none | list with classification>; red-is-a-colour: <checks cited as failing-for-the-right-reason → assertion diff quoted | not applicable>
```
