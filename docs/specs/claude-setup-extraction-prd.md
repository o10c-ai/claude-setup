# PRD — extract the Claude Code setup into `o10c-ai/claude-setup` and add contract skills

Derived from the 2026-09-09 grill (`CONTEXT.md`, `docs/adr/0002..0004`, trail
`.audit/claude-setup-extraction.tsv`).

## Problem Statement

The Claude Code baseline (skills, hooks, output style, spec-to-session pipeline)
is buried in a private nix repo, references upstream libraries by absolute
`~/.config/nix/services/` paths, and cannot be shared or reused by a second
machine or person. Three stack-specific skills that exist in the Phoenix project
(`do-work`, `post-impl-review`, `grill-with-visuals`) encode phases that are
generic but are trapped in one project, and one of them would be silently
dropped the moment a global skill of the same name ships.

## Solution

A public repo `o10c-ai/claude-setup` owns everything stack-independent:
skills, hooks, output styles, docs, and the upstream libraries as `vendor/`
submodules. Three contract skills (`/implement`, `/review`,
`/grill-with-visuals`) read a project profile at `.claude/<skill>.md` and fall
back when it is absent. The nix repo consumes claude-setup as one recursive
submodule and keeps only private files. the Phoenix project is decomposed into the
first example profile set.

## User Stories

1. As the operator, I want `~/.claude/skills/*` to resolve into one checkout, so that `git pull` there updates every machine without a rebuild.
2. As the operator, I want `settings.json` to stay private and read-only, so that the lean preset and the EACCES behaviour I chose are unchanged.
3. As a session in the Phoenix project, I want `/review` to run the seats the Phoenix project defines, so that nothing the committee catches today is lost.
4. As a session in a fresh repo with no profile, I want `/review`, `/implement`, and `/grill-with-visuals` to still work, so that onboarding is a later step, not a prerequisite.
5. As the slicer running `/to-issues`, I want to name mandatory review seats per issue, so that hazards a diff cannot reveal are still reviewed.
6. As `autonomous-run`, I want `/implement` and `/review` as the inner loop of one issue, so that every issue ends with a checkpoint on its head SHA.
7. As a reader of the public repo, I want `docs/set-aside.md`, so that pstack pieces we skipped are visible with their revisit triggers.
8. As a reader, I want a NOTICE with attributions for pstack, mattpocock/skills, and cmux-skills.
9. As the operator, I want no private name (team, initiative, internal domains, private skills) in the public history.
10. As a second stack, I want `examples/<stack>/` to show what a profile set looks like, starting with Phoenix.

## Definition of Done

All of the following on one head of each repo:

- `git -C ~/.config/nix status --porcelain` is empty; `git log --oneline -6` shows the three split commits plus the extraction wiring commit.
- `readlink ~/.claude/skills/review ~/.claude/skills/implement ~/.claude/skills/grill-with-visuals` all point under `~/.config/nix/services/claude-setup/skills/`.
- `cd /tmp && claude -p --model claude-sonnet-5 "Do not call tools. List skills named review, implement, grill-with-visuals with the first 8 words of each description."` names all three.
- `gh repo view o10c-ai/claude-setup --json visibility,defaultBranchRef` returns `PUBLIC` and `main`; `git -C <checkout> log -p | grep -cE 'sk-ant-|ghp_|lin_api_|<internal-domain>|--team <team>'` returns 0.
- `bash skills/to-issues/scripts/check-issue.sh` rejects a body without a `review:` line and accepts one with `review: auto`.
- In the Phoenix project worktree branch: `.claude/{implement,review,grill-with-visuals}.md` exist, `.claude/skills/{do-work,post-impl-review,grill-with-visuals}` do not, and `grep -c post-impl-review CLAUDE.md` is 0.

## Data Shape

The organizing structure is **contract + profile + fallback** (ADR 0002). A
contract skill is a fixed phase list with named slots. A profile is a markdown
file with one `##` section per slot, optionally a first-line `not applicable`
or `delegate: <project skill>`. The `/review` profile's core shape is a
**seat catalogue**: rows of seat name, trigger, and rubric path, plus a guard
table of concern to guard command. `/review` derives the run set as
`named(issue) ∪ fired(diff) ∪ contract_seats`, or `all ∪ contract_seats` at a
gate (ADR 0003).

## Implementation Decisions

- History: `git filter-repo --subdirectory-filter home-manager/claude-code` on a fresh clone, with private paths removed across history (the private `<team>-*`, serena-*, sym-*, gitea-tea, sentry-cli, claude-config-management, claude-plugin-management, o10c-automation-dev, agents/, settings.json, ccstatusline.json). **One-way door**: public history cannot be un-published; a secrets and private-name scan gates the push.
- Vendored format references (`CONTEXT-FORMAT.md`, `ADR-FORMAT.md`) are bundled into the `grill-with-docs` override, because the Skill tool reports the symlink path as base directory, so relative `vendor/` paths do not resolve from `~/.claude/skills/`.
- The public `CLAUDE.md` carries the Shell, cmux, and Autonomy sections; the private nix `CLAUDE.md` keeps its declarative-config section and `@`-imports the public one.
- `settings.example.json` is the private file minus the one internal-domain `WebFetch` allow entry.
- Nix ADR 0001 (Bash allowlist) moves to the public repo as ADR 0001; grill ADRs renumber 0002-0004. Nix `CONTEXT.md` terms merge into the public glossary.
- Contract skill for `/review` carries the two contract seats (audit, regression) and the dispatch protocol; the Phoenix project seat files move to `.claude/docs/review/seats/` in the Phoenix project and the profile points there.
- `autonomous-run` Run step 3 becomes: run `/implement` for the unit, then `/review` at the end of the issue; full committee when `Review gate: interaction` or last slice.
- the Phoenix project work happens in a new worktree on branch `feat/claude-setup-profiles`; the `main` worktree is on another feature branch with a dirty tree and is not touched.

## Verification Harness and Baseline

Baseline before change: `ls ~/.claude/skills/` (20 entries), `claude -p` skill listing, `check-issue.sh` on the current template body (passes). After: same probes plus the Definition of Done. Perf: n/a, no hot path; context cost checked with `/context` delta on the three new skill descriptions only.

## Testing Decisions

Behavioural probes only: symlink targets, `claude -p` skill listing, lint script on fixture bodies, grep-based scans on history. No unit tests exist for shell hooks; `check-issue.sh` gets two fixture bodies under `skills/to-issues/fixtures/`.

## Throughput Checkpoint

- **Blocking first steps.** Split commits in nix (history must be final before filter-repo); filter-repo; scan.
- **Independent workstreams.** Contract skills and docs (public repo) ‖ the Phoenix project decomposition (worktree) ‖ nix wiring draft. They join at rebuild.
- **Shared mutable state.** `home-manager/claude-code/` is deleted from nix only after the submodule is in place; single owner, serialized.
- **Smallest safe decomposition.** One session, four phases, trail rows per phase; no Linear issues (operator is the only consumer and the whole run is one sitting).

## Out of Scope

OpenCode/Pi profiles; a second stack example; re-enabling `/loop`; publishing the nix repo; changing the lean preset.
