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
  if [ -f .claude/review.md ]; then
    catalogue="$(awk '$0=="## Seats"{on=1;next} /^## /{on=0} on && /^\|/{print}' .claude/review.md \
      | awk -F'|' 'NR>2{gsub(/[` ]/,"",$2); if ($2!="") print $2}')"
    for seat in $(printf '%s' "$rev" | sed -E 's/^auto *\+? *//; s/,/ /g'); do
      printf '%s\n' "$catalogue" | grep -qx "$seat" \
        || fail "review: names seat '$seat' not in .claude/review.md '## Seats' table"
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
