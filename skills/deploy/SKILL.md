---
name: deploy
description: "Deployment orchestration — ci-engineer → env-manager → evaluator pipeline"
disable-model-invocation: false
user-invocable: true
---

# /deploy — Deployment Orchestration

Validates environment, runs deployment, and verifies post-deploy health.

## Usage

```
/deploy                        # deploy current branch
/deploy --env <staging|prod>   # target environment
/deploy --dry-run              # validate without deploying
/deploy --rollback             # rollback last deployment
```

## Issue Tracking

Before any work, create a GitHub issue:
```bash
gh issue create --title "deploy: {env} {version}" --body "Deployment tracking" --label "deploy"
```

## Team Composition & Flow

```
Phase 1: Pre-deploy Checks (parallel)
  +-- ci-engineer  → build + CI validation
  +-- env-manager  → environment + secrets validation
       |
Phase 2: Deploy (sequential)
  developer → execute deployment scripts
       |
Phase 3: Post-deploy Verification (sequential)
  evaluator → health checks + smoke tests
       |
Phase 4: Rollback (if needed)
  incident-commander → rollback execution
```

## Phase 1: Pre-deploy Checks (2 agents parallel)

```
Agent(name: "check-ci", subagent_type: "ci-engineer", run_in_background: true)
  → "Validate build and CI pipeline for deployment:
     - Build passes with 0 errors
     - All tests pass
     - Dockerfile/deployment config valid
     - No pending CI failures"

Agent(name: "check-env", subagent_type: "env-manager", run_in_background: true)
  → "Validate deployment environment:
     - All required secrets present (leo secret check)
     - Environment parity (staging matches prod config shape)
     - No missing environment variables
     - Service dependencies reachable"
```

Any FAIL → abort deployment.

## Phase 2: Deploy

After user approval:
```
Agent(
  prompt: "Execute deployment:
    CI check: {ci_output}
    Env check: {env_output}
    - Run deploy.sh or equivalent
    - Monitor deployment progress
    - Capture deployment logs
    Project: {project_root}",
  name: "deployer",
  subagent_type: "developer",
  isolation: "worktree"
)
```

## Phase 3: Post-deploy Verification

```
Agent(
  prompt: "Verify deployment health:
    - Health endpoint responds 200
    - Key user flows functional
    - No error spikes in logs
    - Response times within SLA
    Project: {project_root}",
  name: "verify-deploy",
  subagent_type: "evaluator"
)
```

## Phase 4: Report

```markdown
## Deployment Complete

### Environment: {env}
### Version: {version}
### Pre-checks: PASS
### Health: PASS/FAIL
### Rollback needed: NO
### Issue: #{issue_number} (closed)
```

## Rules

- Pre-deploy checks MUST pass before deploying
- User approval required before Phase 2
- Post-deploy health check mandatory
- Rollback plan always ready
- Never deploy directly to prod without staging first
- All progress tracked on GitHub issue
