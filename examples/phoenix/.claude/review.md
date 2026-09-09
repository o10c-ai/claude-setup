# `/review` profile — Phoenix / Ash / LiveView

Project profile for the `review` contract skill (claude-setup). Fill the slots; keep
deterministic detection in guards and reserve seats for the judgment no guard can make.
Replace the placeholders (`<app>`, `<lib>`) with your names.

## Guards

Green = the evidence line for that concern; the committee does not re-review it.

| Concern | Guard (invocation → green result) |
|---|---|
| Compiler and typing warnings | `mix compile --warnings-as-errors` → exit 0 |
| Style, complexity, project credo checks | `mix credo --strict` → `no issues` |
| Silent `{:error, _}` swallow | project credo check: `NoSilentErrorTuple` |
| Catch-all `rescue` that swallows | project credo check: `AvoidSilentRescue` |
| `authorize?: false` in prod code | project credo check: `AvoidAuthorizeFalse` |
| Hardcoded user-facing prose in HEEx | project credo check: `AvoidHardcodedString` |
| Untranslated / fuzzy `.po` entries | `mix gettext.extract --check-up-to-date` plus a project `mix gettext.untranslated` task → 0 |
| Formatting | `mix format --check-formatted` → exit 0 |
| Test suite | `mix test` → `N tests, 0 failures` |

## Seats

One file per seat under `.claude/docs/review/seats/`. Each file: trigger, rubric,
adjudication, evidence-line template. ★ = wave 1.

| ★ | Seat | Fires when the diff… | Rubric |
|---|---|---|---|
|   | Server-side authorization | adds or changes a mutating `handle_event`, plug, seed, or domain action | `.claude/docs/review/seats/server-side-authorization.md` |
| ★ | Cross-PR contract surface | changes a public function's argument contract, adds a bare-arg public function, or renames a key threaded across modules | `.claude/docs/review/seats/cross-pr-contract-surface.md` |
| ★ | Divergent write paths | adds or changes a write call site (form, wizard step, worker, seed, factory) on a domain action that already has another caller | `.claude/docs/review/seats/divergent-write-paths.md` |
|   | Test-surface enumeration | adds any new behavioural surface | `.claude/docs/review/seats/test-surface-enumeration.md` |
|   | Documentation surface | adds or removes a public symbol, Ash action, event, config flag, or mode | `.claude/docs/review/seats/documentation-surface.md` |
|   | Wire-format boundaries | changes Oban args, PubSub messages, GenServer casts, or a DOM-reachable `handle_event` head | `.claude/docs/review/seats/wire-format-boundaries.md` |
|   | Route descriptor sync | changes `router.ex` or route helper modules | `.claude/docs/review/seats/route-descriptor-sync.md` |

## Evidence pack

Write `tmp/review/evidence.md` before spawning any seat. Raw output only:

```
git diff --stat <base_ref>...HEAD
git diff --name-only <base_ref>...HEAD ; git status --porcelain
mix compile --warnings-as-errors > tmp/review/compile.txt 2>&1; echo "exit: $?"
mix credo --strict > tmp/review/credo.txt 2>&1; echo "exit: $?"
mix format --check-formatted > tmp/review/format.txt 2>&1; echo "exit: $?"
mix test > tmp/review/test.txt 2>&1; echo "exit: $?"
```

Paste each file's tail and exit code into the pack under the guard's name. Include any
migration verification already performed.

## Isolation

Read-only seats (contract, test-surface, documentation, wire-format, route sync) run in
parallel in the main repo. A seat that runs `mix test` or touches the database gets its
own scratch database via `MIX_TEST_PARTITION=<seat-name>` **in the main repo**. Do not
use `isolation: "worktree"` for a review seat: it isolates files, not Postgres, and costs
a full recompile plus a permission refusal per compound command — measured at ~25 minutes
of overhead on a seat whose real work is two. Worktrees are for seats that must *write*
to the repo, which no review seat does.

## Full committee triggers

Beyond the pipeline gates (`Review gate: interaction`, last slice): the diff touches more
than one umbrella/poncho lib, adds LiveView event handlers, adds routes or navigation, or
modifies authentication or authorization.

## Report

Workpad: `tmp/review/<branch>.md`. Evidence pack: `tmp/review/evidence.md`. Both are
git-ignored; the verdict summary is pasted into the PR before merge.
