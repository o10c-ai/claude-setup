# Global Claude Code configuration

## Declarative config — never edit `~/.claude/` directly

Files there are Nix-managed symlinks. Edit the sources instead:
- `~/.config/nix/home-manager/claude-code/` — CLAUDE.md, settings.json, output-styles, agents, hooks
- `~/.config/nix/home-manager/claude-code.nix` — symlink definitions

Apply with `darwin-rebuild switch --flake ~/.config/nix`. Secrets live in macOS Keychain, never in files.

## Shell commands

- Commands for the user to run: if longer than ~80 chars, `echo '<cmd>' | pbcopy` and say "Copied to clipboard"; otherwise inline.
- Read-only inspection: one command per Bash call, run in parallel. No `( … )` blocks or `&&` chains just to group output (`rg` exits non-zero on no match and kills the chain). Multi-line blocks only when shared shell state is needed.
- Prefer shell (`sed -n`, `rg`, `ls`) over the Read/Grep/Glob tools for compact output; a PreToolUse hook rewrites eligible Bash commands through `rtk`.

## cmux (the terminal these sessions run in)

- Show, don't paste: diagrams, diffs, dev pages, images/PDFs go to a split pane via the `show-in-pane` skill. Interactive local web testing: `cmux-browser` skill.
- Never steal focus: `--focus false` / `--no-focus` where supported; never `focus-pane` / `select-workspace` / `focus-window` unprompted; anchor creation verbs with `--workspace "$CMUX_WORKSPACE_ID"`.
- Long autonomous work: `cmux set-progress <0-1> --label "…"` at milestones, `cmux clear-progress` when done, `cmux notify` on completing something the user likely walked away from.

## Autonomy

- Reversible work proceeds without asking. Confirmation is reserved for irreversible actions: force-push to shared branches, deploys, data deletion, messages to external parties. "Going to bed", "run until done", "keep going", "be fully autonomous" suppress every pause except those.
- A "which approach" fork is classified before it is raised. If running something would answer it (behaviour, timing, output, layout), run it and let the result decide. Ask only for product or preference calls no experiment can settle.
- Long, unattended, or multi-phase work keeps a decision trail via the `show-me-your-work` skill and runs under the `autonomous-run` skill. The trail is committed at `.audit/<slug>.tsv`.
- Declining is a valid answer. Say when scope does not earn its place instead of agreeing by default.
