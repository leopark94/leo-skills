---
name: team-review
description: "Spawns 5 specialist agents in parallel for multi-perspective code review"
disable-model-invocation: false
user-invocable: true
---

# /team-review — Agent Team Code Review

Spawns **5 specialist agents in parallel** for multi-perspective code review.
Much deeper analysis than the single-agent `/review` approach.

## Issue Tracking

```bash
gh issue create --title "team-review: {target}" --body "Team review tracking" --label "review"
```
Each agent comments findings to this issue.

## Usage

```
/team-review                    # review git diff (staged + unstaged)
/team-review <file>             # review specific file
/team-review --pr <n>           # review a PR
/team-review --commit <hash>    # review specific commit
```

## Team Composition (5 agents, parallel spawn)

**All agents MUST be spawned simultaneously in a single message using the Agent tool.**

### Agent Spawn Specifications

#### 1. code-quality (reviewer agent)
```
Agent(
  role: reviewer agent,
  prompt: "Review the following changes for code quality: {diff_summary}
    - Naming, structure, duplication, complexity
    - Project rules (MASTER.md)
    - CLAUDE.md conventions
    Changed files: {file_list}",
  run_in_background: true,
  name: "code-quality"
)
```

#### 2. type-review (type-analyzer agent)
```
Agent(
  prompt: "Analyze type/interface design in these changes: {diff_summary}
    - Encapsulation, invariant expression, usefulness, enforcement
    - Focus only on new or modified types
    Changed files: {file_list}",
  run_in_background: true,
  name: "type-review"
)
```

#### 3. test-review (test-analyzer agent)
```
Agent(
  prompt: "Analyze test coverage for these changes: {diff_summary}
    - Are new features sufficiently tested?
    - Edge case coverage gaps?
    - Error path tests exist?
    Changed files: {file_list}",
  run_in_background: true,
  name: "test-review"
)
```

#### 4. error-review (error-hunter agent)
```
Agent(
  prompt: "Hunt for silent errors and poor error handling in these changes: {diff_summary}
    - Empty catch blocks, swallowed errors, dangerous fallbacks
    - Ignored Promise errors
    - Missing resource cleanup
    Changed files: {file_list}",
  run_in_background: true,
  name: "error-review"
)
```

#### 5. security-review (security-auditor agent)
```
Agent(
  prompt: "Perform OWASP Top 10 security audit on these changes: {diff_summary}
    - Authentication/authorization, injection, data exposure
    - Analyze changed code + related security boundaries together
    Changed files: {file_list}",
  run_in_background: true,
  name: "security-review"
)
```

## Execution Process

### Step 1: Pre-collection (Bash phase — main context)

Collect data in main context **before** spawning agents, then inject into agent prompts.
(Analysis agents use only Read/Grep/Glob — tool calls batch up to 10 in parallel)

```bash
# 1. Diff stat + file list
DIFF_STAT=$(git diff --stat)
FILE_LIST=$(git diff --name-only)

# 2. Diff content
DIFF_CONTENT=$(git diff)

# 3. New type/interface detection
NEW_TYPES=$(git diff | grep -E '^\+.*(interface|type|class|enum)\s')

# 4. Error handling change detection
ERROR_CHANGES=$(git diff | grep -E '^\+.*(catch|throw|Error|reject|finally)')

# PR mode: gh pr diff <n>, gh pr view <n> --json files
```

Inject this data into each agent prompt's `{diff_summary}` and `{file_list}`.

### Step 2: Spawn 5 Agents in Parallel

**Spawn all 5 Agent tools in a single message.**
Each agent receives the pre-collected diff data and file list.
All agents run with `run_in_background: true`.
Agents use only Read/Grep/Glob, so internal tool calls also batch in parallel.

### Step 3: Collect & Integrate Results

After all agents complete, merge into a unified report:

```markdown
## Team Review Results

### Participating Agents
- [x] code-quality: complete
- [x] type-review: complete
- [x] test-review: complete
- [x] error-review: complete
- [x] security-review: complete

### Critical (Must Fix)
{All agent critical issues merged, duplicates removed}

### High (Should Fix)
{All agent high issues merged}

### Medium (Nit)
{All agent medium issues merged}

### Well Done
{Positive observations merged}

### Final Verdict: APPROVE / REQUEST CHANGES
- Criteria: 1+ Critical -> REQUEST CHANGES
```

## Rules

- All 5 agents MUST be **spawned simultaneously** (no sequential)
- Each agent analyzes **independently** (no inter-agent dependencies)
- **Remove duplicate issues** when merging results
- 1+ Critical issue = mandatory REQUEST CHANGES
- Include project CLAUDE.md in each agent's context if available
