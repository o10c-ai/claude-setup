---
name: show-in-pane
description: Show a rendered visual to the user in a live cmux split pane — a Markdown/Mermaid file, an SVG/HTML file, or a URL — degrading gracefully when cmux is absent. Use whenever the user should SEE a rendered artifact (a Mermaid diagram, a chart, a dev/prototype page, an HTML mockup) instead of reading raw markup or being asked to imagine a layout. This is the reusable display ladder behind grill-with-visuals' render paths. Complements the cmux-browser skill, which drives interactive browser automation (snapshot/click/fill); this one only opens and shows.
---

# Show a visual in a pane

Put a **real rendered pane** in front of the user rather than dumping raw markup or asking them to picture it. On cmux (the terminal this project runs in) that's a native split pane with live reload; off cmux, fall back down a ladder to the best available viewer.

## Detect cmux first

```bash
# Either signal confirms cmux:
echo "$GHOSTTY_RESOURCES_DIR" | grep -q cmux    # resources dir contains "cmux"
cmux ping                                        # → PONG  (Unix-socket, no auth prompt)
```

If `cmux` is not on `PATH`, its CLI lives at:

```
/Applications/cmux.app/Contents/Resources/bin/cmux
```

If neither signal fires, you're not in cmux → use the **Fallback ladder** below.

## Show it — by input type (cmux present)

| You have… | Command | Notes |
|---|---|---|
| a Markdown file (incl. ` ```mermaid ` blocks) | `cmux markdown open <file>` | **Native Mermaid.js render + live reload.** Edit the file → the pane updates, no re-invoke. Bundles mermaid / vega / marked / highlight. |
| a URL (dev server, prototype page) | `cmux browser open-split <url>` | Opens a WebKit browser pane beside the terminal. |
| an SVG / HTML file | `cmux browser open-split <file-url>` or `cmux new-pane --type browser --direction right --url <url>` | Wrap a path as a `file://` URL. |

**Mermaid / structural diagrams:** write the ` ```mermaid ` block into a scratch `.md`, `cmux markdown open` it, then **edit the file to revise** — the pane live-reloads. The file you looked at *is* the durable text (no screenshots).

## Fallback ladder (headless / non-cmux)

1. **Markdown / Mermaid** → `mmdflux --format text <file>` inline. ⚠ Tall output is **truncated** by the tool-output pane — this is degraded, not primary. If Unicode boxes munge, use `mmdflux --format ascii <file>`. (SVG: `mmdflux -f svg --svg-theme-auto <file>`.) `mmdflux` is a single Rust binary; it must be on `PATH` and de-quarantined (`xattr -c`) on macOS.
2. **URL / HTML / SVG file** → `open <url-or-file>` (macOS) to hand it to the user's default browser.
3. **Nothing available** → say so plainly and give the user the exact path/URL to open themselves. Never fabricate a screenshot or ask them to imagine the render.

## Cleanup

Panes and scratch files are throwaway. Close a browser surface when done (`cmux close-surface --surface surface:N`; list with `cmux list-pane-surfaces`) and delete scratch render files once their content is captured wherever it belongs.

## Related

- **cmux-browser** skill — full interactive browser CLI (snapshot, click, fill, wait, eval). Use it when you need to *drive* a page; use *this* skill when you only need to *display* one.
- **grill-with-visuals** (project skill) — both its render paths (Mermaid diagrams, UI variant pages) call this ladder.
- cmux verbs reference: `cmux docs api|browser`, `cmux capabilities`.
