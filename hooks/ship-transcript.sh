#!/usr/bin/env bash
# SessionEnd hook: archive the finished session transcript off-machine.
#
# Claude Code keeps the full session record (prompts, thinking, tool calls,
# tool outputs) in ~/.claude/projects/<project>/<session-id>.jsonl and deletes
# it after `cleanupPeriodDays` (30 by default). This hook copies it, plus any
# subagent transcripts, to a private sink so a run can be inspected later.
#
# Wiring: settings.json → hooks.SessionEnd → this script. Configuration is one
# env var (set it in settings.json `env` or the shell):
#
#   CLAUDE_TRANSCRIPT_SINK   rsync destination, e.g. "host:/srv/claude-transcripts"
#                            or a local directory. Unset → the hook exits 0 and
#                            does nothing (fail-open; the public baseline ships
#                            no default).
#
# Layout at the sink:
#   <sink>/<project-dir>/<session-id>/transcript.jsonl.gz
#   <sink>/<project-dir>/<session-id>/subagents/agent-*.jsonl.gz
#   <sink>/<project-dir>/<session-id>/meta.json
# where <project-dir> is Claude Code's encoded cwd (e.g. -Users-me-repo), so the
# Loki `session_id` and the archive key are the same string.
#
# Every file passes through redact-secrets.sh (same directory) before it
# leaves the machine. That covers known token shapes only; the archive still
# holds file contents and command output, so the sink must be private.
#
# The upload runs detached with a timeout so a slow network never blocks the
# session from ending. Outcome is logged to ~/.local/state/claude-transcripts/ship.log.

set -u

sink="${CLAUDE_TRANSCRIPT_SINK:-}"
[ -n "$sink" ] || exit 0

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty')"
transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
reason="$(printf '%s' "$input" | jq -r '.reason // "unknown"')"

[ -n "$session_id" ] && [ -f "$transcript" ] || exit 0

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
redactor="$here/redact-secrets.sh"
[ -x "$redactor" ] || redactor="cat"

project_dir="$(basename "$(dirname "$transcript")")"
subagents_dir="$(dirname "$transcript")/$session_id/subagents"
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-transcripts"
mkdir -p "$log_dir"
log="$log_dir/ship.log"

stage="$(mktemp -d "${TMPDIR:-/tmp}/claude-transcript.XXXXXX")" || exit 0

(
  set +e
  ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

  "$redactor" < "$transcript" | gzip -c > "$stage/transcript.jsonl.gz"
  n_sub=0
  if [ -d "$subagents_dir" ]; then
    mkdir -p "$stage/subagents"
    for f in "$subagents_dir"/*.jsonl; do
      [ -f "$f" ] || continue
      "$redactor" < "$f" | gzip -c > "$stage/subagents/$(basename "$f").gz"
      n_sub=$((n_sub + 1))
    done
    for f in "$subagents_dir"/*.meta.json; do
      [ -f "$f" ] && cp "$f" "$stage/subagents/"
    done
  fi

  jq -n \
    --arg session_id "$session_id" \
    --arg project_dir "$project_dir" \
    --arg cwd "$cwd" \
    --arg reason "$reason" \
    --arg host "$(hostname -s 2>/dev/null || hostname)" \
    --arg ended_at "$(ts)" \
    --argjson transcript_bytes "$(wc -c < "$transcript" | tr -d ' ')" \
    --argjson subagents "$n_sub" \
    '{session_id:$session_id, project_dir:$project_dir, cwd:$cwd, reason:$reason,
      host:$host, ended_at:$ended_at, transcript_bytes:$transcript_bytes, subagents:$subagents}' \
    > "$stage/meta.json"

  dest="$sink/$project_dir/$session_id/"
  if command -v timeout >/dev/null 2>&1; then run_to="timeout 120"; else run_to=""; fi
  # Create the parent directory on the sink (remote "host:/path" or local path);
  # macOS ships openrsync, which has no --mkpath.
  case "$sink" in
    *:*) $run_to ssh -o BatchMode=yes "${sink%%:*}" "mkdir -p '${dest#*:}'" >>"$log" 2>&1 ;;
    *)   mkdir -p "$dest" ;;
  esac
  if $run_to rsync -a "$stage/" "$dest" >>"$log" 2>&1; then
    printf '%s ok %s %s reason=%s bytes=%s subagents=%s\n' "$(ts)" "$project_dir" "$session_id" "$reason" \
      "$(wc -c < "$transcript" | tr -d ' ')" "$n_sub" >> "$log"
  else
    printf '%s FAIL %s %s reason=%s (stage kept: %s)\n' "$(ts)" "$project_dir" "$session_id" "$reason" "$stage" >> "$log"
    exit 0
  fi
  rm -rf "$stage"
) </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true
exit 0
