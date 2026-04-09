---
name: test
description: "Comprehensive testing — test-writer → developer → integration-tester → evaluator pipeline"
disable-model-invocation: false
user-invocable: true
---

# /test — Comprehensive Test Coverage

Full TDD cycle: write tests → implement → integration test → live evaluation.

## Usage

```
/test <what to test>
/test --unit                   # unit tests only
/test --integration            # integration/E2E tests only
/test --coverage               # analyze existing coverage gaps
```

## Issue Tracking

```bash
gh issue create --title "test: {target}" --body "Test coverage tracking" --label "testing"
```

## Team Composition & Flow

```
Phase 1: Coverage Analysis (sequential)
  test-analyzer → existing coverage gaps + priority targets
       |
Phase 2: Test Writing — Red (sequential)
  test-writer → write failing tests (worktree)
       |
Phase 3: Implementation — Green (sequential, if needed)
  developer → implement to make tests pass (worktree)
       |
Phase 4: Integration Tests (sequential)
  integration-tester → E2E + API contract tests (worktree)
       |
Phase 5: Live Evaluation (sequential)
  evaluator → run full test suite + report
```

## Phase 1: Coverage Analysis

```
Agent(
  prompt: "Analyze test coverage:
    Target: {test_target}
    - Map existing tests
    - Identify critical untested paths
    - Priority: edge cases, error paths, happy paths
    - Recommend test types per gap
    Project: {project_root}",
  name: "test-analysis",
  subagent_type: "test-analyzer"
)
```

## Phase 2: Red Phase (Write Failing Tests)

```
Agent(
  prompt: "Write failing tests (TDD Red):
    Analysis: {coverage_output}
    - Unit tests for uncovered functions
    - Edge case tests
    - Error path tests
    - Verify tests actually FAIL
    Project: {project_root}",
  name: "test-red",
  subagent_type: "test-writer",
  isolation: "worktree"
)
```

## Phase 3: Green Phase (if implementation needed)

Only if tests reveal missing implementation:
```
Agent(
  prompt: "Implement to make tests pass (TDD Green):
    Failing tests: {test_files}
    - Minimal implementation
    - All red tests must turn green
    Project: {project_root}",
  name: "test-green",
  subagent_type: "developer",
  isolation: "worktree"
)
```

## Phase 4: Integration Tests

```
Agent(
  prompt: "Write integration/E2E tests:
    - API contract tests (request/response validation)
    - Service integration tests
    - Playwright E2E for UI (if applicable)
    Project: {project_root}",
  name: "test-integration",
  subagent_type: "integration-tester",
  isolation: "worktree"
)
```

## Phase 5: Report

```markdown
## Test Coverage Complete

### Target: {what was tested}
### Tests Added: {n unit} + {n integration}
### Coverage: {before}% → {after}%
### All Tests Pass: YES/NO
### Ready to commit? → user approval
```

## Rules

- TDD Red-Green cycle: tests BEFORE implementation
- Tests must actually FAIL first (Red confirmation)
- Integration tests required for API boundaries
- Coverage analysis BEFORE writing new tests
- No test without assertion — snapshot tests need justification
