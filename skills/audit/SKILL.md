---
name: audit
description: "Multi-perspective audit — security + dependency + performance agents in parallel"
disable-model-invocation: false
user-invocable: true
---

# /audit — Comprehensive Codebase Audit

Parallel multi-perspective audit: security, dependencies, and performance.

## Usage

```
/audit                         # full audit (all 3)
/audit --security              # security only
/audit --deps                  # dependency only
/audit --perf                  # performance only
```

## Issue Tracking

Before any work, create a GitHub issue:
```bash
gh issue create --title "audit: {project}" --body "Codebase audit tracking" --label "audit"
```
Each agent comments their findings to this issue.

## Team Composition & Flow

```
Phase 1: Parallel Audit (3 agents simultaneously)
  +-- security-auditor    → OWASP Top 10 + attack scenarios
  +-- dependency-auditor  → vulnerabilities + outdated + licenses
  +-- perf-monitor        → build time + memory + bottlenecks
       |
Phase 2: Report Integration
  Main context → merge results, prioritize findings
       |
Phase 3: Action Plan
  architect → remediation blueprint (if critical findings)
```

## Phase 1: Parallel Audit (3 agents)

All spawned in a single message:

```
Agent(name: "audit-security", subagent_type: "security-auditor", run_in_background: true)
  → "Perform OWASP Top 10 security audit:
     - Injection vulnerabilities (SQL, XSS, command)
     - Authentication/authorization flaws
     - Sensitive data exposure
     - Security misconfiguration
     - Concrete attack scenarios for each finding
     Project: {project_root}"

Agent(name: "audit-deps", subagent_type: "dependency-auditor", run_in_background: true)
  → "Audit all dependencies:
     - Known vulnerabilities (CVE)
     - Outdated packages (major/minor/patch)
     - License compliance issues
     - Unused dependencies
     - Bundle size impact
     Project: {project_root}"

Agent(name: "audit-perf", subagent_type: "perf-monitor", run_in_background: true)
  → "Profile performance:
     - Build time analysis
     - Memory usage patterns
     - Bundle size breakdown
     - Polling/request latency
     - Bottleneck identification
     Project: {project_root}"
```

## Phase 2: Integrated Report

```markdown
## Audit Report — {project}

### Summary
| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Security | {n} | {n} | {n} | {n} |
| Dependencies | {n} | {n} | {n} | {n} |
| Performance | {n} | {n} | {n} | {n} |

### Critical Findings (must fix)
{Merged from all 3 agents, deduplicated}

### High Priority
{Merged}

### Medium Priority
{Merged}

### Recommendations
{Top 5 actionable items}
```

## Phase 3: Remediation (optional)

If critical findings exist:
```
Agent(
  prompt: "Design remediation plan for audit findings:
    Findings: {critical_findings}
    - Priority order for fixes
    - Estimated effort per fix
    - Dependencies between fixes
    Project: {project_root}",
  name: "audit-remediation",
  subagent_type: "architect"
)
```

## Rules

- All 3 agents spawned simultaneously
- Critical findings → immediate user notification
- Each agent comments findings to GitHub issue
- Remediation plan only if critical findings exist
- Audit results saved to `docs/audit/` for tracking
