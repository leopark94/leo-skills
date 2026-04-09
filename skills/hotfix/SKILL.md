---
name: hotfix
description: "Emergency bug fix — fast-path incident-commander → developer → reviewer pipeline"
disable-model-invocation: false
user-invocable: true
---

# /hotfix — Emergency Bug Fix

Fast-path pipeline for urgent production bugs. Skips heavy architecture phase.
Diagnose → Fix → Verify → Ship.

## Usage

```
/hotfix <bug description>
/hotfix --error "<error message>"
/hotfix --rollback             # revert last deploy
```

## Team Composition & Flow

```
Phase 1: Triage (sequential)
  incident-commander → symptom collection + severity assessment
       |
Phase 2: Diagnosis (sequential)
  debugger → competing hypotheses (top 3)
       |
Phase 3: Fix (sequential)
  developer → minimal targeted fix (worktree isolation)
       |
Phase 4: Verification (parallel)
  +-- reviewer     → code quality check
  +-- test-analyzer → regression risk
       |
Phase 5: Ship
  git-master → commit + cherry-pick if needed
```

## Phase 1: Triage

```
Agent(
  prompt: "Triage this production bug:
    Bug: {bug_description}
    - Collect error logs, stack traces, reproduction steps
    - Assess severity: P0 (service down) / P1 (degraded) / P2 (cosmetic)
    - Identify blast radius (which users/features affected)
    - Recommend: hotfix vs full fix vs rollback
    Project: {project_root}",
  name: "triage",
  subagent_type: "incident-commander"
)
```

P0/P1 → proceed immediately. P2 → suggest `/investigate` instead.

## Phase 2: Diagnosis

```
Agent(
  prompt: "Diagnose root cause based on triage:
    Triage: {triage_output}
    - Form top 3 hypotheses with probability
    - Verify highest-probability first
    - Identify exact file + line to fix
    Project: {project_root}",
  name: "diagnosis",
  subagent_type: "debugger"
)
```

## Phase 3: Fix

```
Agent(
  prompt: "Apply minimal fix for this bug:
    Diagnosis: {diagnosis_output}
    - Change ONLY what's needed to fix the root cause
    - No refactoring, no cleanup, no 'improvements'
    - Verify build passes after fix
    Project: {project_root}",
  name: "hotfix-dev",
  subagent_type: "developer",
  isolation: "worktree"
)
```

## Phase 4: Verification

Spawn 2 agents simultaneously:

```
Agent(name: "verify-quality", subagent_type: "reviewer", run_in_background: true)
  → "Review this hotfix for correctness and regressions: {diff}"

Agent(name: "verify-tests", subagent_type: "test-analyzer", run_in_background: true)
  → "Assess regression risk of this hotfix: {diff}"
```

Critical issues → back to Phase 3 (max 2 rounds).

## Phase 5: Ship

```markdown
## Hotfix Complete

### Severity: {P0/P1/P2}
### Root Cause: {one-line summary}
### Fix: {file:line — what changed}
### Verification: PASS/FAIL
### Ready to commit? → user approval
```

## Rules

- **Minimal fix only** — no scope creep, no cleanup
- P0: skip user approval gates, move fast
- P1: brief approval at Phase 2
- P2: redirect to `/investigate`
- Max 2 fix-verify loops
- Always verify build passes
- If fix is too complex → escalate to `/sprint`
