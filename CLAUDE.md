# Claude Code Configuration

This is my global Claude Code 2.0 configuration.

## IMPORTANT: Declarative Configuration

**NEVER modify files directly in `~/.claude/`** - they are Nix-managed symlinks.

All Claude Code customizations must go through:
- `~/.config/nix/home-manager/claude-code/` (source files)
- `~/.config/nix/home-manager/claude-code.nix` (symlink definitions)

After changes: `darwin-rebuild switch --flake ~/.config/nix`

See the `claude-config-management` skill for detailed instructions.

## SuperClaude Framework

All SuperClaude components (agents, commands, modes, MCP integration) are provided by the official plugin.

**Installation**: `/plugin install superclaude`

**Documentation**: https://github.com/SuperClaude-Org/SuperClaude_Plugin

## Serena MCP Integration

Serena MCP server runs locally as a launchd service on port 9121.

**Endpoint**: `http://localhost:9121/mcp`

### When to Use Serena vs Native Tools

| Task | Use Serena | Use Native |
|------|------------|------------|
| Symbol-level navigation | `find_symbol`, `find_referencing_symbols` | - |
| Cross-file refactoring | `rename_symbol`, `replace_symbol_body` | - |
| Cross-session memory | `write_memory`, `read_memory` | - |
| Simple file read | - | Read tool |
| Pattern search | - | Grep tool |
| File path matching | - | Glob tool |
| Quick edits | - | Edit tool |

### Memory Workflow

**Session Start:**
```
1. activate_project <path>
2. list_memories → Check for existing context
3. read_memory <relevant> → Load prior insights
```

**Session End:**
```
1. write_memory for significant discoveries
2. Use /sc:save for SuperClaude integration
```

### Key Serena Tools

- `activate_project` - Set project context
- `find_symbol` - Global symbol search
- `find_referencing_symbols` - Find all usages
- `rename_symbol` - LSP-powered rename
- `write_memory` / `read_memory` - Cross-session persistence
- `think_about_task_adherence` - Validate approach

## Command Output Convention

When providing shell commands for the user to run manually in their terminal, **always copy long commands to clipboard** using `pbcopy` instead of displaying them inline. Long commands displayed in chat get split across lines and break when pasted.

- Commands longer than ~80 characters: `echo 'the full command' | pbcopy` then tell the user "Copied to clipboard — paste in your terminal."
- Short commands (< 80 chars): displaying inline is fine.

## Bash Command Shape (permission-friendly)

The global permission allowlist matches commands **per segment** — it cannot
see inside parenthesized or multi-line blocks, so those always prompt even
when every inner command is individually allowed.

- **For read-only inspection** (rg/grep/find/cat/sed -n/…): prefer **separate
  parallel Bash calls**, one command each. A single `&&` chain is fine when
  order matters — but NOT for batched searches: `rg` exits non-zero on no
  match and silently kills the rest of the chain.
- **Do not** wrap independent read-only commands in `( … )` blocks or
  newline-separated scripts just to label output sections — it converts zero
  prompts into one prompt for pure cosmetics.
- **Multi-line blocks are still right** for loops over many files, heredocs,
  and anything needing shared shell state (env vars don't persist between
  Bash calls) — there, one prompt is cheaper than N separate calls.

## cmux (the terminal these sessions run in)

Sessions usually run inside cmux (`CMUX_WORKSPACE_ID` set / `cmux ping` → PONG;
`Bash(cmux:*)` is allowlisted, so cmux calls never prompt).

- **Show, don't paste:** when the user should *see* something rendered — a
  diagram, a diff, a dev page, an image/PDF — open it in a split pane instead of
  dumping text. The `show-in-pane` skill is the ladder (`cmux markdown open`,
  `cmux diff --unstaged|--branch`, `cmux browser open-split`, `cmux open`).
  Interactive local web testing: `cmux-browser` skill.
- **Never steal focus:** pass `--focus false` / `--no-focus` where supported;
  never call `focus-pane` / `select-workspace` / `focus-window` unprompted, and
  anchor creation verbs with `--workspace "$CMUX_WORKSPACE_ID"` — the user may
  be looking at a different workspace.
- **Long autonomous work:** `cmux set-progress <0-1> --label "…"` at milestones
  (+ `cmux clear-progress` when done); `cmux notify --title "…"` on completing
  something the user likely walked away from. Per-session status icons are
  already handled by hooks — don't duplicate those.

## Personal Preferences

- Prefer declarative Nix configurations
- Use home-manager for user-level settings
- Keep secrets in macOS Keychain, not in files
- Version control all configuration in ~/.config/nix
