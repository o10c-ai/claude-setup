#!/usr/bin/env bash
# PreToolUse hook on the Bash tool — selectively wraps commands whose
# output is likely to surface secrets, so the wrapped form passes
# through `redact-secrets.sh` before Claude captures it.
#
# Why selective? Wrapping every command rewrites the tool input from
# `mix test` to `( set -o pipefail; { mix test
# } 2>&1 | …redact… )`, which makes Claude Code's `permissions.allow`
# matcher fail to recognize broad rules like `Bash(mix:*)` — the
# rewritten command no longer starts with `mix`. Result: every Bash
# call prompts for permission. By wrapping ONLY commands that might
# expose credentials, normal commands keep matching the allowlist.
#
# Risky-command criteria (any match → wrap):
#   - Credential CLIs: op, gh auth, aws sts, gcloud auth print-…
#   - Env-dump utilities: env (standalone), printenv, set
#   - Reads of credential-shaped paths: *.env, */credentials*,
#     *.aws/*, *.config/op/*
#   - kubectl get/describe secret
#   - echo/printf with a variable or command expansion ($NAME, ${…},
#     $(…), backtick) — `echo $GH_TOKEN` would otherwise print a secret
#     into context. Because the wrapped form no longer starts with
#     `echo`, the global `Bash(echo:*)` allow rule deliberately fails
#     to match, so expansion-bearing echo still prompts AND its output
#     is redacted. Plain echo (incl. special params like $?) passes
#     through and is covered by the allowlist. See docs/adr/0001.
#
# Anything else passes through unchanged. Defense-in-depth covers the
# common leak vectors; routine commands keep the allowlist working.

set -euo pipefail

REDACTOR="$HOME/.claude/hooks/redact-secrets.sh"

# If the redactor isn't installed (e.g., between rebuilds), fail open —
# return the input unchanged rather than blocking the user's work.
if [ ! -x "$REDACTOR" ]; then
  cat
  exit 0
fi

input=$(cat)
orig_cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Empty / missing command — pass through.
if [ -z "$orig_cmd" ]; then
  printf '%s' "$input"
  exit 0
fi

# --- Risky-command detection -----------------------------------------

# Match a credential CLI invoked as a command word (start of line, or
# preceded by `;`, `&&`, `||`, `|`, `(`, or whitespace), and bounded on
# the right so `MIX_ENV=` is not a false-positive for `env`.
risky_cmd_re='(^|[[:space:];&|(])(op|printenv|env|set|gh[[:space:]]+auth|aws[[:space:]]+sts|gcloud[[:space:]]+auth[[:space:]]+print|kubectl[[:space:]]+(get|describe)[[:space:]]+secret)([[:space:]]|[|;&]|$)'

# Match reads of credential-shaped paths anywhere in the command.
risky_path_re='(\.env([[:space:]]|/|$)|/credentials([[:space:]]|/|$)|\.aws/|\.config/op/)'

# Match echo/printf as a command word whose segment carries an
# expansion: $NAME, ${…}, $(…), or a backtick. Special params ($?, $#,
# $$, $!, $0-9) do NOT match — plain status echoes stay allowlisted.
echo_leak_re='(^|[[:space:];&|(])(echo|printf)[^|;&]*(\$[{(A-Za-z_]|`)'

wrap=false
if [[ "$orig_cmd" =~ $risky_cmd_re ]] || [[ "$orig_cmd" =~ $risky_path_re ]] || [[ "$orig_cmd" =~ $echo_leak_re ]]; then
  wrap=true
fi

# Safe path — emit no updatedInput, original command runs as-is. The
# tool output is NOT redacted; that's the cost of preserving the
# allowlist match.
if [ "$wrap" = false ]; then
  printf '%s' "$input"
  exit 0
fi

# --- Wrap risky commands ---------------------------------------------

wrapped=$(jq -nr \
  --arg orig "$orig_cmd" \
  --arg redactor "$REDACTOR" \
  '"( set -o pipefail; { " + $orig + "\n} 2>&1 | " + $redactor + " )"')

jq -nc \
  --arg cmd "$wrapped" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: { command: $cmd }
    }
  }'
