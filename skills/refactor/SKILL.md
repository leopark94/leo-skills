---
name: refactor
description: "Safe structural refactoring — architect → refactorer → reviewer + type-analyzer verification"
disable-model-invocation: false
user-invocable: true
---

# /refactor — Safe Structural Refactoring

Restructures code safely with architecture analysis first, then refactoring, then multi-agent verification.
Ensures no behavior changes while improving structure.

## Usage

```
/refactor <what to refactor>
/refactor --scope <file|module|layer>
/refactor --dry-run                     # analysis only, no changes
```

## Team Composition & Flow

```
Phase 1: Analysis (sequential)
  architect → refactoring blueprint (what to move, rename, extract)
       |
Phase 2: Exploration (sequential)
  explorer → dependency map + impact analysis
       |
Phase 3: Refactoring (sequential)
  refactorer → execute refactoring plan (worktree isolation)
       |
Phase 4: Verification (parallel)
  +-- reviewer      → code quality + pattern consistency
  +-- type-analyzer  → type design integrity
  +-- test-analyzer  → test coverage after changes
       |
Phase 5: Cleanup
  simplifier → final cleanup pass
```

## Phase 1: Architecture Analysis

```
Agent(
  prompt: "Design a refactoring plan:
    Target: {refactor_description}
    - Map current structure and dependencies
    - Identify what to extract, rename, move, or merge
    - Build order for changes (avoid circular deps)
    - List ALL files that will be touched
    - Risk assessment: what could break?
    Project: {project_root}",
  name: "refactor-architect",
  subagent_type: "architect"
)
```

Show plan to user. **Wait for approval.**

## Phase 2: Dependency Exploration

```
Agent(
  prompt: "Analyze dependencies for refactoring plan:
    Plan: {architect_output}
    - Trace all imports/exports that will change
    - Identify consumers of moved/renamed APIs
    - Flag circular dependencies
    - Check test file references
    Project: {project_root}",
  name: "refactor-explorer",
  subagent_type: "explorer"
)
```

## Phase 3: Execute Refactoring

```
Agent(
  prompt: "Execute this refactoring plan:
    Blueprint: {architect_output}
    Dependencies: {explorer_output}
    - Follow build order strictly
    - Update ALL imports/exports
    - Verify build after each major step
    - NO behavior changes — structure only
    Project: {project_root}",
  name: "refactor-exec",
  subagent_type: "refactorer",
  isolation: "worktree"
)
```

## Phase 4: Verification (3 agents parallel)

```
Agent(name: "verify-quality", subagent_type: "reviewer", run_in_background: true)
Agent(name: "verify-types", subagent_type: "type-analyzer", run_in_background: true)
Agent(name: "verify-tests", subagent_type: "test-analyzer", run_in_background: true)
```

All 3 spawned in a single message. Critical issues → back to Phase 3 (max 2 rounds).

## Phase 5: Report

```markdown
## Refactoring Complete

### Scope: {what was refactored}
### Files Changed: {n}
### Verification: {3 agent results}
### Behavior Changes: NONE (confirmed by tests)
### Ready to commit? → user approval
```

## Rules

- **Zero behavior changes** — refactoring only
- Architecture analysis BEFORE any changes
- User approval required after Phase 1
- Build must pass after every step
- If behavior change needed → escalate to `/team-feature`
- Max 2 verification-fix loops
