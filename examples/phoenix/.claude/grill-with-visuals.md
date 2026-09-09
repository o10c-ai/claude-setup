# grill-with-visuals — project profile (Phoenix / LiveView)

Read by the `grill-with-visuals` contract skill. Replace `<app>` with the OTP
app name. Delete this file, or make the first line `status: not applicable`,
to route every grill to `grill-with-docs`.

## Surfaces

| Decision shape | Medium |
|---|---|
| LiveView page, HEEx component, layout, information hierarchy, primary affordance | dev gallery (heavy path) |
| State machine, workflow, data flow, module relationship, event sequence | inline Mermaid (light path) |
| Naming, policy, domain relationship | plain grill question |

## Render

- **Gallery route:** `/dev/prototype` (dev env only, guarded in `router.ex`).
  Each prototype is one module under `lib/<app>_web/dev/prototypes/`
  implementing the `<App>Web.Dev.Prototype` behaviour: `meta/0` (id, title,
  one-line intent), optional `mount/1` and `handle_event/3` for interactive
  variants, and `render/1` returning HEEx.
- **Registry:** `lib/<app>_web/dev/prototype_registry.ex`, one line per module.
  "Drop a module + add one registry line" is the whole recipe; the gallery
  index lists everything registered.
- **URL pattern:** `http://localhost:4000/dev/prototype/<id>`. Variant ids:
  `gwv-<feature>-a`, `-b`, `-c`; synthesis id: `gwv-<feature>-synthesis`.
- **Faithfulness:** compose only real components from the project's component
  catalogue (`.claude/docs/reference/ui-component-catalog.md` or the core
  components module) with the project's design tokens. Real seeded data over
  lorem ipsum. Never invent markup the app does not ship.
- **Diverge count:** 3 subagents by default, cap 5. Each subagent's brief
  includes: the behaviour contract above, the registry step, the catalogue
  path, the one decision under exploration, the instruction to be
  structurally distinct from siblings, and its unique id.
- **Converge:** the synthesis module is revised in place; Phoenix live-reload
  pushes each revision to the open tab. Keep the dev server running
  (`mix phx.server`, or the project's equivalent) for the whole session.

## Capture

- Decision fragment + one-line rationale → `.claude/docs/specs/<feature>.md`,
  one `##` section per settled decision, HEEx or Mermaid plus prose only.
- Resolved glossary term → `CONTEXT.md` (glossary only, no implementation).
- Hard-to-reverse architectural call → `docs/adr/NNNN-slug.md`, next number.

## Cleanup

- `lib/<app>_web/dev/prototypes/gwv-*` modules created this session.
- Their lines in `lib/<app>_web/dev/prototype_registry.ex`.
- Confirm with `git status` that nothing under `dev/prototypes/` is left
  modified or untracked.

## Known walls

- Triage board: `.claude/docs/grill-with-visuals/KNOWN-ISSUES.md`.
- Work-orders: `.claude/docs/grill-with-visuals/capability-handoffs/<slug>.md`.
