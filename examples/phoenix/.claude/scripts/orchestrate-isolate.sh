#!/usr/bin/env bash
# Isolation hook for claude-setup's orchestrate launcher (skills/orchestrate/scripts/launch.sh).
# Thin adapter over the repo's own worktree tooling; the mechanics live in
# local.just / bin/worktree-init and .claude/docs/parallel-worktrees.md.
#
#   add <branch> <base_ref>   jl worktree-add: sibling worktree, next free slot, devenv.local.nix
#                             with the slot PORT. Last stdout line = worktree path.
#   env                       PORT from devenv.local.nix (Phoenix + base_url + tidewave);
#                             Postgres is a per-checkout unix socket, nothing to export.
#   up                        devenv up -d (this worktree's Postgres) + mix setup (deps, db, seeds).
set -euo pipefail
cmd="${1:-}"; shift || true
case "$cmd" in
  add)
    branch="${1:?branch}"; base="${2:-origin/main}"
    # jl is a devenv script; reach it through devenv shell from this checkout.
    devenv shell -q -- jl worktree-add "$branch" '' "$base" >&2
    dir="$(cd "../${branch//\//-}" && pwd -P)"
    printf '%s\n' "$dir" ;;
  env)
    [ -f devenv.local.nix ] || { echo "no devenv.local.nix here: not a slotted worktree (run bin/worktree-init <slot>)" >&2; exit 1; }
    port="$(sed -n 's/.*env.PORT = "\([0-9]*\)".*/\1/p' devenv.local.nix)"
    printf 'PORT=%s\nSLOT=%s\nMIX_TEST_PARTITION=\n' "$port" "$((port - 4002))" ;;
  up)
    devenv up -d >&2
    devenv shell -q -- mix setup >&2 ;;
  *) echo "usage: orchestrate-isolate.sh add <branch> [base_ref] | env | up" >&2; exit 2 ;;
esac
