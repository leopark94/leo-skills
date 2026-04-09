---
name: sprint
description: "Full Anthropic harness: PM→Architect→Contract→test-writer→developer→Evaluator (Playwright live) with score-based iteration loop"
disable-model-invocation: false
user-invocable: true
---

# /sprint — Full Anthropic Harness Implementation

Complete implementation of the Anthropic "Harness Design for Long-Running Apps" pattern.
PM orchestrates, Architect designs, Contract negotiated, test-writer writes Red tests,
developer writes Green code, Evaluator tests live app with Playwright.

## Usage

```
/sprint <feature description>
/sprint --light "simple task"
/sprint --full "complex auth system"
```

## Issue Tracking

Before any work, create a GitHub issue:
```bash
gh issue create --title "sprint: {feature}" --body "Sprint tracking issue" --label "sprint"
```
All agents comment progress to this issue. Close on completion.

## Step 0: Mode Selection

**Default is STANDARD.** Solo requires explicit `--light`.

```
STANDARD [default]:
  PM → Architect → Contract → test-writer → developer
  → Evaluator (live) → [verification team parallel] → Simplifier

FULL (auto-escalation or --full):
  PM → Architect + Explorer → Contract (27+ criteria)
  → test-writer → developer → Evaluator (live + Playwright)
  → [5 verification agents] → Security Auditor → Simplifier
  → per-sprint mid-checks

LIGHT (--light only):
  Planner → Generator → Evaluator (original Anthropic harness, no teams)
```

Auto-escalation STANDARD → FULL:
- 5+ sprints expected
- Auth/security/payment related
- New architecture pattern

Announce mode in one line and proceed.

## LIGHT Mode

Original Anthropic triple-agent harness:

```
Phase 1: Planner → spec → user approval
Phase 2: Generator (sprint implementation)
Phase 3: Evaluator (live testing)
Phase 4: Commit
```

## STANDARD Mode

### Phase 0: PM Sprint Planning

PM agent runs first:

```
Agent(name: "pm")
→ Analyze feature scope
→ Estimate sprints, cost, risk
→ Create priority/dependency map
→ Identify parallel opportunities
→ Define scope boundaries (IN/OUT/DEFER)
→ Present plan to user
```

User approves plan before proceeding.

### Phase 1: Architecture Design

```
Agent(name: "architect")
→ Existing code pattern analysis
→ Concrete blueprint (files, components, data flow, build order)
→ TDD test scenarios per component
→ ADR generation (mandatory)
→ User approval required
```

### Phase 2: Sprint Contract Negotiation

**Before ANY code is written**, negotiate success criteria:

```
Based on the architect blueprint, define testable success criteria:

## Sprint Contract — Sprint {N}

### Success Criteria (minimum 15 for STANDARD, 27+ for FULL)
1. [ ] {Specific, testable behavior — e.g., "User can click 'Add' button and see new item in list"}
2. [ ] {Another concrete criterion}
3. [ ] ...
15. [ ] ...

### Evaluation Method per Criterion
- UI criteria → Playwright live test (click, screenshot, verify)
- API criteria → curl/httpie request + response validation
- Data criteria → DB query verification
- Build criteria → tsc --noEmit, npm run build

### Pass Threshold
- STANDARD: 80% criteria pass = PASS
- FULL: 90% criteria pass = PASS
```

Present contract to user for approval. Adjust criteria based on feedback.

### Phase 3: TDD Red Phase

```
Agent(name: "test-writer")
→ Read architect blueprint + sprint contract
→ Write failing tests for EACH success criterion
→ Verify tests actually FAIL (Red confirmation)
→ Hand off test file locations to developer
```

### Phase 4: TDD Green Phase (Implementation)

```
Agent(name: "developer")
→ Read blueprint + failing tests
→ Implement in build order: Domain → Application → Infrastructure → Presentation
→ Each file: implement → build check → next file
→ Goal: make ALL Red tests Green
→ Build must pass with 0 errors
```

If developer is not spawned as separate agent (simpler projects),
main context implements directly following the same rules.

### Phase 5: Live Evaluation

**Evaluator tests the RUNNING app, not just static code.**

```
1. Start the app/server
   npm run dev  OR  node dist/index.js

2. Evaluator tests each success criterion from the contract:
   - UI: Playwright MCP → navigate, click, type, screenshot, verify
   - API: curl/httpie → request, check response body/status
   - Data: sqlite3/psql → query, verify state
   - Build: tsc, npm test

3. Score each criterion:
   | # | Criterion | Result | Score | Notes |
   |---|-----------|--------|-------|-------|
   | 1 | Add button creates item | PASS | 1/1 | Verified via screenshot |
   | 2 | Item persists on refresh | FAIL | 0/1 | Item disappears after F5 |
   | ... | ... | ... | ... | ... |

4. Overall scores (Anthropic 4-axis):
   | Axis | Score (1-10) | Notes |
   |------|-------------|-------|
   | Design Quality | {N} | Consistent visual language? |
   | Originality | {N} | Custom decisions vs template defaults? |
   | Completeness | {N} | Typography, spacing, color harmony? |
   | Functionality | {N} | User can understand and complete tasks? |

5. Verdict: PASS (>= threshold) / FAIL (< threshold)
```

### Phase 6: Feedback Loop (max 5 iterations)

If FAIL:

```
Evaluator provides structured feedback:
  - Which criteria failed + specific reproduction steps
  - Screenshot/log evidence
  - Suggested fix approach

Decision (based on score trend):
  Score improving → REFINE (fix specific failures)
  Score plateaued → PIVOT (try fundamentally different approach)
  3 consecutive same-score → ESCALATE (ask user for guidance)

Loop: Phase 4 (developer fixes) → Phase 5 (re-evaluate) → repeat
Max iterations: 5 for STANDARD, 15 for FULL
```

### Phase 7: Parallel Verification Team

After Evaluator PASS, spawn verification team for deep analysis:

```
Agent(name: "verify-quality", run_in_background: true)   → reviewer
Agent(name: "verify-tests", run_in_background: true)     → test-analyzer
Agent(name: "verify-errors", run_in_background: true)    → error-hunter
Agent(name: "verify-types", run_in_background: true)     → type-analyzer (if new types)
```

All spawned in ONE message. Critical issues → back to Phase 4 (max 3 rounds).

### Phase 8: Cleanup + Release

```
1. Simplifier agent → code cleanup suggestions → apply
2. PM retrospective → what went well, what to improve
3. Release-coordinator → version bump, CHANGELOG, tag (if applicable)
4. User approval → commit + push
```

## FULL Mode Extensions

### Phase 1+: Architect + Explorer parallel

```
Agent(name: "architect") + Agent(name: "explorer") simultaneously
→ Blueprint + existing code deep analysis
→ Merged report to user
```

### Phase 2+: 27+ Success Criteria

Sprint contract must have **minimum 27 testable criteria** (Anthropic recommendation).

### Phase 5+: Playwright-First Evaluation

Every UI criterion MUST be tested via Playwright MCP:
```
browser_navigate → browser_snapshot → browser_click → browser_fill_form
→ browser_take_screenshot → verify expected state
```

### Phase 7+: Security Auditor Added

```
5th agent: Agent(name: "verify-security", run_in_background: true) → security-auditor
```

### Per-Sprint Verification

Mid-sprint checks after each sprint (not just final):
- reviewer + error-hunter (2 agents, cost-efficient)
- Full 5-agent team only after final sprint

## Context Anxiety Management

When context window is filling up:

```
1. Agent outputs compressed to token budgets (architect: 2000, verify: 800, simplifier: 500)
2. PM monitors context usage, suggests /compact at 70%
3. After /compact, compact-reinject hook restores team-first principles
4. For Sonnet: spawn fresh sub-agents with clean context (context reset)
5. For Opus: auto-compression handles it (no manual reset needed)
```

## Cost Guide

| Mode | Estimated Cost | Iterations | Example |
|------|---------------|-----------|---------|
| LIGHT | $5-15 | 1-2 | Single endpoint, bug fix |
| STANDARD | $20-80 | 3-5 | Service module, CRUD, component |
| FULL | $80-200+ | 5-15 | Auth system, payment, full app |

## Circuit Breaker

```
Failure 1 → Warning + approach switch
Failure 2 → Strong warning + root cause re-analysis
Failure 3 → Automatic stop + status report to user
```

Resume only on explicit user instruction.

## Rules

- One feature = one session
- **Sprint Contract BEFORE any code** — no coding without agreed criteria
- **test-writer before developer** — TDD Red before Green
- **Evaluator tests LIVE app** — not just static analysis
- Build failure blocks next sprint/phase
- **3 consecutive failures → circuit breaker**
- Verification team spawned **simultaneously**
- Score trend determines REFINE vs PIVOT
- Mode announced to user before proceeding
- **ADR required for architecture decisions**
- Agent results compressed within token budgets
- **Secrets via `leo secret`** — never hard-code
