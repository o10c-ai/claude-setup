# Phoenix example profiles

Ready-to-copy project profiles for a Phoenix/LiveView app managed with devenv.
They fill the slots of the three contract skills (`docs/profiles.md`):

| File | Contract | What it supplies |
|---|---|---|
| `.claude/implement.md` | `/implement` | devenv-wrapped `mix lint` / `mix test`, branch rules, `devenv shell -- git commit`, full-committee triggers |
| `.claude/review.md` | `/review` | the credo/mix guard table, the seat catalogue with triggers and rubric paths, evidence-pack commands, test-DB isolation |
| `.claude/grill-with-visuals.md` | `/grill-with-visuals` | the dev prototype gallery as the render surface, HEEx as the captured currency, cleanup paths |

## Copy

```sh
cp examples/phoenix/.claude/*.md <project>/.claude/
```

Then edit paths and commands to match the project. Seat rubrics referenced by
`review.md` live in the project (e.g. `.claude/docs/review/seats/`), not here;
the profile only points at them.

If the project ignores `.claude/`, add after the ignore rule:

```
!.claude/*.md
```
