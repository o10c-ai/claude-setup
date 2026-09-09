# Project profiles

A **contract skill** ships here with fixed phases. Its stack-specific parts
are read at invocation time from a **project profile**: a markdown file at
`.claude/<skill>.md` in the project (ADR 0002).

## Format

```
.claude/implement.md
.claude/review.md
.claude/grill-with-visuals.md
```

Plain markdown. Optional first non-blank line, one of:

- `status: not applicable` — the contract does not apply to this project; the
  skill runs its fallback (`/grill-with-visuals` → `grill-with-docs`;
  `/implement` and `/review` run their generic default).
- `delegate: <project-skill-name>` — invoke that differently named project
  skill instead. A migration escape hatch for an instance not yet decomposed
  into contract + profile; not a steady state.

Then one `## <Slot>` section per slot the contract defines. Unknown sections
are ignored. A profile may be as rich as it needs to be and may point at
project docs and scripts; only the contract's phases are fixed.

## Slots per contract

### `/implement`

| Slot | Contents |
|---|---|
| `## Read first` | Documents to read before touching the area |
| `## Branch rules` | Branch naming, protected branches, base ref |
| `## Feedback loops` | Ordered commands (lint, test, typecheck), with wrappers |
| `## Commit` | The commit command and why (hooks, env wrappers) |
| `## Review` | Project triggers that upgrade a checkpoint to the full committee |

### `/review`

| Slot | Contents |
|---|---|
| `## Guards` | Table: concern → deterministic guard command; a green guard is the evidence, the committee does not re-review it |
| `## Seats` | Table: seat name (kebab-case) → fires when → rubric path. `check-issue.sh` validates `review:` lines against the first column |
| `## Full committee triggers` | Project-level conditions beyond the pipeline gates |
| `## Evidence pack` | Commands whose raw output populates the pack before any seat spawns |
| `## Isolation` | How a state-mutating seat isolates (e.g. a test DB partition) |
| `## Report` | Where the workpad goes |

### `/grill-with-visuals`

| Slot | Contents |
|---|---|
| `## Surfaces` | What counts as a visual decision in this project |
| `## Render` | How to render one surface in isolation: gallery contract, registry, URL pattern, default fan-out |
| `## Capture` | Spec destination and the durable currency (HEEx, Mermaid, prose) |
| `## Cleanup` | Paths to sweep before the session ends |
| `## Known walls` | Path to the capability backlog |

## The same-name hazard

Do **not** create a project skill with a contract skill's name. On Claude Code
2.1.266 a project `.claude/skills/<name>/` that shares its name with a
user-scope skill is silently dropped: it appears neither in the skill list
nor on `Skill` invocation, and the user-scope copy wins. This is why the
contract reads a profile instead of relying on shadowing. Existing instances
are decomposed (`examples/phoenix/` shows the result) or renamed and reached
through `delegate:`.

## `.gitignore`

Many projects ignore `.claude/` wholesale. Profiles must be tracked, so add:

```
!.claude/*.md
```

after the ignore rule (or `!.claude/implement.md` etc. individually).

## Cost

A profile costs nothing until its contract skill is invoked. It is not a skill,
so it adds no line to the skill list in any session.
