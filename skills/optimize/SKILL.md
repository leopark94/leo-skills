---
name: optimize
description: "Performance optimization — perf-monitor → performance-optimizer → reviewer pipeline"
disable-model-invocation: false
user-invocable: true
---

# /optimize — Performance Optimization

Profile → identify bottlenecks → optimize → verify improvement.

## Usage

```
/optimize                      # auto-detect bottlenecks
/optimize <target>             # optimize specific area
/optimize --build              # build time optimization
/optimize --bundle             # bundle size optimization
/optimize --runtime            # runtime performance
```

## Issue Tracking

```bash
gh issue create --title "optimize: {target}" --body "Performance optimization tracking" --label "performance"
```

## Team Composition & Flow

```
Phase 1: Profiling (sequential)
  perf-monitor → baseline measurements + bottleneck identification
       |
Phase 2: Design (sequential)
  architect → optimization strategy (caching, lazy loading, batching, etc.)
       |
Phase 3: Implementation (sequential)
  performance-optimizer → apply optimizations (worktree)
       |
Phase 4: Verification (parallel)
  +-- perf-monitor → after measurements (compare baseline)
  +-- reviewer     → code quality of optimized code
```

## Phase 1: Profiling

```
Agent(
  prompt: "Profile performance baseline:
    Target: {optimize_target}
    - Build time measurement
    - Bundle size breakdown
    - Runtime profiling (memory, CPU, latency)
    - N+1 query detection
    - Polling/request frequency analysis
    - Identify top 3 bottlenecks
    Project: {project_root}",
  name: "profile-baseline",
  subagent_type: "perf-monitor"
)
```

## Phase 2: Strategy

```
Agent(
  prompt: "Design optimization strategy:
    Baseline: {profile_output}
    - Prioritize by impact (biggest bottleneck first)
    - Recommend: caching, lazy loading, batching, parallelization, memoization
    - Risk assessment per optimization
    - Expected improvement per change
    Project: {project_root}",
  name: "optimize-strategy",
  subagent_type: "architect"
)
```

User approval.

## Phase 3: Implementation

```
Agent(
  prompt: "Apply optimizations:
    Strategy: {architect_output}
    - Implement each optimization
    - Verify build passes after each
    - Comment progress to issue #{issue_number}
    Project: {project_root}",
  name: "optimize-impl",
  subagent_type: "performance-optimizer",
  isolation: "worktree"
)
```

## Phase 4: Verification (2 agents parallel)

```
Agent(name: "profile-after", subagent_type: "perf-monitor", run_in_background: true)
  → "Measure performance after optimization — compare to baseline"

Agent(name: "verify-quality", subagent_type: "reviewer", run_in_background: true)
  → "Review optimized code for quality and correctness"
```

## Report

```markdown
## Optimization Complete

### Target: {what was optimized}
### Results
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Build time | {ms} | {ms} | {%} |
| Bundle size | {KB} | {KB} | {%} |
| Response time | {ms} | {ms} | {%} |

### Optimizations Applied: {list}
### Ready to commit? → user approval
```

## Rules

- Baseline measurement BEFORE any changes
- One optimization at a time (measure impact individually)
- No premature optimization — profile first
- Verify no regressions after each optimization
- Before/after comparison mandatory
