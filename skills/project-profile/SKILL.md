---
name: project-profile
description: Doctor and initialiser for the project profiles the contract skills (implement, review, grill-with-visuals, orchestrate) read from .claude/<skill>.md. "doctor" (default) checks the project's profiles against the interface in profiles/slots.tsv and explains each failure; "init" scaffolds missing profiles from the nearest example or a skeleton and leaves TODO markers for the project-specific parts. Use for "/project-profile", "check the profiles", "set up this project for the contract skills", or when a contract skill reports an invalid profile.
---

# Project profile: doctor and init

The contract skills are stack-agnostic; everything stack-specific lives in the project's
`.claude/<skill>.md` profile (ADR 0002). The interface those skills expect is one file,
`profiles/slots.tsv` in claude-setup, and one script enforces it. This skill runs that
script and turns its findings into fixes.

Both scripts live next to this file; from a consuming machine they resolve as
`~/.claude/skills/project-profile/scripts/`.

## `doctor` (default)

```
~/.claude/skills/project-profile/scripts/check-profile.sh [contract ...]
```

Prints one line per finding and one summary line per contract: `ok`, `absent`
(the contract falls back; fine), `not-applicable`, `delegate:<skill>`, or `invalid`.
Exit 1 only when something is invalid.

For each finding, do this, in order, and re-run until the summary has no `invalid`:

| Finding | Fix |
|---|---|
| `.claude/skills/<contract>/ exists and is silently shadowed` | Decompose the project skill into the profile (see `examples/phoenix/`), or rename it and put `delegate: <new-name>` on the profile's first line. Never leave a same-name skill. |
| `is git-ignored` / `would be git-ignored` | In `.gitignore`, `.claude/` must become `.claude/*`, followed by `!.claude/*.md` and `!.claude/docs/`. Git cannot re-include a file under an excluded directory. |
| `missing required slot '## X'` | Add the section. The finding carries the slot's description; the example profile shows a filled one. |
| `slot '## X' is empty` / `has no table` / `lacks a 'Col' column` | The contract reads that slot by structure, not prose. Match the shape in `profiles/slots.tsv`. |
| `'## X' names <path>, which does not exist` | Create the rubric or doc, or drop the row. A seat without a rubric file cannot be adjudicated. |
| `unresolved placeholder` | Replace `TODO:`, `<app>`, `<lib>`, `<fill …>` with the project's real names and commands. Verify commands by running them, not by assuming. |
| `warning: section '## X' is not a slot` | Harmless. Either delete it or move its content into a slot the contract reads. |
| `delegate:` warning | Migration state. Plan the decomposition; it is not a steady state. |

Report the final summary block verbatim, then one line per contract that changed.

## `init`

```
~/.claude/skills/project-profile/scripts/init-profile.sh [--stack phoenix|generic] [--force] [contract ...]
```

Detects the stack (`mix.exs` with `:phoenix` → `phoenix`; otherwise `generic`), fixes
`.gitignore` as above, and writes each missing profile: a copy of
`examples/<stack>/.claude/<contract>.md` when one exists (plus the seat rubrics the
example ships), else a skeleton generated from `profiles/slots.tsv` with one `TODO:` line
per slot. Existing profiles are skipped unless `--force`.

After it runs, the doctor is red by construction. Resolve every placeholder yourself:

1. **Commands** (`## Feedback loops`, `## Guards`, `## Evidence pack`, `## Commit`):
   run each candidate in the project before writing it down. A guard that does not
   exist is a `## Seats` row, not a guard.
2. **Seats**: the project-specific judgment no guard makes. A multi-tenant app names a
   tenant-isolation seat; a CLI does not. Write the rubric file first, then the row.
3. **Paths**: every path the profile names must exist on disk now, not later.
4. **Optional slots** you don't need: delete the section rather than leaving prose.

Then run `doctor`. Stop when it prints `ok` for every contract that applies and
`not-applicable` for the rest.

## Where the contracts use this

Each contract skill runs the doctor for its own name as phase 0. `absent` → the skill's
fallback. `invalid` → the skill stops and says: run `/project-profile`. This replaces
silent fallback-on-broken-profile, which is how a seven-seat table with one rubric file
went unnoticed.

## Tests

`scripts/test.sh` runs the doctor and init against fixtures and the shipped example;
run it after editing either script or `profiles/slots.tsv`.
