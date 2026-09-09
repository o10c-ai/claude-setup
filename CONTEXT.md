# Claude Code setup (o10c-ai)

The public, declarative Claude Code baseline: skills, hooks, output styles, and
the spec-to-session pipeline. Projects consume it through the nix config and
supply stack-specific parts through profiles.

## Language

**Contract skill**:
A skill shipped by this repo whose phases, inputs, and outputs are fixed, but
whose stack-specific parts are read from the project at invocation time.
`/implement`, `/grill-with-visuals`, `/review` are contract skills.
_Avoid_: abstract skill, base skill, global skill

**Project profile**:
The markdown file at `.claude/<skill>.md` in a project that fills a contract
skill's stack-specific slots (commands, surfaces, lane catalogue, render
recipe). One profile per contract skill; may point at project scripts.
_Avoid_: instance, implementation, config, override

**Fallback**:
What a contract skill does when the project profile is absent or declares the
contract not applicable. `/grill-with-visuals` falls back to `grill-with-docs`;
`/review` and `/implement` run a generic default and name the example profile
to copy.
_Avoid_: default mode, degraded mode

**Example profile**:
A ready-to-copy project profile for one stack, kept under
`examples/<stack>/` in this repo.
_Avoid_: template, starter

**Instance decomposition**:
Splitting an existing project skill into the parts that belong to a contract
skill (phases, invariants, output shape) and the parts that become its
project profile (commands, paths, catalogues, rubrics).
_Avoid_: migration, port

## Review

**Seat**:
One orthogonal review concern with its own trigger, rubric, adjudication rule,
and evidence line, judged independently of the session that wrote the code.
_Avoid_: lane, check, reviewer, rule

**Checkpoint**:
The `/review` run at the end of one issue: its named seats plus the seats
whose triggers fire on the diff.
_Avoid_: partial review, quick review

**Full committee**:
Every seat in the profile's catalogue plus the two contract seats, run on one
head SHA. Only at a review gate or at the Definition of Done.
_Avoid_: full review, final review

**Contract seat**:
A seat defined by the `/review` contract itself, present in every project:
the audit seat and the regression seat.
