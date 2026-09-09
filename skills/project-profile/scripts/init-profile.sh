#!/usr/bin/env bash
# Scaffold project profiles for the contract skills (ADR 0006).
#
# Usage: init-profile.sh [--root DIR] [--stack phoenix|generic] [--force] [contract ...]
#   contract   implement | review | grill-with-visuals | orchestrate (default: all four)
#   --stack    which example to start from; auto-detected when omitted
#   --force    overwrite an existing profile (default: skip it)
# Writes .claude/<contract>.md. From a matching example under examples/<stack>/ when
# one exists, else a skeleton generated from profiles/slots.tsv. Every slot that needs
# project knowledge carries a 'TODO:' marker; check-profile.sh fails until they are gone.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
setup="$(cd "$here/../../.." && pwd -P)"
slots="$setup/profiles/slots.tsv"

root=""; stack=""; force=0; contracts=()
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root="${2:?}"; shift 2 ;;
    --stack) stack="${2:?}"; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    -*) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *) contracts+=("$1"); shift ;;
  esac
done
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
root="$(cd "$root" && pwd -P)"
[ "${#contracts[@]}" -gt 0 ] || contracts=(implement review grill-with-visuals orchestrate)

detect() {
  if [ -f "$root/mix.exs" ] && grep -qE ':phoenix\b' "$root/mix.exs" 2>/dev/null; then echo phoenix
  else echo generic; fi
}
[ -n "$stack" ] || stack="$(detect)"
printf 'stack: %s (root: %s)\n' "$stack" "$root"

mkdir -p "$root/.claude"
if git -C "$root" rev-parse --show-toplevel >/dev/null 2>&1 && git -C "$root" check-ignore -q .claude/implement.md 2>/dev/null; then
  # git cannot re-include a file under an excluded directory: '.claude/' must become '.claude/*'.
  [ -f "$root/.gitignore" ] && sed -i.bak -E 's#^(\.claude)/[[:space:]]*$#\1/*#' "$root/.gitignore" && rm -f "$root/.gitignore.bak"
  printf '\n# claude-setup profiles and seat rubrics must be tracked (docs/profiles.md)\n!.claude/*.md\n!.claude/docs/\n' >> "$root/.gitignore"
  printf '.gitignore: rewrote .claude/ -> .claude/* and added !.claude/*.md, !.claude/docs/\n'
fi

for c in "${contracts[@]}"; do
  out="$root/.claude/$c.md"
  if [ -f "$out" ] && [ "$force" -eq 0 ]; then printf '%s: exists, skipped (use --force)\n' ".claude/$c.md"; continue; fi
  ex="$setup/examples/$stack/.claude/$c.md"
  if [ -f "$ex" ]; then
    cp "$ex" "$out"
    # Docs the example's profiles point at (seat rubrics, known-walls board): copy
    # what is missing so every path in the copied profile resolves. Never overwrites.
    if [ -d "$setup/examples/$stack/.claude/docs" ]; then
      ( cd "$setup/examples/$stack/.claude/docs" && find . -type f ) | while IFS= read -r rel; do
        dst="$root/.claude/docs/${rel#./}"
        [ -e "$dst" ] || { mkdir -p "$(dirname "$dst")"; cp "$setup/examples/$stack/.claude/docs/${rel#./}" "$dst"; }
      done
    fi
    printf '%s: from examples/%s (edit; TODO markers must go)\n' ".claude/$c.md" "$stack"
  else
    {
      printf '# `/%s` profile — %s\n\n' "$c" "$(basename "$root")"
      printf 'Project profile for the `%s` contract skill (claude-setup). The contract fixes the\nphases; this file supplies the project specifics. Format: docs/profiles.md; interface:\nprofiles/slots.tsv. Remove every TODO line (`check-profile.sh` fails while any remains).\n' "$c"
      awk -F'\t' -v c="$c" '!/^#/ && $1==c {
        printf "\n## %s\n\n", $2
        if ($4 ~ /^table:/) { col=substr($4,7); printf "| Concern | %s |\n|---|---|\n| TODO: %s | TODO |\n", col, $5 }
        else printf "TODO: %s%s\n", $5, ($3=="optional" ? " (optional slot: delete this section if not needed)" : "")
      }' "$slots"
    } > "$out"
    printf '%s: skeleton (fill the TODO lines)\n' ".claude/$c.md"
  fi
done
printf '\nnext: %s\n' "$here/check-profile.sh --root $root"
