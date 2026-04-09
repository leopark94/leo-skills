---
name: incident
description: "Production incident response — triage → diagnose → fix → verify → postmortem"
disable-model-invocation: false
user-invocable: true
---

# /incident — Production Incident Response

Full incident lifecycle: triage → diagnose → fix → verify → postmortem.
For urgent bugs, use `/hotfix` instead (faster, less ceremony).

## Usage

```
/incident <incident description>
/incident --p0                  # P0 fast-track (skip approvals)
/incident --postmortem-only     # generate postmortem from resolved incident
```

## Issue Tracking

Immediately create a tracking issue:
```bash
gh issue create --title "INCIDENT: {description}" --body "P{severity} incident" --label "incident,P{severity}"
```
All agents comment status updates. Pin issue if P0.

## Team Composition & Flow

```
Phase 1: Triage (sequential)
  incident-commander → severity, blast radius, initial assessment
       |
Phase 2: Diagnosis (parallel)
  +-- debugger (hypothesis 1)
  +-- debugger (hypothesis 2)
  +-- debugger (hypothesis 3)
       |
Phase 3: Fix (sequential)
  developer → targeted fix (worktree)
       |
Phase 4: Verification (parallel)
  +-- evaluator   → live verification
  +-- reviewer    → fix quality
       |
Phase 5: Postmortem (sequential)
  incident-commander → postmortem document
```

## Phase 1: Triage

```
Agent(
  prompt: "Triage production incident:
    Incident: {description}
    - Severity: P0/P1/P2
    - Blast radius (users/features affected)
    - Timeline (when did it start)
    - Current impact (service degraded/down)
    - Immediate mitigation options
    Comment status to issue #{issue_number}
    Project: {project_root}",
  name: "incident-triage",
  subagent_type: "incident-commander"
)
```

P0 → skip approvals, proceed immediately.

## Phase 2: Parallel Diagnosis (3 hypotheses)

```
Agent(name: "hyp-1", subagent_type: "debugger", run_in_background: true)
  → "Hypothesis 1: {h1} — verify and report CONFIRMED/REJECTED"

Agent(name: "hyp-2", subagent_type: "debugger", run_in_background: true)
  → "Hypothesis 2: {h2} — verify and report"

Agent(name: "hyp-3", subagent_type: "debugger", run_in_background: true)
  → "Hypothesis 3: {h3} — verify and report"
```

## Phase 3: Fix

```
Agent(
  prompt: "Fix incident root cause:
    Root cause: {confirmed_hypothesis}
    - Minimal fix only
    - Verify service recovers
    - Comment fix details to issue #{issue_number}
    Project: {project_root}",
  name: "incident-fix",
  subagent_type: "developer",
  isolation: "worktree"
)
```

## Phase 4: Verification (2 agents parallel)

```
Agent(name: "verify-live", subagent_type: "evaluator", run_in_background: true)
Agent(name: "verify-fix", subagent_type: "reviewer", run_in_background: true)
```

## Phase 5: Postmortem

```
Agent(
  prompt: "Generate postmortem:
    - Timeline of events
    - Root cause analysis
    - What went well / what went wrong
    - Action items to prevent recurrence
    - Save to docs/postmortems/
    Project: {project_root}",
  name: "postmortem",
  subagent_type: "incident-commander"
)
```

## Report

```markdown
## Incident Resolved

### Severity: P{n}
### Duration: {start} — {resolved}
### Root Cause: {summary}
### Fix: {what changed}
### Action Items: {list}
### Postmortem: docs/postmortems/{date}-{title}.md
### Issue: #{number} (closed)
```

## Rules

- P0: skip all approval gates, move fast
- P1: brief approval at Phase 2 only
- Always create tracking issue FIRST
- Parallel diagnosis (3 hypotheses minimum)
- Postmortem mandatory for P0/P1
- Fix root cause, not symptoms
