---
name: investigate
description: "Diagnoses issues using competing hypotheses — auto-deploys parallel agents for complex bugs"
disable-model-invocation: false
user-invocable: true
---

# /investigate — Competing Hypotheses Diagnosis (Automatic Team Scaling)

Anthropic-recommended debugging pattern.
Automatically deploys parallel agent teams for complex bugs based on bug complexity.

## Usage

```
/investigate <problem description>
/investigate --parallel            # force parallel mode
/investigate --serial              # force sequential mode
/investigate --error "<error msg>"
```

## Step 0: Mode Selection

**Default is PARALLEL (team mode).** Sequential requires explicit opt-out.

### PARALLEL Mode [default]
-> Each hypothesis assigned to a separate agent for simultaneous verification
-> Explorer collects symptoms first

### SERIAL Mode (--serial flag only)
-> Sequential hypothesis verification in main context
-> Cost reduction purpose

**SERIAL is only used when the user explicitly passes `/investigate --serial`.** All other cases use PARALLEL.
Announce the mode to the user in one line and proceed immediately.

## Common: Symptom Collection

### Explorer Agent (PARALLEL mode only)

```
Agent(name: "symptom-collector")
  -> Error messages / stack traces
  -> Related files and code paths
  -> Recent changes (git log)
  -> Environment information
  -> Reproduction conditions
```

### Direct Collection (SERIAL mode)

In main context:
```bash
git log --oneline -10
git diff
# Check error logs
# Check environment info
```

## Common: Hypothesis Formation (minimum 5)

```markdown
| # | Hypothesis | Probability | Verification Method | Verification Command |
|---|-----------|-------------|-------------------|---------------------|
| 1 | {hypothesis} | 40% | {method} | {command} |
| 2 | {hypothesis} | 25% | {method} | {command} |
| 3 | {hypothesis} | 15% | {method} | {command} |
| 4 | {hypothesis} | 10% | {method} | {command} |
| 5 | {hypothesis} | 10% | {method} | {command} |
```

Hypotheses must be **independently verifiable** (prerequisite for PARALLEL mode).

## SERIAL Mode Execution

Verify from highest to lowest probability:

```
for each hypothesis (by probability desc):
  1. Execute verification command
  2. Record result: CONFIRMED / REJECTED / INCONCLUSIVE
  3. CONFIRMED -> proceed to fix phase immediately
  4. 2 consecutive REJECTED -> consider adding new hypotheses
```

## PARALLEL Mode Execution

### Parallel Hypothesis Verification

Spawn one agent per hypothesis simultaneously:

```
Agent(name: "hypothesis-1", run_in_background: true)
  -> "Hypothesis: {h1}, Verification: {m1}, Related files: {files}
     Verdict: CONFIRMED/REJECTED/INCONCLUSIVE + evidence"

Agent(name: "hypothesis-2", run_in_background: true)
  -> Same structure

... (all 5 simultaneously)
```

**All 5 spawned in a single message.**

### Result Collection

```
After all agents complete:
  CONFIRMED exists    -> fix based on highest-probability CONFIRMED
  Multiple CONFIRMED  -> root cause analysis (may be related)
  All REJECTED        -> new hypothesis round (back to Phase 2, max 2 rounds)
  Only INCONCLUSIVE   -> request additional info from user
```

## Common: Fix & Verification

```
Fix:
  - Minimal change targeting root cause only
  - git stash or status check before fixing
  - No unrelated code changes

Verification:
  - Build passes
  - Original error no longer reproduces
  - Related tests pass
```

## Common: Report

```markdown
## Diagnosis Results

### Mode: {SERIAL / PARALLEL}
### Agents deployed: {list if any}

### Root Cause
{Confirmed root cause}

### Hypothesis Verification Results
| # | Hypothesis | Probability | Verdict | Key Evidence |
|---|-----------|-------------|---------|-------------|
| 1 | ... | 40% | CONFIRMED | ... |
| 2 | ... | 25% | REJECTED | ... |
| ... | ... | ... | ... | ... |

### Fix Applied
| File | Change | Rationale |
|------|--------|-----------|
| ... | ... | ... |

### Verification
- [x] Build passes
- [x] Error resolved
- [x] No regressions

### Rejected Hypotheses (reference)
{For future debugging reference}
```

## Rules

- Minimum **5 hypotheses** (tunnel vision prevention)
- Announce mode decision to user **before starting**
- 2 consecutive same-fix failures -> switch approach
- PARALLEL loop (all hypotheses rejected -> re-form) max 2 rounds
- Fix **root cause only** — no symptom treatment
- Brute force forbidden — always hypothesis-driven
