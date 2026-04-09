---
name: db
description: "Database design + migration — db-specialist → migration-writer → test-writer pipeline"
disable-model-invocation: false
user-invocable: true
---

# /db — Database Design & Management

Schema design, query optimization, migration management, and WAL mode configuration.

## Usage

```
/db <database task>
/db --schema <design description>    # design new schema
/db --optimize                       # query optimization
/db --migrate <migration description> # create migration (delegates to /migrate)
/db --audit                          # schema health check
```

## Issue Tracking

```bash
gh issue create --title "db: {task}" --body "Database work tracking" --label "database"
```

## Team Composition & Flow

```
Phase 1: Analysis (sequential)
  db-specialist → current schema analysis + recommendations
       |
Phase 2: Design (sequential)
  architect → schema design + normalization decisions
       |
Phase 3: Implementation (sequential)
  migration-writer → migration files + seed data (worktree)
       |
Phase 4: Testing (parallel)
  +-- test-writer   → migration tests (up/down) + query tests
  +-- reviewer      → SQL review
       |
Phase 5: Fixtures (sequential)
  fixture-factory → test factories + seed data
```

## Phase 1: Schema Analysis

```
Agent(
  prompt: "Analyze database:
    Task: {db_task}
    - Current schema map (tables, relations, indexes)
    - Query patterns + slow queries
    - WAL mode / connection pool status
    - Normalization assessment
    - Recommend improvements
    Project: {project_root}",
  name: "db-analysis",
  subagent_type: "db-specialist"
)
```

## Phase 2: Design

```
Agent(
  prompt: "Design schema changes:
    Analysis: {db_output}
    - Entity-relationship design
    - Index strategy
    - Migration path (additive first)
    - Backward compatibility plan
    Project: {project_root}",
  name: "db-design",
  subagent_type: "architect"
)
```

User approval.

## Phase 3: Migration

```
Agent(
  prompt: "Write migration files:
    Design: {architect_output}
    - UP + DOWN migrations
    - Data migration if schema changes affect existing data
    - Idempotent where possible
    Project: {project_root}",
  name: "db-migration",
  subagent_type: "migration-writer",
  isolation: "worktree"
)
```

## Phase 4: Verification (2 agents parallel)

```
Agent(name: "db-tests", subagent_type: "test-writer", run_in_background: true, isolation: "worktree")
  → "Write migration tests: UP succeeds, DOWN succeeds, data integrity preserved"

Agent(name: "db-review", subagent_type: "reviewer", run_in_background: true)
  → "Review SQL: injection safety, performance, index usage"
```

## Phase 5: Fixtures

```
Agent(
  prompt: "Generate test fixtures:
    Schema: {final_schema}
    - createUser(), createOrder() factories
    - Seed data for development
    - API response fixtures
    Project: {project_root}",
  name: "db-fixtures",
  subagent_type: "fixture-factory",
  isolation: "worktree"
)
```

## Report

```markdown
## Database Work Complete

### Task: {description}
### Schema Changes: {table list}
### Migrations: {file list}
### Rollback: {rollback command}
### Tests: {n} passing
### Fixtures: {generated factories}
### Ready to apply? → user approval
```

## Rules

- Schema design BEFORE migration writing
- Every migration has UP + DOWN
- Test UP → DOWN → UP sequence
- No DROP without data migration
- Backup before applying to production
- WAL mode for SQLite (always)
- Connection pool size documented in ADR
