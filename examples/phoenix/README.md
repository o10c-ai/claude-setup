# Phoenix example profiles

Ready-to-copy project profiles for a Phoenix/LiveView app managed with devenv.
They fill the slots of the four contract skills (`docs/profiles.md`):

| File | Contract | What it supplies |
|---|---|---|
| `.claude/implement.md` | `/implement` | devenv-wrapped `mix lint` / `mix test`, branch rules, `devenv shell -- git commit`, full-committee triggers |
| `.claude/review.md` | `/review` | the credo/mix guard table, the seat catalogue with triggers and rubric paths, evidence-pack commands, test-DB isolation |
| `.claude/grill-with-visuals.md` | `/grill-with-visuals` | the dev prototype gallery as the render surface, HEEx as the captured currency, cleanup paths |
| `.claude/orchestrate.md` | `/orchestrate` | implementer budgets, the worktree + `MIX_TEST_PARTITION` isolation recipe (serial until enabled), extra drift-check inputs |

## Copy

```sh
cp examples/phoenix/.claude/*.md <project>/.claude/
```

Then edit paths and commands to match the project. `review.md` names seven
rubric files under `.claude/docs/review/seats/`; only
`server-side-authorization.md` ships here as the worked example, the other six
must be authored in the project (one file per seat: trigger, rubric,
adjudication rule, evidence-line template) before those seats can fire.

If the project ignores `.claude/`, add after the ignore rule:

```
!.claude/*.md
```
