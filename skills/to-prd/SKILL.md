---
name: to-prd
description: Turn the current conversation context into a PRD and save it as a local spec document. Use when user wants to create a PRD from the current context.
---

This skill takes the current conversation context and codebase understanding and produces a PRD. Do NOT interview the user. Synthesize what you already know; a `grill-with-docs` session normally precedes this.

> OWN override of the vendored mattpocock-skills `to-prd`. Differences: the PRD is a **local document**, not a tracker artifact, and it carries four sections lifted from pstack's Frame and Feature playbooks (definition of done, data shape, verification harness, throughput checkpoint). Those four are what `/to-issues` and `autonomous-run` consume downstream.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use the project's domain glossary vocabulary throughout the PRD, and respect any ADRs in the area you're touching.

2. Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can.

Check with the user that these seams match their expectations.

3. Settle any open question that an experiment can answer before writing. Run the `prototype` skill, keep the branch and SHA, and cite it in the relevant decision. Ask the user only about product or preference calls no run can settle.

4. Write the PRD using the template below to the project's spec directory (`.claude/docs/specs/<feature>-prd.md` if the project has one; otherwise next to the source spec, or `docs/`). If the PRD was derived from an existing spec/ADR file, link to it from the PRD header and note their relationship. Do NOT publish it anywhere.

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Definition of Done

One falsifiable predicate for the whole feature: the command, test name, diff, or measurement that proves it shipped. Not prose. Examples: `mix test test/billing/subscription_correction_test.exs` green plus the corrections page rendering the new column; `pixel-diff 0` against `baseline/`; `curl …` returns the new field. Each slice in `/to-issues` will carry its own sub-predicate that rolls up to this one.

## Data Shape

Name the core data shape and its organizing structure before any slice is cut: a state machine over scattered booleans, a typed model over repeated shape assumptions, a table or registry over branching, a reducer, a boundary. What concurrent actors share, and what is deliberately not shared. A type sketch from a prototype belongs here (see the snippet exception below).

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype, with the branch or SHA. Trim to the decision-rich parts, not a working demo.

Mark each decision that is a one-way door (hard to reverse, high blast radius). Those get a review gate downstream; the rest run autonomously.

## Verification Harness and Baseline

What gets built before feature work so every slice reads as "old value vs new value": the test scaffold, fixture, screenshot baseline, or measurement script, and the pre-change value it captures. Name the verification rule per slice: unit plus live on the real surface by default; a perf gate (metric, probe, trunk baseline, failing number) only when the change touches a hot path.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details; the test must fail if every imported function returned nothing)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Throughput Checkpoint

Four lines, each kept even when it is `n/a: <reason>`:

- **Blocking first steps.** Gates and scaffold that must land before anything fans out.
- **Independent workstreams.** Disjoint files, services, or layers that can run in parallel.
- **Shared mutable state.** What two slices would both write. Default to splitting the target; serialize only for a real invariant.
- **Smallest safe decomposition.** The fewest slices that still each end in a check. If one owner is best, say why.

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
