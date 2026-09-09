---
name: grill-with-visuals
description: Grilling session that renders each consequential design decision as a faithful visual — UI variants in the project's dev gallery (diverge → critique → synthesize one solution in place) or an inline Mermaid diagram for structural decisions — then captures the agreed render fragments as LLM-reproducible text into a durable design spec for the PRD pipeline. Superset of grill-with-docs; reads the project profile at .claude/grill-with-visuals.md and falls back to grill-with-docs when no profile exists or the plan has no consequential visual decision. Use when stress-testing a UI- or structure-heavy plan where decisions must be seen, not just described.
---

# Grill with visuals

A **contract skill**: the phases below are fixed; the stack-specific parts come
from the **project profile** at `.claude/grill-with-visuals.md`. Vocabulary:
`CONTEXT.md` in the claude-setup checkout. Mechanism: ADR 0002 there.

## 0. Resolve the profile, or fall back

Read `.claude/grill-with-visuals.md` in the project root.

- **Missing**, or first non-blank line is `status: not applicable`, or after
  reading the plan you find **no consequential UI or structural decision**:
  say so in one line ("No visual profile / no visual decisions; running
  grill-with-docs.") and invoke the `grill-with-docs` skill. Stop reading this
  file.
- First non-blank line is `delegate: <name>`: invoke that project skill via the
  Skill tool and stop.
- Otherwise the profile must carry these slots; a missing slot is a
  capability wall (see below), not something to invent:

| Slot | What it supplies |
|---|---|
| `## Surfaces` | Which decision shapes count as visual, and which medium each gets |
| `## Render` | How to render one surface in isolation: gallery contract, registry, URL pattern, component catalogue, default/max diverge count |
| `## Capture` | Where agreed fragments, glossary terms, and ADRs land |
| `## Cleanup` | Paths to sweep for throwaway render modules |
| `## Known walls` | Path of the capability triage board and work-order directory |

## 1. Run the grill

Invoke the `grill-with-docs` skill and run its loop unchanged: one question at
a time with a recommended answer, classify before asking, design one-way doors
twice, glossary challenges, inline `CONTEXT.md` and ADR updates. Everything
below is **added on top**; do not restate or weaken that loop.

## 2. Per-decision medium router

Before asking each question, pick the medium by the decision's shape:

| Decision shape | Medium | Weight |
|---|---|---|
| UI / layout / component — "what should this look like?" | project dev gallery, diverge → critique → converge | heavy |
| Structure / state / flow / relationship | inline Mermaid, single-diagram loop | light |
| Terminology, policy, domain relationship | plain grill question | none |

The asymmetry is deliberate: UI gets subagents and a real gallery; Mermaid is
authored inline by you. Do not spin up subagents or gallery modules for a
diagram, and do not describe a layout in prose when the gallery can show it.

**Not every decision earns a render.** Reserve visuals for decisions where
seeing it changes the answer. Trivial or already-obvious calls stay text.

### UI path (heavy)

1. **Diverge.** Spawn N subagents in one message (N from the profile's
   `## Render`, default 3, cap 5). Each writes ONE throwaway module into the
   gallery per the profile's contract, with its own id and URL, composing the
   project's **real components** from its catalogue — invented markup defeats
   faithfulness-by-construction. Each variant must be **structurally distinct**
   (layout, information hierarchy, primary affordance), never a recolour. Each
   subagent returns the live URL and the render fragment as text.
2. **Critique.** Show the URLs (via the `show-in-pane` skill when cmux is
   present; otherwise print them). The human flips between variants. The gold
   feedback is usually a graft ("header from A, table density from C");
   capture it precisely as the synthesis brief.
3. **Converge.** Spawn ONE synthesis subagent that renders a combined solution
   **in place**: same module, same URL across rounds, so live-reload pushes each
   revision to the tab already open. Loop: render → "settled, or another
   round?" → feed critique back → re-render, until the human says settled.
4. **Settle → capture → delete.** See §3. Only after capture, delete the
   synthesis module and the diverge variants and their registry lines.

### Mermaid path (light)

1. Author the ` ```mermaid ` block inline (or show it via `show-in-pane`).
2. Single-diagram revise loop: critique → edit → re-show, until settled.
3. Diverge to two diagrams **only** for genuinely competing structural models
   (event-sourced vs CRUD, state machine vs flag bag). Default is one diagram
   refined in place.
4. On settle, capture per §3. Nothing to delete.

## 3. Capture-before-delete — the linchpin

The instant a visual decision settles:

1. **Lift it to disk first.** Append the agreed fragment (render markup for
   UI, Mermaid block for structure) plus a one-line rationale to the design
   spec named in the profile's `## Capture` (incrementally written, one
   section per decision).
2. **Then** delete the throwaway gallery module (UI path only).

Never delete a module before its fragment is captured. The fragment on disk
is what survives compaction, going AFK, and gallery cleanup.

**Every durable artifact is LLM-reproducible text. No screenshots, ever.**
Render markup, Mermaid, and prose are the only currencies: a downstream agent
reproduces a markup fragment losslessly and reverse-engineers a PNG poorly.
That fidelity gap is the reason this skill exists. Screenshots may be shown to
the human during critique; they are never the artifact.

Where each capture lands (all from `## Capture`): decision fragment +
rationale → the design spec; resolved glossary term → the glossary; hard-to-
reverse architectural call → an ADR, offered only under grill-with-docs' three
conditions.

## 4. Capability walls

When the gallery cannot render what the design needs, a real component is
missing, a profile slot is absent, or this skill has no instruction for the
case, you have hit a **capability wall**, distinct from a design question.
Do not hack around it. Follow `CAPABILITY-WALLS.md` in this skill directory:
propose the split, wait for confirmation, write the two handoffs, index the
work-order at the profile's `## Known walls` path, stop.

## 5. Final cleanup sweep

Before ending: confirm every settled fragment is in the spec, then sweep every
path in `## Cleanup` for straggler modules this session created and delete them
(and their registry lines). Leave the gallery clean.

## 6. Handoff out — never auto-chain

End by naming the design spec path and telling the user the next step is
theirs: `/to-prd` (promotes the spec to a PRD), then `/to-issues`. This skill
does not invoke `/to-prd` and does not assemble the spec itself.

## Escape hatches

- "Compare N options and pick a winner", no durable spec wanted → `/prototype`.
- An interactive state machine you want to play with → `/prototype`, logic branch.
- A plan with no consequential visual decision → you are in the wrong skill;
  §0 already routed you to `grill-with-docs`.
