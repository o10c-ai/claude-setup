---
name: cmux-browser
description: Drive cmux's built-in WebKit browser panes — snapshot refs, DOM actions (click/fill/type), waits, screenshots, console/errors, cookies/storage, session state. Use when testing or debugging a LOCAL web app (dev server, prototype page, HTML artifact) from inside cmux; the pane stays visible beside the terminal. Complements show-in-pane (display-only) — use this skill when you need to interact with or inspect the page. For real-Chrome automation (logged-in sites, extensions), use claude-in-chrome instead.
---

# cmux Browser Automation

cmux browser surfaces are WKWebView panes inside the workspace, driven by a
Playwright-like CLI (`cmux browser …`, globally allowed, never prompts). The
user sees everything you do, live, in a split beside the terminal.

## Prerequisites

You must be inside cmux — `CMUX_WORKSPACE_ID` is set, or `cmux ping` → PONG.
If not on `PATH`: `/Applications/cmux.app/Contents/Resources/bin/cmux`.
Not in cmux → fall back to the claude-in-chrome MCP (real Chrome) or ask the
user to test manually.

## Etiquette (applies to every command here)

- Anchor to the **caller workspace**: pass `--workspace "$CMUX_WORKSPACE_ID"`
  when creating surfaces. The visually focused workspace may be a different one.
- **Never steal focus**: pass `--focus false` on creation verbs; never call
  `focus-pane` / `select-workspace` / `focus-window` unless the user asks.
- Reuse one browser surface per task; don't open a new split per navigation.

## Core loop

```bash
# 1. Open in the caller workspace; capture the returned surface ref (e.g. surface:7)
cmux --json browser open http://localhost:3000 --workspace "$CMUX_WORKSPACE_ID"

# 2. Wait, then snapshot (returns element refs like e10, e14)
cmux browser surface:7 wait --load-state complete --timeout-ms 15000
cmux browser surface:7 snapshot --interactive --compact

# 3. Act using refs or CSS selectors; re-snapshot after mutations
cmux browser surface:7 fill '#email' 'test@example.com'
cmux browser surface:7 click 'button[type=submit]' --snapshot-after

# 4. Verify
cmux browser surface:7 wait --text 'Dashboard' --timeout-ms 15000
cmux browser surface:7 get url
```

Snapshot refs are **temporary** — re-snapshot after navigation, modal or DOM
changes. Use `--snapshot-after` on mutating actions to fold steps together.

## Command quick map

| Need | Commands |
|---|---|
| Navigate | `goto <url>`, `back`, `forward`, `reload` |
| Wait | `wait --selector / --text / --url-contains / --load-state / --function` |
| Act | `click`, `dblclick`, `hover`, `type`, `fill`, `press`, `select`, `check`, `scroll` |
| Read | `get url\|title\|text\|html\|value\|attr\|count`, `is visible\|enabled\|checked` |
| Locate | `find role\|text\|label\|placeholder\|testid …`, `highlight <sel>` |
| Debug | `console list`, `errors list`, `screenshot --out <path>`, `eval <js>` |
| State | `cookies get/set/clear`, `storage local/session …`, `state save/load <path>` |
| Tabs/frames/dialogs | `tab new/list/switch/close`, `frame <sel\|main>`, `dialog accept/dismiss` |

Prefer `get` / `is` / `find` for scripted checks; screenshots and snapshots are
for human review. Save screenshots to the session scratchpad (or a path the
user names), not `/tmp` dumps they'll never find.

Full catalog with exact flags (vendored, on disk — no fetch needed):
`~/.config/nix/services/cmux-skills/skills/cmux-browser/SKILL.md` and
`…/references/commands.md`. Live syntax: `cmux --help`.

## Debug capture pattern

```bash
cmux browser surface:7 console list
cmux browser surface:7 errors list
cmux browser surface:7 screenshot --out <scratchpad>/failure.png
```

## Cleanup

```bash
cmux close-surface --surface surface:7   # list with: cmux list-pane-surfaces
```

Close surfaces you opened once the task is done, unless the user is still
looking at the result.
