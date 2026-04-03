---
name: review
description: "Auto-selects single review or specialist agent team review based on change scope"
disable-model-invocation: false
user-invocable: true
---

# /review — Code Review (Automatic Team Scaling)

Analyzes change scope and nature to **automatically determine review depth**.

## Usage

```
/review                    # review staged + unstaged changes
/review <file>             # review specific file
/review --pr <n>           # review a PR
/review --deep             # force team review
/review --quick            # force single review
```

## Step 0: Mode Selection

**Default is STANDARD (team mode).** Solo requires explicit opt-out.

```bash
# Determine change scope
git diff --stat
git diff --numstat
```

### STANDARD Mode [default]
-> reviewer + context-appropriate specialist agents (minimum 2)

### DEEP Mode (auto-escalation or --deep)
Auto-escalation conditions:
- Changed files > 10
- Changed lines > 500
- Auth/security/payment files included

-> All 5 specialist agents spawned in parallel

### QUICK Mode (--quick flag only)
-> Direct review in main context (no agent spawning)

**QUICK is only used when the user explicitly passes `/review --quick`.** All other cases use STANDARD or higher.

## QUICK Mode Execution

No agent spawning — direct review in main context:

```markdown
## Review Results

### Must Fix
- ...

### Should Fix
- ...

### Nit
- ...

### Well Done
- ...

### Verdict: APPROVE / REQUEST CHANGES
```

## STANDARD Mode Execution

Selectively spawn agents based on change characteristics:

```
Always spawn:
  Agent(name: "review-quality", run_in_background: true)
    -> reviewer: code quality + project rules

Conditional spawns:
  New types/interfaces detected:
    Agent(name: "review-types", run_in_background: true)
      -> type-analyzer: type design analysis

  try-catch/error handling changes detected:
    Agent(name: "review-errors", run_in_background: true)
      -> error-hunter: silent error detection

  Source changes without test files included:
    Agent(name: "review-tests", run_in_background: true)
      -> test-analyzer: test coverage analysis
```

Spawn selected agents **in a single message**.

Results integration:
```markdown
## Review Results (STANDARD — {N} agents)

### Deployed Agents
- [x] reviewer (code quality)
- [x] type-analyzer (type design) <- new interface detected
- [ ] error-hunter — not applicable
- [ ] test-analyzer — tests included

### Must Fix
{Integrated critical issues}

### Should Fix
{Integrated warning issues}

### Nit
{Integrated}

### Well Done
{Integrated}

### Verdict: APPROVE / REQUEST CHANGES
```

## DEEP Mode Execution

All 5 agents spawned in parallel:

```
Agent(name: "review-quality", run_in_background: true)    -> reviewer
Agent(name: "review-types", run_in_background: true)      -> type-analyzer
Agent(name: "review-tests", run_in_background: true)      -> test-analyzer
Agent(name: "review-errors", run_in_background: true)     -> error-hunter
Agent(name: "review-security", run_in_background: true)   -> security-auditor
```

All 5 **spawned in a single message**.

Results integration:
```markdown
## Review Results (DEEP — 5 agents)

### Participating Agents
- [x] reviewer: complete
- [x] type-analyzer: complete
- [x] test-analyzer: complete
- [x] error-hunter: complete
- [x] security-auditor: complete

### Critical (Must Fix)
{All agent critical issues merged, duplicates removed}

### High (Should Fix)
{Merged}

### Medium (Nit)
{Merged}

### Well Done
{Merged}

### Verdict: APPROVE / REQUEST CHANGES
- 1+ Critical -> REQUEST CHANGES
```

## Post-Review: Marker Cleanup

After review completes, always run this command to remove the commit-blocking markers:

```bash
rm -f .claude-needs-review .claude-edit-count
```

If these markers remain, the pre-commit-guard hook will block `git commit`.

## Rules

- Announce mode decision to user **in one line** ("STANDARD mode (8 files/320 lines changed, new types detected)")
- **Remove duplicate issues** when merging agent results
- QUICK mode auto-escalates to STANDARD if security keywords detected (auth, token, password, secret, permission)
- User can force mode with `--deep`/`--quick` flags
- **After review, always delete `.claude-needs-review` and `.claude-edit-count` marker files**
