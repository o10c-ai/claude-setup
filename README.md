# claude-setup

A lean, declarative Claude Code baseline: skills, hooks, an output style, and a
spec-to-session pipeline whose stack-specific parts live in each project as
**profiles**. Consumed by symlinking the files you want into `~/.claude/`;
nothing loads unless you link it.

## Layout

```
CLAUDE.md               global instructions (shell, cmux, autonomy) — import it from yours
settings.example.json   the lean preset (deny list, allowlist, hooks); your real file stays private
output-styles/          ConciseEng
hooks/                  rtk-rewrite, secret redaction, concise-nudge, ship-transcript (PreToolUse / UserPromptSubmit / SessionEnd)
skills/                 own skills and overrides (see below)
vendor/                 upstream skill libraries as submodules (mattpocock/skills, pstack-claude, cmux-skills)
examples/phoenix/       example project profiles for the four contract skills
docs/                   pipeline, profiles, context budget, set-aside, adr/, specs/
CONTEXT.md              glossary
.audit/                 decision trail of the extraction
```

## Skills

| Skill | Kind | Role |
|---|---|---|
| `grill-with-docs` | override of mattpocock | plan stress-test; classify questions, run experiments, design one-way doors twice, ADRs with evidence |
| `grill-with-visuals` | **contract** | `grill-with-docs` plus rendered decisions; falls back to `grill-with-docs` without a profile |
| `to-prd` | override | local PRD with a Definition of Done predicate, data shape, harness, throughput checkpoint |
| `to-issues` | override | Linear issues, one runnable predicate each; `scripts/check-issue.sh` lints bodies |
| `autonomous-run` | own | drive one issue to its predicate; wraps `implement` → `review`; trail at `.audit/<id>.tsv` |
| `implement` | **contract** | tracer bullet, red-green-refactor, the project's feedback loops, review, commit |
| `review` | **contract** | committee of seats with independent adjudication; checkpoint per issue, full committee at gates |
| `project-profile` | own | doctor + init for the profiles the contract skills read; `profiles/slots.tsv` is the interface (ADR 0006) |
| `show-in-pane`, `cmux-browser` | own | cmux pane display and browser automation |
| `linear-cli`, `delegate`, `invoke-opencode-acp` | own | tooling skills, off by default |
| from `vendor/` | symlinked | `diagnose`, `prototype`, `tdd`, `triage`, `zoom-out`, `improve-codebase-architecture`, `write-a-skill`, `teach`, `handoff`, `show-me-your-work`, `figure-it-out`, … |

A **contract skill** has fixed phases and reads `.claude/<skill>.md` in the
project for commands, catalogues, and paths. See `docs/profiles.md` and
`docs/pipeline.md`. Do not create a project skill with a contract skill's
name; it is silently dropped (same-name hazard, ADR 0002).

## Consume

Clone with submodules:

```sh
git clone --recursive https://github.com/o10c-ai/claude-setup
```

**home-manager (nix).** Point an out-of-store symlink helper at the checkout so
`git pull` is live without a rebuild, one line per skill:

```nix
let
  setup = "${config.home.homeDirectory}/path/to/claude-setup";
  fromSetup = sub: config.lib.file.mkOutOfStoreSymlink "${setup}/${sub}";
in {
  home.file = {
    ".claude/skills/review".source            = fromSetup "skills/review";
    ".claude/skills/implement".source         = fromSetup "skills/implement";
    ".claude/skills/grill-with-visuals".source = fromSetup "skills/grill-with-visuals";
    ".claude/skills/prototype".source         = fromSetup "vendor/mattpocock-skills/skills/engineering/prototype";
    ".claude/hooks/rtk-rewrite.sh"            = { source = fromSetup "hooks/rtk-rewrite.sh"; executable = true; };
    ".claude/output-styles/concise-eng.md".source = fromSetup "output-styles/concise-eng.md";
  };
}
```

Keep `settings.json` and your private `CLAUDE.md` in your own config; import
this repo's `CLAUDE.md` with an `@/abs/path/to/claude-setup/CLAUDE.md` line.

**Without nix.** Same idea with `ln -s`:

```sh
S=$PWD; mkdir -p ~/.claude/skills ~/.claude/hooks ~/.claude/output-styles
ln -s $S/skills/review ~/.claude/skills/review
ln -s $S/skills/implement ~/.claude/skills/implement
ln -s $S/hooks/rtk-rewrite.sh ~/.claude/hooks/
cp settings.example.json ~/.claude/settings.json   # then edit
```

Hooks and env vars are read at process start: quit and reopen Claude Code
after changing them.

## Profiles

Run `/project-profile init` in the project (or
`skills/project-profile/scripts/init-profile.sh`): it copies
`examples/<stack>/.claude/*.md` or a skeleton, fixes `.gitignore`
(`.claude/*` + `!.claude/*.md` + `!.claude/docs/` + `!.claude/scripts/`), and leaves `TODO:` markers.
`/project-profile` (doctor) then reports what is still missing; the contract
skills refuse to run on an `invalid` profile. The interface is
`profiles/slots.tsv`, described in `docs/profiles.md`.

## Docs

- `docs/pipeline.md` — grill → to-prd → to-issues → autonomous-run(implement → review)
- `docs/profiles.md` — profile format, slots, the same-name hazard; `profiles/slots.tsv` is the interface
- `docs/context-budget.md` — why the baseline stays small and which levers keep it so
- `docs/set-aside.md` — pstack pieces not adopted, with revisit triggers
- `docs/adr/` — decisions with evidence
- `NOTICE.md` — attributions for the vendored upstreams
