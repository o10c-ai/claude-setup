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

## Personal Preferences

- Prefer declarative Nix configurations
- Use home-manager for user-level settings
- Keep secrets in macOS Keychain, not in files
- Version control all configuration in ~/.config/nix
