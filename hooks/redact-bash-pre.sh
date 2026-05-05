#!/usr/bin/env bash
# PreToolUse hook on the Bash tool — wraps the command so its combined
# stdout/stderr passes through the secret redactor before Claude captures it.
#
# Invoked by Claude Code's hook system. Reads the tool input JSON from stdin,
# emits a hookSpecificOutput with `updatedInput.command` set to the wrapped
# form. The Bash tool then executes the wrapped command instead of the
# original — Claude only ever sees redacted output.
#
# Wrapper structure:
#   ( set -o pipefail; { ORIGINAL; } 2>&1 | redact-secrets.sh )
#
# `pipefail` preserves the exit status of the inner command so failed
# commands still report failure. The subshell isolates the option setting.
# `2>&1` ensures stderr is also filtered.

set -euo pipefail

REDACTOR="$HOME/.claude/hooks/redact-secrets.sh"

# If the redactor isn't installed (e.g., between rebuilds), fail open —
# return the input unchanged rather than blocking the user's work. The
# alternative (blocking) breaks Claude Code in a way that's hard to debug.
if [ ! -x "$REDACTOR" ]; then
  cat
  exit 0
fi

input=$(cat)
orig_cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Empty / missing command — pass through unchanged.
if [ -z "$orig_cmd" ]; then
  printf '%s' "$input"
  exit 0
fi

# Build the wrapped form. Use jq's @sh-style escaping by passing $orig_cmd
# as a string arg into a jq expression; jq handles the quoting.
wrapped=$(jq -nr \
  --arg orig "$orig_cmd" \
  --arg redactor "$REDACTOR" \
  '"( set -o pipefail; { " + $orig + "\n} 2>&1 | " + $redactor + " )"')

# Return only the modification — Claude Code merges with the original
# tool_input on its end. Setting `updatedInput.command` is sufficient.
jq -nc \
  --arg cmd "$wrapped" \
  '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: { command: $cmd }
    }
  }'
