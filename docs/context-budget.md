# Context budget

The setup keeps the per-session baseline small so that project context, not
tooling, fills the window. The posture is default-deny, re-enable selectively.

## Zero base

No plugins, no resident MCP servers, no bundled skills. Everything that loads
in a session is one explicit line in the consuming config (one symlink per
skill). A skill that is not symlinked costs nothing. Comment a line out to
shed its cost.

## Settings levers (`settings.example.json`)

| Lever | Effect |
|---|---|
| `env.ENABLE_CLAUDEAI_MCP_SERVERS=false` | No claude.ai account connectors in the CLI (Gmail, Calendar, Drive, Linear, …). Saves tens of thousands of baseline tokens per session; connectors keep working in the web and desktop apps. Machine-wide, all or nothing. |
| `disableClaudeAiConnectors` | Settings-native duplicate of the env var; both kept. |
| `disableBundledSkills`, `disableWorkflows`, `disableArtifact` | No bundled skill descriptions, workflows, or artifact tooling in the prompt. |
| `permissions.deny` (13 tools) | Denied tools are stripped from the schema: plan mode, `AskUserQuestion`, scheduling, cron, remote triggers, notebook edits, design sync, findings UI. |
| `permissions.allow` | A read-only search set, verb-scoped workflow reads, and safe prefixes, so Bash-based search runs without prompts (ADR 0001). |
| `outputStyle` | `ConciseEng`, reinforced per turn by the `concise-nudge.sh` hook. |

Knowingly lost with the deny list: `/schedule`, `/loop`, the `/code-review`
findings UI, plan mode, structured questions. Re-enable a tool by removing it
from `deny`; bundled skills can only be re-enabled together (`disableBundledSkills:
false`) and then trimmed with `skillOverrides`.

## MCP servers: per project, on demand

None load by default. Add one where it is needed with project-local scope
(`claude mcp add <name> -s local`). Tool search (on by default) defers MCP tool
schemas so only names load upfront. Other knobs: `alwaysLoad`,
`enabledMcpjsonServers` / `disabledMcpjsonServers`, `MAX_MCP_OUTPUT_TOKENS`.

## Shell output

Two `PreToolUse` hooks on Bash: `rtk-rewrite.sh` rewrites eligible commands
(`git`, `cargo`, `ls`, test runners, …) to their compact `rtk` form, and
`redact-bash-pre.sh` wraps credential-shaped commands so secrets never reach
the model. Both fail open when their binaries are missing.

## Skills from upstream libraries

Upstream libraries live under `vendor/` as submodules; only the skills listed
in the consuming config are symlinked. Following a large library costs nothing
until a skill from it is exposed.

## Profiles cost nothing until invoked

The contract skills (`/implement`, `/review`, `/grill-with-visuals`) are three
listing lines. Their project profiles at `.claude/<skill>.md` are not skills:
no listing line, no baseline cost, read only when the contract is invoked.
This is the reason profiles were chosen over per-project skills (ADR 0002).
