---
name: sprint
description: "Implements features using the Anthropic triple-agent harness with automatic specialist team deployment"
disable-model-invocation: false
user-invocable: true
---

# /sprint — Triple-Agent Harness + Automatic Team Scaling

Based on the Anthropic "Harness Design" pattern.
Automatically deploys specialist agents based on complexity for quality assurance.

## Usage

```
/sprint <feature description>
/sprint --light "simple task"
/sprint --full "complex auth system"
```

## Step 0: Mode Selection

**Default is STANDARD (team mode).** Solo requires explicit opt-out.

```
STANDARD mode [default]:
  -> Architect agent produces concrete blueprint
  -> After implementation, verification team spawned in parallel
  -> Simplifier cleanup

FULL mode (auto-escalation or --full):
  -> Architect + Explorer before implementation
  -> Verification team after each sprint
  -> Security Auditor added
  -> Simplifier cleanup

LIGHT mode (--light flag only):
  -> Original harness (Planner -> Generator -> Evaluator)
  -> No specialist agents
```

Auto-escalation conditions (STANDARD -> FULL):
- 5+ sprints expected
- Authentication/security/payment related
- New architecture pattern introduced

**LIGHT is only used when the user explicitly passes `/sprint --light`.** All other cases use STANDARD or higher.
Announce the mode to the user in one line and proceed immediately.

## LIGHT Mode

Original harness flow:

```
Phase 1: Planner -> spec -> user approval
Phase 2: Generator (sprint implementation)
Phase 3: Evaluator (live testing)
Phase 4: Commit
```

## STANDARD Mode

### Phase 1: Design

Spawn Architect agent:
```
-> Analyze existing code patterns
-> Produce concrete blueprint (file list, components, data flow, build order)
-> Wait for user approval
```

If Planner answers "what," Architect answers "how."
Blueprint must include reference to similar existing files.

### Phase 2: Implementation (per sprint)

For each sprint:
1. Implement following blueprint's build order
2. Verify build passes
3. If build fails, do NOT proceed to next sprint

### Phase 3: Verification Team Deployment

After all sprint implementation completes, **spawn 4 agents simultaneously:**

```
Agent(name: "verify-quality", run_in_background: true)
  -> reviewer role: code quality, naming, structure, project rules

Agent(name: "verify-tests", run_in_background: true)
  -> test-analyzer role: test coverage, missing cases

Agent(name: "verify-errors", run_in_background: true)
  -> error-hunter role: silent errors, empty catch, error swallowing

Agent(name: "verify-types", run_in_background: true)
  -> type-analyzer role: type design quality (only when new types exist)
```

Spawn all 4 agents **in a single message**.
If no new types, skip verify-types (spawn only 3).

### Phase 4: Results Processing

```
Collect verification results:
  Critical issues found -> return to Phase 2 for fixes (max 3 rounds)
  No critical issues    -> spawn Simplifier agent
    -> Review simplification suggestions -> apply -> commit
```

### Phase 5: Completion

```markdown
## Sprint Complete

### Mode: STANDARD
### Agents deployed: architect, reviewer, test-analyzer, error-hunter, [type-analyzer], simplifier

### Implementation Summary
- ...

### Verification Results
| Agent | Verdict | Key Findings |
|-------|---------|-------------|
| reviewer | PASS | ... |
| test-analyzer | PASS | ... |
| error-hunter | PASS | ... |
| type-analyzer | PASS | ... |

### Simplifications Applied
- ...

### Ready to commit?
```

## FULL Mode

Extends STANDARD with:

### Phase 1 Extension: Architect + Explorer

```
Agent(name: "architect") -> blueprint
Agent(name: "explorer")  -> existing code analysis (based on architect results)
Integrate both results for user -> approval
```

### Phase 3 Extension: Security Audit Added

Verification team expands to 5:
```
Original 4 + Agent(name: "verify-security", run_in_background: true)
  -> security-auditor role: OWASP Top 10 audit
```

### Per-Sprint Verification

In FULL mode, verification team runs **after each sprint** (not just the final one).
For cost efficiency, each mid-sprint check spawns only reviewer + error-hunter (2 agents).
Full 5-agent team only runs after the final sprint.

## Cost Guide

| Mode | Estimated Cost | Example Use Case |
|------|---------------|-----------------|
| LIGHT | $5-15 | Single API endpoint, simple bug fix |
| STANDARD | $20-60 | New service module, CRUD, dashboard component |
| FULL | $80-200+ | Auth system, payment integration, large refactor |

## Circuit Breaker

```
Failure 1: Warning + switch approach
Failure 2: Strong warning + root cause re-analysis
Failure 3: Automatic stop + report to user
```

Resumes only on explicit user instruction.

## Agent Token Budgets

Compress agent results to prevent excessive main context consumption:

| Agent | Max Tokens | Format |
|-------|-----------|--------|
| architect | 2000 | Blueprint summary |
| verification agents | 800 each | Critical/High only |
| simplifier | 500 | Change suggestion list only |

## Rules

- One feature = one session
- Build failure blocks next sprint/phase
- **3 consecutive failures -> circuit breaker (automatic stop)**
- Verification team must be **spawned simultaneously** (no sequential)
- Show mode decision to user **before proceeding** with approval
- Critical issue fix loop: max 3 rounds
- Agent results compressed within token budgets
- **ADR file required for architecture decisions** (docs/adr/)
- **Secrets must use `leo secret`** (never hard-code in source)
