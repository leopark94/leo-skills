---
name: team-debug
description: "Spawns parallel hypothesis verification agents for systematic bug diagnosis"
disable-model-invocation: false
user-invocable: true
---

# /team-debug — Agent Team Debugging

Executes the competing hypotheses pattern with **parallel agents**.
Verifies multiple hypotheses simultaneously vs `/investigate`'s sequential approach.

## Issue Tracking

```bash
gh issue create --title "debug: {problem}" --body "Debug tracking" --label "bug"
```
Each hypothesis agent comments results to this issue.

## Usage

```
/team-debug <problem description>
/team-debug --error "<error message>"
/team-debug --log <log file path>
```

## Team Composition & Execution Flow

```
Phase 1: Symptom Collection (sequential)
  explorer --> codebase + error context collection
       |
Phase 2: Hypothesis Formation (main context)
  5+ hypotheses + probability estimates
       |
Phase 3: Parallel Verification (simultaneous spawn)
  +-- hypothesis-1 --> verification result
  +-- hypothesis-2 --> verification result
  +-- hypothesis-3 --> verification result
  +-- hypothesis-4 --> verification result
  +-- hypothesis-5 --> verification result
       |
Phase 4: Verdict & Fix (main context)
  Fix based on most probable confirmed hypothesis
       |
Phase 5: Verification (sequential)
  Build + reproduction test
```

## Detailed Process

### Phase 1: Symptom Collection

```
Agent(
  prompt: "Collect symptoms for this bug: {problem_description}
    - Error messages / stack traces
    - Related files and code paths
    - Recent changes (git log --oneline -10)
    - Environment info (Node version, dependencies)
    - Reproduction conditions
    Project: {project_root}",
  name: "symptom-collector"
)
```

### Phase 2: Hypothesis Formation

Form hypotheses in main context based on collected symptoms:

```markdown
| # | Hypothesis | Probability | Verification Method | Verification Command |
|---|-----------|-------------|-------------------|---------------------|
| 1 | {hypothesis} | 40% | {method} | {command} |
| 2 | {hypothesis} | 25% | {method} | {command} |
| 3 | {hypothesis} | 15% | {method} | {command} |
| 4 | {hypothesis} | 10% | {method} | {command} |
| 5 | {hypothesis} | 10% | {method} | {command} |
```

**Hypotheses must be independently verifiable.**

### Phase 3: Parallel Hypothesis Verification

Spawn one agent per hypothesis simultaneously:

```
Agent(
  prompt: "Verify this hypothesis:
    Hypothesis: {hypothesis_N}
    Verification method: {verification_method}
    Verification command: {verification_command}
    
    Symptom context: {symptom_summary}
    Related files: {related_files}
    
    Output format:
    - Verdict: CONFIRMED / REJECTED / INCONCLUSIVE
    - Evidence: {concrete evidence}
    - Additional findings: {any extra info discovered during verification}",
  run_in_background: true,
  name: "hypothesis-{N}"
)
```

**All 5 agents MUST be spawned in a single message.**

### Phase 4: Verdict & Fix

```
1. Collect all hypothesis verification results
2. CONFIRMED exists     -> fix based on that hypothesis
3. Multiple CONFIRMED   -> fix highest probability first
4. All REJECTED         -> new hypothesis round (back to Phase 2, max 2 rounds)
5. Only INCONCLUSIVE    -> request additional information

Fix principles:
- Minimal change (root cause only)
- No unrelated code changes
- git stash for backup before fixing
```

### Phase 5: Verification

```bash
# Build check
{project_build_command}

# Reproduction attempt -> should no longer reproduce
{reproduction_steps}

# Related test execution
{test_command}
```

## Output Format

```markdown
## Team Debug Results

### Symptom Summary
- Error: {error message}
- Reproduction: {conditions}

### Hypothesis Verification Results
| # | Hypothesis | Probability | Verdict | Key Evidence |
|---|-----------|-------------|---------|-------------|
| 1 | ... | 40% | CONFIRMED | {evidence} |
| 2 | ... | 25% | REJECTED | {evidence} |
| 3 | ... | 15% | REJECTED | {evidence} |
| 4 | ... | 10% | INCONCLUSIVE | {reason} |
| 5 | ... | 10% | REJECTED | {evidence} |

### Root Cause
- Confirmed hypothesis: #{N} — {hypothesis content}
- Root cause: {detailed explanation}

### Fix Applied
| File | Change | Rationale |
|------|--------|-----------|
| ... | ... | ... |

### Verification
- Build: PASS/FAIL
- Reproduction test: PASS/FAIL
- Related tests: PASS/FAIL

### Rejected Hypotheses (reference)
{Each rejected hypothesis with reason — for future debugging reference}
```

## /investigate vs /team-debug

| Aspect | /investigate | /team-debug |
|--------|-------------|-------------|
| Verification | Sequential (highest probability first) | Parallel (all simultaneously) |
| Speed | Slower (serial) | Faster (parallel) |
| Context | Single (pollution risk) | Isolated (per-agent fork) |
| Cost | Lower | Higher (5x agents) |
| Best for | Simple bugs, cost savings | Complex bugs, fast diagnosis needed |

## Rules

- Minimum **5 hypotheses** (tunnel vision prevention)
- Hypotheses must be **mutually independent** (dependent hypotheses must be split)
- Hypothesis verification agents MUST be **spawned simultaneously**
- Phase 2 -> Phase 3 loop: **max 2 rounds**
- Fix **root cause only** — no symptom treatment
- `git stash` or verify current state before fixing
