# Widen the Bash allowlist instead of restoring Grep/Glob

> Originally written in the operator's nix repo; the allowlist now ships as `settings.example.json`.

Claude Code ≥2.1.x removes the Grep/Glob tools from the schema whenever Bash
is enabled (compiled-in, default-on; verified against 2.1.202) and runs all
file search through Bash instead — which made every search prompt for
permission. Restoration exists (`claude --allowedTools "Grep,Glob"`) but is
CLI-flag-only: it can't be set declaratively via settings.json, and a wrapper
alias breaks subcommands (`claude mcp list --allowedTools …` → unknown
option). We chose to accept Bash-search and adapt the permission layer: a
global, Nix-managed `permissions.allow` list in
your `settings.json` (shipped here as `settings.example.json`), scoped to the **search set**,
verb-scoped **workflow reads**, and **safe prefixes** (see CONTEXT.md), plus
`echo`/`cd`. Network tools (`curl`, `gh api`) and bare write-capable tools
(`sed`, `awk`, `python3`) are deliberately excluded globally — a read-shaped
prefix on those can still write or exfiltrate.

## The echo guard

`Bash(echo:*)` alone would let `echo $GH_TOKEN` run unprompted and put the
secret into model context. Instead of dropping echo (88% of its uses are
plain status output), `redact-bash-pre.sh` classifies **expansion-bearing
echo/printf** (`$NAME`, `${…}`, `$(…)`, backtick) as risky and wraps it. The
wrapped command no longer starts with `echo`, so the allow rule deliberately
fails to match — the same matcher-breaking behavior that was a bug for the
old universal wrapper is the enforcement mechanism here: expansion-bearing
echo still prompts AND its output is redacted, strictly better than the
pre-decision state (prompt, no redaction). Do not "fix" the hook to preserve
the allowlist match for these commands.

## Consequences

- Pipelines and compound commands prompt only when a segment falls outside
  the allowed set; bare rtk-eligible commands were already prompt-free via
  the rtk hook's self-allow.
- `Bash(git branch:*)` was considered and rejected: the same prefix matches
  `git branch -D`.
- The user-level `~/.claude/settings.local.json` was absorbed into the managed
  file and emptied; it remains the writable landing zone for future "always
  allow" clicks and should be harvested into the managed file periodically.
