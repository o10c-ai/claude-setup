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
adjudication, evidence-line template. ★ = wave 1. Every rubric path must exist
(`check-profile.sh` fails otherwise); this example ships one seat.

| ★ | Seat | Fires when the diff… | Rubric |
|---|---|---|---|
| ★ | Server-side authorization | adds or changes a mutating `handle_event`, plug, seed, or domain action | `.claude/docs/review/seats/server-side-authorization.md` |

Seats a Phoenix/Ash project typically adds next, each with its own rubric file:
cross-PR contract surface (public function argument contracts, keys threaded across
modules); divergent write paths (a second caller on a domain action); test-surface
enumeration; documentation surface; wire-format boundaries (Oban args, PubSub, GenServer
casts, DOM-reachable `handle_event` heads); route descriptor sync (`router.ex`). Add a row
only once its rubric file exists.

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
