---
status: accepted
date: 2026-09-09
---

# The profile interface is a manifest, and a doctor gates the contract skills on it

ADR 0002 made the contract skills stack-agnostic by reading a per-project
profile. The interface between the two existed only as prose tables in
`docs/profiles.md`, each contract parsed its own slots, and a broken profile
fell back silently to the generic path. The clean-context audit found a
profile naming seven rubric files with one on disk; nothing had noticed.

Decision: `profiles/slots.tsv` is the single definition of the interface
(contract, slot, required/optional, shape, description). One deterministic
script, `skills/project-profile/scripts/check-profile.sh`, enforces it:
missing or empty required slots, tables without the expected column,
dangling rubric and doc paths, unresolved placeholders, the same-name skill
hazard, and git-ignored profiles. Every contract skill runs it as phase 0.
`absent` keeps the fallback; `invalid` stops the skill. A companion
`init-profile.sh` scaffolds profiles from `examples/<stack>/` or a skeleton
generated from the manifest, always leaving `TODO:` markers so the
project-specific judgment (tenant isolation, wire formats, dev gallery) is
authored, never inherited.

## Considered options

- **Let the contract skills judge profile validity in prose.** Rejected:
  that is the silent fallback we had. An LLM reading a profile does not
  notice a path that does not exist.
- **JSON manifest + jq.** Rejected for a TSV: the repo's scripts are
  bash + awk (`check-issue.sh`, the audit trail), and the manifest must be
  readable by an agent without tooling.
- **Doctor judges rubric quality.** Rejected: whether a seat rubric is good
  is a `/review` calibration question answered by running it. The doctor
  checks structure only.

## Consequences

- `docs/profiles.md` describes the manifest; the manifest is authoritative.
  Adding a slot to a contract means one TSV line plus the contract's use of it.
- `scripts/test.sh` pins the behaviour against the shipped example and
  fixtures; run it after touching either script or the manifest.
- `.gitignore` guidance changes: `.claude/` must become `.claude/*` before
  `!.claude/*.md` and `!.claude/docs/` can re-include profiles and rubrics.
  The earlier advice in ADR 0002 and the README did not work.
- The Phoenix example now references only the seat file it ships; the other
  seats are listed as prose so the example itself passes the doctor apart
  from its intentional `<app>`/`<lib>` placeholders.
