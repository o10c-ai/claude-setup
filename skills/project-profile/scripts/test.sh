#!/usr/bin/env bash
# Scenario tests for check-profile.sh / init-profile.sh. Exit 1 on any failure.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
setup="$(cd "$here/../../.." && pwd -P)"
chk="$here/check-profile.sh"; ini="$here/init-profile.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
rc=0; pass() { printf 'ok   %s\n' "$1"; }; fail() { printf 'FAIL %s\n' "$1"; rc=1; }
expect() { # expect <name> <exit> <grep-pattern-on-output> -- cmd...
  local name="$1" want="$2" pat="$3"; shift 3; [ "${1:-}" = "--" ] && shift
  local out; out="$("$@" 2>&1)" && got=0 || got=$?
  if [ "$got" = "$want" ] && printf '%s\n' "$out" | grep -qE -- "$pat"; then pass "$name"
  else fail "$name (exit $got, wanted $want; pattern '$pat')"; printf '%s\n' "$out" | sed 's/^/     /'; fi
}

# 1. shipped example: only the intentional <app>/<lib> placeholders are wrong
expect "example: implement ok" 1 '^implement: ok$' -- "$chk" --root "$setup/examples/phoenix"
expect "example: orchestrate ok" 1 '^orchestrate: ok$' -- "$chk" --root "$setup/examples/phoenix"
out="$("$chk" --root "$setup/examples/phoenix" 2>&1 || true)"
if printf '%s\n' "$out" | grep -vE 'placeholder|^[a-z-]+: (ok|invalid)$' | grep -q .; then
  fail "example: findings other than placeholders"; printf '%s\n' "$out" | grep -vE 'placeholder|^[a-z-]+: (ok|invalid)$' | sed 's/^/     /'
else pass "example: no findings besides placeholders"; fi

# 2. empty git project: everything absent, exit 0, gitignore warning when .claude/ ignored
d="$tmp/empty"; mkdir -p "$d"; git -C "$d" init -q; printf '.claude/\n' > "$d/.gitignore"
expect "empty: all absent, exit 0" 0 '^review: absent$' -- "$chk" --root "$d"
expect "empty: gitignore warning" 0 'would be git-ignored' -- "$chk" --root "$d"

# 3. init generic: skeleton, gitignore rewritten, doctor red on TODOs
expect "init generic writes skeleton" 0 'skeleton' -- "$ini" --root "$d" review
expect "init rewrote .claude/ to .claude/*" 0 '^\.claude/\*$' -- grep -E '^\.claude/\*$' "$d/.gitignore"
( cd "$d" && git check-ignore -q .claude/review.md ) && fail "profile still git-ignored after init" || pass "profile tracked after init"
expect "skeleton is invalid on TODO" 1 'unresolved placeholder' -- "$chk" --root "$d" review
expect "init skips existing" 0 'exists, skipped' -- "$ini" --root "$d" review

# 4. init phoenix from example, then a filled profile passes
p="$tmp/phx"; mkdir -p "$p"; git -C "$p" init -q
printf 'defmodule X.MixProject do\n  defp deps, do: [{:phoenix, "~> 1.7"}]\nend\n' > "$p/mix.exs"
expect "init detects phoenix" 0 'stack: phoenix' -- "$ini" --root "$p"
[ -f "$p/.claude/docs/review/seats/server-side-authorization.md" ] && pass "init copied example seat" || fail "init did not copy example seat"
sed -i.bak -E 's/<app>/myapp/g; s/<lib>/mylib/g; /Replace the placeholders/d; /Replace `<app>`/d' "$p"/.claude/*.md && rm -f "$p"/.claude/*.bak
mkdir -p "$p/.claude/docs/grill-with-visuals"
expect "phoenix profiles pass once placeholders resolved" 0 '^review: ok$' -- "$chk" --root "$p"

# 5. structural failures
b="$tmp/broken"; mkdir -p "$b/.claude/skills/review"; printf 'x' > "$b/.claude/skills/review/SKILL.md"
printf '# r\n\n## Guards\n\nprose only\n\n## Seats\n\n| ★ | Seat | Fires | Rubric |\n|---|---|---|---|\n| | A | x | `.claude/docs/review/seats/a.md` |\n\n## Evidence pack\n\ncmd\n\n## Report\n\ntmp/\n\n## Extra\n\nz\n' > "$b/.claude/review.md"
expect "same-name skill flagged" 1 'silently shadowed' -- "$chk" --root "$b" review
expect "guards without table flagged" 1 "has no table" -- "$chk" --root "$b" review
expect "dangling rubric flagged" 1 'seats/a.md, which does not exist' -- "$chk" --root "$b" review
expect "unknown section warned" 1 "section '## Extra' is not a review slot" -- "$chk" --root "$b" review
printf 'status: not applicable\n' > "$b/.claude/grill-with-visuals.md"
expect "not applicable honoured" 0 '^grill-with-visuals: not-applicable$' -- "$chk" --root "$b" grill-with-visuals
printf 'delegate: nope\n' > "$b/.claude/implement.md"
expect "dangling delegate flagged" 1 "delegate: names 'nope'" -- "$chk" --root "$b" implement
expect "unknown contract is usage error" 2 'unknown contract' -- "$chk" --root "$b" bogus

exit $rc
