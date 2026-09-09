#!/usr/bin/env bash
# Doctor for project profiles: does .claude/<contract>.md match the interface the
# contract skills expect? Interface = profiles/slots.tsv (ADR 0006).
#
# Usage: check-profile.sh [--root DIR] [--quiet] [contract ...]
#   contract   implement | review | grill-with-visuals | orchestrate (default: all)
#   --root     project root (default: git toplevel of cwd, else cwd)
#   --quiet    summary lines only
# Output: one line per finding "<profile>: <message>", then one summary line per
# contract: "<contract>: ok | absent | not-applicable | delegate:<skill> | invalid".
# Exit 0 when no contract is invalid (absent profiles fall back and are fine),
# 1 when any is invalid, 2 on usage error.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
slots="$here/../../../profiles/slots.tsv"
[ -f "$slots" ] || { printf 'check-profile.sh: manifest not found at %s\n' "$slots" >&2; exit 2; }

root=""; quiet=0; contracts=()
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:?--root needs a directory}"; shift 2 ;;
    --quiet) quiet=1; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    -*) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *) contracts+=("$1"); shift ;;
  esac
done
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "$root" ] || { printf 'no such directory: %s\n' "$root" >&2; exit 2; }
root="$(cd "$root" && pwd -P)"

known="$(awk -F'\t' '!/^#/ && NF>=5 {print $1}' "$slots" | awk '!seen[$0]++')"
[ "${#contracts[@]}" -gt 0 ] || contracts=($known)
for c in "${contracts[@]}"; do
  printf '%s\n' "$known" | grep -qx "$c" || { printf 'unknown contract: %s (known: %s)\n' "$c" "$(printf '%s' "$known" | tr '\n' ' ')" >&2; exit 2; }
done

overall=0
say() { [ "$quiet" -eq 1 ] || printf '%s\n' "$1"; }

section() { awk -v h="## $1" '$0==h{on=1;next} /^## /{on=0} on{print}' "$2"; }
nonblank() { grep -cve '^[[:space:]]*$' || true; }
slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[`*]//g; s/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }

# Column <name> of the first markdown table in the text on stdin, one cell per line.
table_col() {
  awk -F'|' -v want="$(slug "$1")" '
    function slug(x){ x=tolower(x); gsub(/[`*]/,"",x); gsub(/[^a-z0-9]+/,"-",x); gsub(/^-+|-+$/,"",x); return x }
    /^\|/ { if (!hdr) { for (i=1;i<=NF;i++) if (index(slug($i), want)==1) col=i; hdr=1; next }
            if (!sep) { sep=1; next }
            if (col) { c=$col; gsub(/^[ \t]+|[ \t]+$/,"",c); print c } }'
}

# Relative paths in cells/prose: backticked or bare tokens containing a slash or ending in .md/.sh
# Only tokens with a slash count as paths; patterns (<slug>, *, {a,b}) and git refs are skipped.
paths_in() { grep -oE '`[^`]+`|[A-Za-z0-9_./-]+\.(md|sh|exs|ex|ts|js|py|json|yaml|yml)' | sed -E 's/^`|`$//g' | grep -E '^[A-Za-z0-9_.]' | grep -vE '^(https?:|tmp/|_build|deps/|origin/|upstream/|refs/|HEAD)|[<>*{}]' | grep -E '/' || true; }

for c in "${contracts[@]}"; do
  f="$root/.claude/$c.md"
  rel=".claude/$c.md"
  status=ok
  fail() { say "$rel: $1"; status=invalid; }
  warn() { say "$rel: warning: $1"; }

  # Same-name hazard (ADR 0002): a project skill with the contract's name is silently dropped.
  [ -e "$root/.claude/skills/$c" ] && { say "$rel: .claude/skills/$c/ exists and is silently shadowed by the global contract skill; decompose it into this profile or rename it and use 'delegate:'"; status=invalid; }

  if [ ! -f "$f" ]; then
    [ "$status" = invalid ] || status=absent
    # Absent is fine (fallback) unless something else already failed.
    if git -C "$root" rev-parse --show-toplevel >/dev/null 2>&1 && git -C "$root" check-ignore -q "$rel" 2>/dev/null; then
      warn "would be git-ignored; ignore '.claude/*' (not '.claude/') and add '!.claude/*.md' and '!.claude/docs/' before creating it"
    fi
    printf '%s: %s\n' "$c" "$status"; [ "$status" = invalid ] && overall=1; continue
  fi

  if git -C "$root" rev-parse --show-toplevel >/dev/null 2>&1 && git -C "$root" check-ignore -q "$rel" 2>/dev/null; then
    fail "is git-ignored; ignore '.claude/*' (not '.claude/') and add '!.claude/*.md' and '!.claude/docs/' (profiles must be tracked)"
  fi

  first="$(grep -m1 -ve '^[[:space:]]*$' "$f" || true)"
  case "$first" in
    "status: not applicable")
      printf '%s: not-applicable\n' "$c"; continue ;;
    "status:"*)
      fail "unknown status line '$first' (only 'status: not applicable' is defined)" ;;
    "delegate: "*)
      d="${first#delegate: }"
      if [ -f "$root/.claude/skills/$d/SKILL.md" ]; then
        [ "$d" = "$c" ] && fail "delegate: names the contract itself"
        warn "delegates to project skill '$d' (migration escape hatch, not a steady state)"
        printf '%s: delegate:%s\n' "$c" "$d"; continue
      else
        fail "delegate: names '$d' but .claude/skills/$d/SKILL.md does not exist"
      fi ;;
  esac

  ph="$(grep -nE 'TODO:|<fill|<your|<app>|<lib>' "$f" | head -5 || true)"
  if [ -n "$ph" ]; then
    printf '%s\n' "$ph" | while IFS= read -r line; do say "$rel: unresolved placeholder at line ${line%%:*}: $(printf '%s' "${line#*:}" | cut -c1-70)"; done
    status=invalid
  fi

  present="$(grep -E '^## ' "$f" | sed -E 's/^## //')"
  while IFS=$'\t' read -r contract slot req kind desc; do
    [ "$contract" = "$c" ] || continue
    if ! printf '%s\n' "$present" | grep -qx "$slot"; then
      [ "$req" = required ] && fail "missing required slot '## $slot' ($desc)"
      continue
    fi
    body="$(section "$slot" "$f")"
    [ "$(printf '%s\n' "$body" | nonblank)" -ge 1 ] || { fail "slot '## $slot' is empty"; continue; }
    case "$kind" in
      table:*)
        col="${kind#table:}"
        printf '%s\n' "$body" | grep -q '^|' || { fail "slot '## $slot' has no table (expected a column '$col')"; continue; }
        cells="$(printf '%s\n' "$body" | table_col "$col")"
        [ -n "$cells" ] || { fail "slot '## $slot' table lacks a '$col' column"; continue; }
        printf '%s\n' "$cells" | paths_in | sort -u | while IFS= read -r p; do
          [ -e "$root/$p" ] || say "$rel: '## $slot' names $p, which does not exist"
        done
        printf '%s\n' "$cells" | paths_in | sort -u | while IFS= read -r p; do [ -e "$root/$p" ] || exit 9; done || status=invalid
        ;;
      paths)
        printf '%s\n' "$body" | paths_in | sort -u | while IFS= read -r p; do
          [ -e "$root/$p" ] || say "$rel: '## $slot' names $p, which does not exist"
        done
        printf '%s\n' "$body" | paths_in | sort -u | while IFS= read -r p; do [ -e "$root/$p" ] || exit 9; done || status=invalid
        ;;
    esac
  done < <(grep -v '^#' "$slots")

  # Unknown sections are ignored by the contract; say so once.
  known_slots="$(awk -F'\t' -v c="$c" '!/^#/ && $1==c {print $2}' "$slots")"
  printf '%s\n' "$present" | while IFS= read -r s; do
    printf '%s\n' "$known_slots" | grep -qx "$s" || say "$rel: warning: section '## $s' is not a $c slot and will be ignored"
  done

  printf '%s: %s\n' "$c" "$status"
  [ "$status" = invalid ] && overall=1
done
exit $overall
