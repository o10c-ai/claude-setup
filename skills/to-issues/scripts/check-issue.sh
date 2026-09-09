#!/usr/bin/env bash
# Lint a to-issues slice body. Prints one line per defect; exit 1 if any.
# Usage: check-issue.sh <body.md>
set -euo pipefail

[ "$#" -eq 1 ] || { printf 'usage: check-issue.sh <body.md>\n' >&2; exit 2; }
f="$1"
[ -f "$f" ] || { printf '%s: no such file\n' "$f" >&2; exit 2; }

rc=0
fail() { printf '%s: %s\n' "$f" "$1"; rc=1; }

section() { awk -v h="## $1" '
  $0==h {on=1; next}
  /^## / {on=0}
  on {print}
' "$f"; }

nonblank() { grep -cve '^[[:space:]]*$' || true; }

for h in "What to build" "Predicate" "You see" "Verify" "Review gate" "Depends on"; do
  grep -qx "## $h" "$f" || fail "missing section '## $h'"
done

pred="$(section Predicate)"
n="$(printf '%s\n' "$pred" | nonblank)"
[ "$n" -ge 1 ] || fail "Predicate is empty"
[ "$n" -le 3 ] || fail "Predicate has $n lines; one runnable check per issue"
printf '%s\n' "$pred" | grep -qiE 'should|ensure|properly|correctly|works as expected' \
  && fail "Predicate reads as prose; name the command, test, diff, or measurement"

[ "$(section 'You see' | nonblank)" -ge 1 ] || fail "'You see' is empty"

ver="$(section Verify)"
printf '%s\n' "$ver" | grep -qE '^- *unit:' || fail "Verify lacks a 'unit:' line"
printf '%s\n' "$ver" | grep -qE '^- *live:' || fail "Verify lacks a 'live:' line"
printf '%s\n' "$ver" | grep -qE '^- *perf:' || fail "Verify lacks a 'perf:' line (use \"n/a: <reason>\")"

# review: line — ADR 0003. "auto" = seats whose triggers fire on the diff; named
# seats are mandatory whatever the diff shows.
rev="$(printf '%s\n' "$ver" | grep -E '^- *review:' | head -1 | sed -E 's/^- *review: *//' || true)"
if [ -z "$rev" ]; then
  fail "Verify lacks a 'review:' line (write \"review: auto\" or \"review: auto + <seat>, <seat>\")"
else
  printf '%s' "$rev" | grep -qE '^auto( *\+ *[a-z0-9-]+( *, *[a-z0-9-]+)*)? *$' \
    || fail "review: must be 'auto' or 'auto + <seat>, <seat>' (kebab-case seat names; got: '$rev')"
  # Seat catalogue: the project's .claude/review.md (repo root, not cwd). The
  # `Seat` column is found by header name and slugified (lowercase, non-alnum
  # runs -> '-'), so Title-Case names and a leading star column both work.
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  profile="$root/.claude/review.md"
  if [ -f "$profile" ]; then
    catalogue="$(awk '$0=="## Seats"{on=1;next} /^## /{on=0} on && /^\|/{print}' "$profile" \
      | awk -F'|' '
          function slug(x){ x=tolower(x); gsub(/[`*]/,"",x); gsub(/[^a-z0-9]+/,"-",x); gsub(/^-+|-+$/,"",x); return x }
          NR==1 { for (i=1;i<=NF;i++) if (slug($i)=="seat") col=i; next }
          NR==2 { next }
          col && $col !~ /^[ -]*$/ { print slug($col) }')"
    for seat in $(printf '%s' "$rev" | sed -E 's/^auto *\+? *//; s/,/ /g'); do
      printf '%s\n' "$catalogue" | grep -qx "$seat" \
        || fail "review: names seat '$seat' not in $profile '## Seats' table (known: $(printf '%s' "$catalogue" | tr '\n' ' '))"
    done
  fi
fi

gate="$(section 'Review gate' | grep -ve '^[[:space:]]*$' | head -1 || true)"
printf '%s' "$gate" | grep -qE '^(none|interaction)' \
  || fail "Review gate must start with 'none' or 'interaction' (got: '${gate:-<empty>}')"

[ "$(section 'Depends on' | nonblank)" -ge 1 ] || fail "'Depends on' is empty (write \"None — can start immediately\")"

# Stale-path smell in the behaviour section.
section 'What to build' | grep -qE '(^|[[:space:]])(lib|src|test|app)/[A-Za-z0-9_./-]+\.[a-z]+' \
  && fail "'What to build' names a file path; describe behaviour, not files"

exit $rc
