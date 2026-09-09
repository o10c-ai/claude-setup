---
status: accepted
date: 2026-09-09
---

# Contract skills read a project profile instead of being shadowed by a project skill

`/implement`, `/grill-with-visuals`, and `/review` need stack-specific behaviour
per project while their phases stay fixed in this repo. Each contract skill is a
single user-scope skill that, on invocation, reads `.claude/<skill>.md` in the
project (the project profile); a missing profile triggers the skill's fallback
(`/grill-with-visuals` → `grill-with-docs`; the others run a generic default and
name the example profile to copy).

## Considered options

- **Same-name project skill shadows the global one.** Rejected on evidence:
  on Claude Code 2.1.266 (2026-09-09), a throwaway project with
  `.claude/skills/show-in-pane/SKILL.md` and `.claude/skills/handoff/SKILL.md`
  loaded its distinct-name probe skill but dropped both same-named ones from
  the listing and on `Skill` invocation; the user-scope copy won each time.
- **Global router that `Skill`-invokes a differently named project skill.**
  Rejected: every project skill adds a listing line to every session in that
  project, the router is a pass-through layer, and the naming convention
  needs its own lint. Bundled scripts, its one advantage, are recovered by
  letting the profile point at project `scripts/` paths.

## Consequences

- A project skill that shares a contract skill's name is silently dropped
  (the shadowing experiment above). Existing instances, e.g. the Phoenix project's
  `.claude/skills/grill-with-visuals/`, must be decomposed into the contract
  plus a profile, or renamed. The profile may carry a `delegate: <project
  skill name>` line so a not-yet-decomposed instance keeps working through a
  differently named project skill during migration.
- A profile may be arbitrarily rich and point at project docs (seat rubrics,
  render recipes, gallery paths); only the contract's phases are fixed.

- Profiles live under `.claude/`, so projects whose `.gitignore` excludes
  `.claude/` must allow `.claude/*.md` explicitly; the README states the line.
- A contract skill must be usable with no profile at all, so the fallback path
  is part of each contract, not an afterthought.
