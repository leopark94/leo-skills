---
name: setup
description: "Project scaffolding — scaffolder → config-writer → env-manager → ci-engineer pipeline"
disable-model-invocation: false
user-invocable: true
---

# /setup — Project Scaffolding & Setup

Creates new project structure with DDD layers, configs, environment, and CI/CD.

## Usage

```
/setup <project description>
/setup --template <node|python|swift|flutter>
/setup --monorepo                # monorepo setup (Turborepo/Nx)
/setup --minimal                 # bare minimum setup
```

## Issue Tracking

```bash
gh issue create --title "setup: {project-name}" --body "Project setup tracking" --label "setup"
```

## Team Composition & Flow

```
Phase 1: Architecture (sequential)
  architect → project structure design + tech decisions
       |
Phase 2: Scaffolding (sequential)
  scaffolder → DDD folders, barrel exports, tsconfig (worktree)
       |
Phase 3: Configuration (parallel)
  +-- config-writer → tsconfig, eslint, prettier, package.json
  +-- env-manager   → .env template, .leo-secrets.yaml, env validation
  +-- ci-engineer   → GitHub Actions, Dockerfile, launchd
       |
Phase 4: ADR + Docs (sequential)
  architect → initial ADR records
```

## Phase 1: Architecture Design

```
Agent(
  prompt: "Design project architecture:
    Project: {project_description}
    - Tech stack selection + rationale
    - DDD layer structure (domain/application/infrastructure/presentation)
    - Module boundaries
    - Scale assessment (small/medium/large)
    - Apply CQRS level appropriate to scale
    Project root: {project_root}",
  name: "setup-architect",
  subagent_type: "architect"
)
```

User approval required.

## Phase 2: Scaffolding

```
Agent(
  prompt: "Scaffold project structure:
    Blueprint: {architect_output}
    - Create directory structure
    - Barrel exports (index.ts)
    - tsconfig path aliases
    - Base dependency installation
    Project: {project_root}",
  name: "setup-scaffold",
  subagent_type: "scaffolder",
  isolation: "worktree"
)
```

## Phase 3: Configuration (3 agents parallel)

```
Agent(name: "setup-config", subagent_type: "config-writer", isolation: "worktree", run_in_background: true)
  → "Generate project configs: tsconfig, eslint, prettier, package.json"

Agent(name: "setup-env", subagent_type: "env-manager", run_in_background: true)
  → "Set up environment: .env.example, .leo-secrets.yaml, validation"

Agent(name: "setup-ci", subagent_type: "ci-engineer", isolation: "worktree", run_in_background: true)
  → "Set up CI/CD: GitHub Actions workflow, Dockerfile, deploy script"
```

## Phase 4: Report

```markdown
## Project Setup Complete

### Project: {name}
### Structure: {DDD layer summary}
### Tech Stack: {stack}
### Configs: {list}
### CI/CD: {pipeline description}
### ADRs: {list of initial decisions}
### Next steps: Start feature development with /team-feature
```

## Rules

- Architecture decision before scaffolding
- DDD structure scaled to project size
- All configs must be validated (Zod schemas)
- .leo-secrets.yaml mandatory for leo-* projects
- ADR-0001 always created (initial architecture decision)
- CLAUDE.md generated for the new project
