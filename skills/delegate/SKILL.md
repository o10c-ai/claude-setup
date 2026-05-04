---
name: delegate
description: Three-model orchestration pipeline for multi-file tasks. Opus plans with atomic acceptance criteria, Kimi K2.5 (via OpenCode) executes, Sonnet judges each criterion pass/fail. Use when a task involves >=3 file changes, batch refactoring, or mechanical code generation where speed matters more than deep reasoning. Triggers on "delegate", "fast execute", or when the user wants parallel model execution.
---

# delegate — Opus→Kimi→Sonnet Pipeline

## Pipeline

```
Opus (this session) → Kimi K2.5 (OpenCode) → Sonnet (judge)
   spec + criteria         execute files        pass/fail each criterion
```

## When to Use

**Good fit (delegate):**
- **10+ files** with the same mechanical pattern (add moduledocs, rename a symbol, apply a code mod)
- Batch boilerplate generation (test stubs, PO file entries, config files)
- Tasks where the **spec IS the value** — you want a reviewable contract before execution
- Tasks you want to run in the background while doing other work

**Bad fit (do it yourself):**
- <30 targeted edits across files you already have in context — the spec overhead exceeds the edit time
- Edits requiring **cultural/domain judgment** (e.g., French translations need nuance, not mechanical replacement)
- Files you've been actively editing this session — you already have the mental model, transferring it to a spec is waste
- Security-sensitive code, architecture decisions, complex debugging
- When you can't parallelize — if you're blocked waiting for Kimi with nothing else to do, you lost the concurrency advantage

**The threshold:** If writing the spec takes longer than doing the edits, don't delegate. Rule of thumb: delegate when `file_count × repetitiveness > context familiarity`.

## Workflow

### Phase 1: Spec with Acceptance Criteria (Opus)

Write a **self-contained spec** with **atomic acceptance criteria**. Kimi has NO conversation context. The spec is both Kimi's instructions AND Sonnet's rubric.

#### Spec Structure

```json
{
  "objective": "One sentence describing the goal",
  "context": "What the codebase looks like, relevant patterns",
  "stories": [
    {
      "id": "S-001",
      "title": "Short description of this unit of work",
      "files": ["exact/paths/to/modify.ex"],
      "instructions": "What to do, with a concrete example for one file",
      "acceptanceCriteria": [
        "Criterion 1: observable, binary, verifiable",
        "Criterion 2: observable, binary, verifiable"
      ]
    }
  ],
  "constraints": ["Style rules", "Things to avoid", "Edge cases"],
  "verificationCommand": "mix compile --warnings-as-errors"
}
```

#### Writing Good Acceptance Criteria

Each criterion must be **independently verifiable** by Sonnet reading the diff. Follow the Ralph pattern:

**Good** (observable, binary):
- "Every .ex file in lib/app/contexts/ has a @moduledoc string"
- "No file that already had @moduledoc was modified"
- "`mix compile --warnings-as-errors` passes"
- "Comment blocks use Nix `#` syntax, not `/* */`"

**Bad** (subjective, vague):
- "Code is clean" — not binary
- "Good documentation" — not observable
- "Follows best practices" — not verifiable from diff

#### Sizing Stories

Each story should be completable in one pass. Split if too large:

| Right-sized | Too big (split) |
|-------------|-----------------|
| Add @moduledoc to all context modules | Refactor the entire codebase |
| Add type specs to one module's public functions | Add type specs to all modules |
| Convert 5 YAML configs to TOML | Migrate the entire config system |

### Phase 2: Execute (Kimi via OpenCode)

Flatten the spec into a prompt for Kimi. Include all stories, instructions, and constraints. Omit the acceptance criteria — those are for Sonnet only.

Pick timeout by scope:

| Scope | Stories | Timeout |
|-------|---------|---------|
| Small | 1-2 | `-t 180` |
| Medium | 3-5 | `-t 600` |
| Large | 6+ | `-t 1800` |

```bash
node ~/.claude/skills/invoke-opencode-acp/acp_client.cjs "$PWD" "<flattened instructions>" -o /tmp/delegate-output.txt -t <timeout>
```

Run with `dangerouslyDisableSandbox: true` — OpenCode needs network and filesystem access.

If timeout or error: check `/tmp/delegate-output.txt` for partial progress. Reduce scope or fall back to Opus.

### Phase 3: Judge (Sonnet subagent)

Launch a Sonnet agent as a **criteria judge**, not a code reviewer:

```
Agent(model: "sonnet", subagent_type: "general-purpose", prompt: "<judge prompt>")
```

#### Judge Prompt Template

```
You are judging whether code changes meet acceptance criteria.

## Spec
<paste the full spec JSON from Phase 1>

## Instructions
1. Run: git diff HEAD~1
2. If a verificationCommand is specified, run it
3. For each story, evaluate every acceptance criterion independently
4. Report in this exact format:

### S-001: <title>
- [PASS] Criterion text — evidence
- [FAIL] Criterion text — what's wrong, what was expected

### Summary
- Total: X criteria
- Pass: Y
- Fail: Z
- Verdict: PASS (all pass) | FAIL (any fail)
```

#### Handling Results

| Verdict | Action |
|---------|--------|
| **PASS** | Proceed to Phase 4 |
| **FAIL (1-2 minor)** | Opus fixes directly from Sonnet's report |
| **FAIL (systemic)** | Clarify spec, re-run Phase 2 |
| **FAIL (wrong approach)** | Abort delegation, do on Opus |

### Phase 4: Report

Summarize to the user:
- Stories completed and their verdicts
- Any criteria that failed and how they were resolved
- Manual follow-up needed (if any)

## Example

User: "Add comments to all Nix package files in pkgs/"

**Phase 1 — Spec:**
```json
{
  "objective": "Add descriptive comment blocks to all .nix files in pkgs/",
  "context": "3 Nix derivation files: sidecar.nix (Go build), td.nix (Go build), sentry-cli.nix (prebuilt binary)",
  "stories": [
    {
      "id": "S-001",
      "title": "Add comment blocks to pkgs/*.nix",
      "files": ["pkgs/sidecar.nix", "pkgs/td.nix", "pkgs/sentry-cli.nix"],
      "instructions": "After the input args block and before the builder call, add 3-4 lines of # comments describing: what the package is, build method, source URL. Example for sidecar.nix:\n# Sidecar: Terminal UI companion for CLI coding agents\n# Built via buildGoModule from GitHub source\n# Source: https://github.com/marcus/sidecar (v0.74.1)",
      "acceptanceCriteria": [
        "All 3 files in pkgs/ have a comment block between inputs and builder",
        "Comments use Nix # syntax only",
        "Each comment block mentions: package name, build method, source URL",
        "No other lines in the files were modified",
        "nix-instantiate --parse succeeds for all 3 files"
      ]
    }
  ],
  "constraints": ["Keep comments to 3-4 lines", "Don't modify existing code"],
  "verificationCommand": "for f in pkgs/*.nix; do nix-instantiate --parse $f > /dev/null; done"
}
```

**Phase 2:** Kimi executes via OpenCode (timeout 180s)

**Phase 3 — Sonnet judges:**
```
### S-001: Add comment blocks to pkgs/*.nix
- [PASS] All 3 files have comment block — confirmed in diff
- [PASS] Comments use # syntax — no /* */ found
- [PASS] Each mentions package name, build method, source — verified
- [PASS] No other lines modified — diff shows only additions
- [PASS] nix-instantiate passes — exit code 0 for all 3

### Summary
- Total: 5 criteria | Pass: 5 | Fail: 0
- Verdict: PASS
```

**Phase 4:** "Added comments to 3 files. All 5 criteria passed. Done."

## Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Kimi modifies wrong files | Spec missing explicit file list | Always list exact paths in stories |
| Sonnet flags systemic failures | Task needs reasoning Kimi lacks | Abort, do on Opus |
| Timeout | Too many stories in one pass | Split into batches of 2-3 stories |
| Criteria too vague to judge | Bad criteria design | Rewrite: must be observable from diff or command output |
