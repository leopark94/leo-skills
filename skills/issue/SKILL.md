---
name: issue
description: "3-perspective issue management — planner (PM), analyst (architect), reviewer (QA) for before/after work"
disable-model-invocation: false
user-invocable: true
---

# /issue — Multi-Perspective Issue Management

3 agents with different viewpoints ensure issues are well-defined before work starts
and properly verified after work completes.

## Usage

```
/issue create <description>        # create structured issue (planner + analyst)
/issue review <number>             # review completed issue (reviewer + analyst)
/issue triage                      # triage open issues (analyst)
/issue check <number>              # mid-work progress check (reviewer)
```

## Issue Template (enforced by planner)

```markdown
## Summary
One paragraph: WHAT and WHY.

## Scope
### IN scope
- [ ] Deliverable 1
- [ ] Deliverable 2

### OUT of scope
- Excluded item

## Acceptance Criteria
- [ ] AC1: When [action], then [expected result]
- [ ] AC2: [Measurable outcome]
- [ ] AC3: Build passes, 0 errors
- [ ] AC4: Tests cover changes

## Technical Notes
- Files affected: [list]
- Dependencies: [issues or "none"]
- Related: #N

## Labels
type: [bug|feature|refactor|docs|infra|chore]
priority: [P0|P1|P2]
size: [S|M|L|XL]
```

## /issue create — Before Work

Spawn 2 agents in parallel:

```
Agent(name: "plan-issue", subagent_type: "issue-planner", run_in_background: true)
  → "Create a structured GitHub issue for this work:
     Description: {description}
     - Follow the issue template exactly
     - Check for duplicate issues first (gh issue list)
     - Define clear acceptance criteria (testable, binary)
     - Set scope boundaries (IN/OUT)
     - Size estimate (S/M/L/XL — decompose if XL)
     - Assign labels (type + priority + size)
     Project: {project_root}"

Agent(name: "analyze-issue", subagent_type: "issue-analyst", run_in_background: true)
  → "Analyze technical feasibility for this proposed work:
     Description: {description}
     - Impact assessment (blast radius)
     - Dependency mapping (upstream/downstream)
     - Risk evaluation (top 3 risks + mitigations)
     - Architecture alignment check
     - Alternative approaches (minimum 2)
     - Feasibility verdict: GO / GO WITH CHANGES / SPIKE FIRST / RETHINK
     Project: {project_root}"
```

### After Both Complete

Merge results into a single issue:
1. Planner's structure → issue body
2. Analyst's assessment → appended as "Technical Analysis" section
3. Create issue via `gh issue create`
4. Show issue URL to user

If analyst says SPIKE FIRST or RETHINK → flag to user before creating.

## /issue review — After Work

Spawn 2 agents in parallel:

```
Agent(name: "review-issue", subagent_type: "issue-reviewer", run_in_background: true)
  → "Review completed work for issue #{number}:
     - Verify every acceptance criterion (PASS/FAIL with evidence)
     - Check edge cases
     - Verify documentation updated
     - Verdict: APPROVE / NEEDS WORK
     Project: {project_root}"

Agent(name: "impact-check", subagent_type: "issue-analyst", run_in_background: true)
  → "Post-implementation impact check for issue #{number}:
     - Verify no unintended side effects
     - Check dependency chain still valid
     - Confirm architecture alignment maintained
     - Any new risks introduced?
     Project: {project_root}"
```

### After Both Complete

1. Post combined review as issue comment
2. If APPROVE from both → close issue
3. If NEEDS WORK → list specific action items, keep issue open
4. Update `claude-progress.json`

## /issue triage — Prioritize Open Issues

```
Agent(name: "triage", subagent_type: "issue-analyst")
  → "Triage all open issues:
     gh issue list --state open --json number,title,labels,createdAt
     - Priority matrix (urgency vs impact)
     - Dependency order (what blocks what)
     - Recommended sprint assignment
     - Flag stale issues (> 2 weeks no activity)
     Project: {project_root}"
```

## /issue check — Mid-Work Progress

```
Agent(name: "progress-check", subagent_type: "issue-reviewer")
  → "Mid-work progress check for issue #{number}:
     - Which acceptance criteria are met so far?
     - Which are still pending?
     - Any blockers or scope changes needed?
     - Comment progress on the issue
     Project: {project_root}"
```

## Rules

- `/issue create` is **mandatory** before any work — no exceptions
- `/issue review` is **mandatory** before closing any issue
- Issue template must be followed exactly — planner enforces this
- Acceptance criteria must be testable (binary pass/fail)
- XL issues (> 3 days) must be decomposed into sub-issues
- All 3 agents comment directly on the GitHub issue
- Analyst's SPIKE FIRST / RETHINK verdicts halt work until user decides
- Stale issues (> 2 weeks) flagged during triage
