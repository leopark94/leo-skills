---
name: team-feature
description: "Develops features using architect-explore-implement-verify team with sequential+parallel orchestration"
disable-model-invocation: false
user-invocable: true
---

# /team-feature — Agent Team Feature Development

Develops features through architect -> explore -> implement -> verify (parallel) -> simplify flow.
Unlike `/sprint`'s harness pattern, deploys **specialist agent teams at each stage**.

## Usage

```
/team-feature <feature description>
/team-feature --spec <spec-file.md>    # spec file based
```

## Issue Tracking

Before any work, create a GitHub issue:
```bash
gh issue create --title "feature: {feature}" --body "Feature development tracking" --label "feature"
```
All agents comment progress to this issue. Close on completion.

## Team Composition & Execution Flow

```
Phase 1: Design (sequential)
  architect --> blueprint output
       |
Phase 2: Exploration (sequential)
  explorer --> existing code analysis output
       |
Phase 3: Implementation (main context)
  [user + Claude direct implementation]
       |
Phase 4: Verification (parallel)
  +-- test-analyzer --> test analysis
  +-- error-hunter  --> error handling analysis
  +-- type-analyzer --> type design analysis
  +-- reviewer      --> code quality analysis
       |
Phase 5: Cleanup (sequential)
  simplifier --> simplification suggestions
       |
Phase 6: Completion
  user approval -> commit
```

## Detailed Process

### Phase 1: Architecture Design

```
Agent(
  prompt: "Design an architecture blueprint for this feature: {feature_description}
    - Analyze existing codebase patterns
    - List files to create/modify
    - Component design, data flow
    - Build order
    Project: {project_root}
    CLAUDE.md: {claude_md_path}",
  name: "architect"
)
```

Show architect results to user and **wait for approval**.
Proceed only after approval.

### Phase 2: Codebase Exploration

```
Agent(
  prompt: "Analyze related existing code based on the architect's blueprint:
    Blueprint: {architect_output}
    - Current structure of files to modify
    - Existing implementation patterns for similar features
    - Dependency relationships
    Project: {project_root}",
  name: "explorer"
)
```

Inject exploration results as summary into main context.

### Phase 3: Implementation

**Implemented in main context, NOT by an agent.**

```
1. Implement following blueprint's build order
2. Verify build after each step (npm run build / project build command)
3. Build failure blocks next step
4. After implementation complete -> Phase 4
```

### Phase 4: Parallel Verification

After implementation, **spawn 4 agents simultaneously for verification:**

```
Agent(test-analyzer role, run_in_background: true, name: "verify-tests")
Agent(error-hunter role, run_in_background: true, name: "verify-errors")
Agent(type-analyzer role, run_in_background: true, name: "verify-types")
Agent(reviewer role, run_in_background: true, name: "verify-quality")
```

Information to provide each agent:
- Architect blueprint (original intent)
- Changed file list and diff
- Project CLAUDE.md

### Phase 5: Results Analysis & Cleanup

```
Collect results from all 4 agents:
1. Critical issues exist -> return to Phase 3 for fixes (max 3 rounds)
2. No critical issues   -> spawn simplifier agent

Agent(
  prompt: "Analyze simplification opportunities in these changes:
    Changed files: {file_list}
    - Remove unnecessary complexity
    - Improve readability
    Functionality must be preserved",
  name: "simplifier"
)
```

### Phase 6: Completion

```markdown
## Team Feature Complete

### Implementation Summary
- Feature: {feature_name}
- Files created: {n}
- Files modified: {n}

### Verification Results
| Agent | Verdict | Issues |
|-------|---------|--------|
| test-analyzer | PASS/FAIL | {summary} |
| error-hunter | PASS/FAIL | {summary} |
| type-analyzer | PASS/FAIL | {summary} |
| reviewer | PASS/FAIL | {summary} |

### Simplifications Applied
- {applied simplification list}

### Ready to commit?
-> Waiting for user approval
```

## /sprint vs /team-feature

| Aspect | /sprint | /team-feature |
|--------|---------|---------------|
| Planning | Planner (abstract) | Architect (concrete blueprint) |
| Implementation | Generator (single) | Main context (direct) |
| Evaluation | Evaluator (live testing) | 4 specialist agents (parallel static analysis) |
| Cleanup | None | Simplifier |
| Iteration | Eval-Gen loop | Reimplementation only on critical issues |
| Best for | Large multi-sprint work | Single feature precision implementation |

## Rules

- Phase 1 architect results **require user approval** before proceeding
- Phase 4 verification **must spawn 4 agents simultaneously**
- Phase 3 -> Phase 4 -> Phase 3 loop: **max 3 rounds**
- Build failure blocks next phase
- Report progress to user at each phase transition
