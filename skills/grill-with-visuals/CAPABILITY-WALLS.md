# Capability walls — recognize, split, hand off, stop

Companion to `SKILL.md`. Read when the session hits something the skill, the
profile, or the app cannot do.

## Disk is the anchor, not the conversation

A skill's `SKILL.md` is rendered into the conversation **once and frozen** when
invoked. Editing the file afterwards does not update what is already in
context, and `claude --resume` / `--continue` replays the old conversation with
the stale body. **You cannot edit a skill and resume your way to the new
version.** The reliable reload is a fresh `claude` process. Bundled files read
with the Read tool (this one, the profile) are re-read from disk each time, so
edits to them show up on the next read; keep volatile mechanics in bundled
files or the profile for that reason.

Because a fresh session starts empty, everything that must survive a pause
lives on disk: the design spec (capture-before-delete) and the two handoffs
below.

## Classify first

- **Design question** — "drawer or modal?", "is a Customer a Subscriber?".
  That is the grilling itself. Keep going: render it, ask, resolve. Not a wall.
- **Capability gap** — the gallery cannot render this widget; a real component
  does not exist; a brand token is missing; the profile lacks a slot the
  contract needs; the skill has no instruction for this case. No amount of
  asking the human resolves it. **This is a wall. Stop.**

Do not hack around a wall: no invented markup, no "good enough" workaround that
defeats faithfulness-by-construction.

## Propose the split, then wait

Before writing anything, surface the wall and propose the split in prose: name
the gap, then one sentence each on what Handoff A and Handoff B would contain.
Wait for the go-ahead. The human may re-scope the grilling around the wall,
fold the gap into an existing work-order, reclassify it as a design question,
or drop it. Only after confirmation write the handoffs.

## Handoff A — resume the grilling

Run `/handoff`: which decision is in flight, what the user was leaning toward,
the settled-so-far state, and **which throwaway gallery modules are still
live** (ids and URLs) so a resumed session can pick them up or sweep them.

## Handoff B — expand the capability

Write a buildable work-order, not a conversation dump, to
`<work-order dir>/<short-slug>.md`, where the directory is the one the
profile's `## Known walls` names. Include:

- **The gap:** what the design needed that could not be done.
- **Where it belongs:** **skill** (contract instructions), **profile** (a
  missing or wrong slot), **app** (a real component, a prototype-able surface,
  a token — normal feature work, promoted through the project's triage flow),
  or a combination.
- **The trigger:** the exact decision being explored when the wall appeared,
  linking Handoff A and the spec.
- **Acceptance:** how the next session will know the capability exists.

## Index it, then stop

Add one line to the triage board named in `## Known walls`:

```
- [ ] <slug> — <one-line gap> · belongs in: skill | profile | app · → <work-order path>
```

Then stop. Do not auto-fix and do not auto-chain. Present both handoffs; the
human sequences them (build the capability in one session, resume the grill in
another, any order). Settled decisions are already safe in the spec, so neither
handoff carries finished work.

## Graduation

When the board's open list is empty and the profile runs end to end without
walls, the profile is stable; mechanics that turned out to be stack-independent
are candidates to move from the profile into this contract.
