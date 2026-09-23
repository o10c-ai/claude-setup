---
name: decision-brief
description: Present a choice to the user as a one-screen decision brief — the question, a concrete example, one-line abstraction, stakes and urgency, 2-4 options each with a contrasting example and +/- bullets, then a recommendation with its reason, failure signal, and approvable action. Use whenever you are about to ask the user to pick between approaches, confirm a tradeoff, or unblock a fork you cannot settle by running something. Also on "/decision-brief", "give me the options", "what should I pick".
---

# Decision brief

The user's time is the scarcest resource in the session. Brief them the way a
chief of staff briefs a head of state: one read, a correct decision, no follow-up
question needed to understand the situation. The brief is completed staff work:
all that remains for the user is to approve or reject.

## Before writing

- If running something (a command, a test, a prototype) would settle the fork,
  run it instead of asking. A brief is only for calls no experiment can settle.
- Screen every candidate option. Keep it only if it is:
  - feasible: it can be done with the time and resources at hand
  - distinguishable: it differs from the other options in outcome, not wording
  - genuine: a reasonable person would pick it. If you cannot write a real `+`
    for it, it is a straw man. Cut it.
- Check whether a combination ("A now, B later") or a cheap trial beats
  picking one option outright.
- Work out what doing nothing costs. Deferring is often a valid option.

## Shape (fixed order, no other sections)

```
**Decision:** <the question, one line> — <reversible | one-way door>, <time to decide>

**Example.** <a concrete case from this codebase/session: a real file, command,
input, or user-visible behaviour — what happens today and why it hurts>

**Problem.** <one sentence, the general form of the example>

**Stakes.** <what goes wrong if we pick badly, with numbers: likelihood, cost, blast radius>
**Urgency.** <now | by <event/date> | deferrable> — <what waiting costs, and what would force the decision>

**A — <short name>.** <the leading example replayed under this option>
+ <pro>
− <con>

**B — <short name>.** <same example, replayed>
+ …
− …

**Recommendation: <letter>.** <one sentence: the deciding reason>
**Watch:** <the most likely way the recommendation fails, and the early signal>
**Next:** <the exact action taken on approval: "Reply B and I edit X, run Y">
```

## Rules

- Every option's example replays the leading example, so the difference is
  visible side by side. Same input, different outcome.
- 2-4 options. 1-3 `+` and 1-3 `−` bullets each, one line per bullet, concrete
  (numbers, files, commands), no bullet that restates another option's con.
- Put numbers on uncertainty: "~70% this recurs", not "likely" or "may".
- A reversible decision gets a light brief and a fast pick; say so in the
  Decision line. Full care goes to one-way doors.
- Urgency states whether this must be settled now. If it can wait, name the
  cost of waiting per day/session and the trigger that would force the decision.
  When deferring is viable, list it as an option.
- Recommendation always present. If it depends on a preference only the user
  holds, say which preference flips it: "A, unless X matters more than Y."
- No preamble, no restating the request, no closing question. The brief ends at
  Next; the user's reply is the decision.
- Whole brief fits one screen (~30 lines). If it does not, cut options or merge
  bullets; do not add headers.
- Use a table only when options differ on the same 3+ axes; otherwise the shape above.

## Example

**Decision:** how to stop parallel test runs slowing each other down — reversible, 1 min

**Example.** `mix test` in worktree `feat-a` takes 94 s while `feat-b` compiles
in parallel; alone it takes 31 s. Both stacks share the Colima VM (10 CPU).

**Problem.** Parallel agent sessions contend for one fixed-size container VM.

**Stakes.** Every agent's feedback loop is ~3x slower during overlap (~40% of
session time today). Resizing the VM restarts all containers (~1 min downtime).
**Urgency.** Deferrable — costs ~10 min of agent wait per parallel session;
becomes urgent if a third parallel session becomes routine.

**A — Raise the VM to 14 CPU.** `feat-a` test run: ~60 s under contention.
+ One-line change in `colima.nix`
− Host keeps 2 cores; the IDE and browser stutter under full load
− Contention returns at 3 parallel sessions

**B — Cap each stack at 4 CPU via compose.** `feat-a` test run: ~45 s, steady.
+ Predictable per-session latency, scales to 2 sessions cleanly
− A lone session also runs at 4 CPU (31 s → ~40 s)

**C — Defer.** `feat-a` keeps taking 94 s during overlap.
+ Zero change, no container restarts
− ~10 min lost per parallel session until fixed

**Recommendation: B.** Steady latency matters more than peak speed when 2+
agents run at once, which is the normal case.
**Watch:** lone-session tests creeping past 45 s — the cap is then too tight.
**Next:** reply B and I add `cpus: 4` to both compose services and rerun `mix test`.
