---
name: migrate
description: "Database/schema migration — architect → migration-writer → developer → test-writer pipeline"
disable-model-invocation: false
user-invocable: true
---

# /migrate — Database & Schema Migration

Safe database migrations with rollback plans, backward compatibility checks, and data loss prevention.

## Usage

```
/migrate <migration description>
/migrate --dry-run                  # generate SQL only, don't apply
/migrate --rollback <migration-id>  # rollback specific migration
```

## Team Composition & Flow

```
Phase 1: Design (sequential)
  architect → migration strategy + backward compatibility plan
       |
Phase 2: Schema Analysis (sequential)
  db-specialist → current schema analysis + optimization recommendations
       |
Phase 3: Migration Writing (sequential)
  migration-writer → migration files + rollback scripts (worktree)
       |
Phase 4: Verification (parallel)
  +-- test-writer      → migration tests (up + down)
  +-- reviewer         → SQL review + safety check
       |
Phase 5: Apply
  developer → apply migration + verify data integrity
```

## Phase 1: Migration Strategy

```
Agent(
  prompt: "Design migration strategy:
    Migration: {migration_description}
    - Analyze current schema
    - Design target schema
    - Backward compatibility assessment
    - Data loss risk analysis
    - Rollback plan (mandatory)
    - Zero-downtime migration possible?
    Project: {project_root}",
  name: "migrate-architect",
  subagent_type: "architect"
)
```

User approval required.

## Phase 2: Schema Analysis

```
Agent(
  prompt: "Analyze current database schema:
    Strategy: {architect_output}
    - Current table relationships
    - Index usage and optimization
    - Query patterns that will be affected
    - WAL mode / connection pool considerations
    Project: {project_root}",
  name: "migrate-db",
  subagent_type: "db-specialist"
)
```

## Phase 3: Write Migration

```
Agent(
  prompt: "Write migration files:
    Strategy: {architect_output}
    Schema analysis: {db_output}
    - UP migration (apply changes)
    - DOWN migration (rollback)
    - Data migration if needed (transform existing data)
    - Idempotent operations where possible
    Project: {project_root}",
  name: "migrate-writer",
  subagent_type: "migration-writer",
  isolation: "worktree"
)
```

## Phase 4: Verification (2 agents parallel)

```
Agent(name: "verify-migration", subagent_type: "test-writer", run_in_background: true)
  → "Write tests for migration UP and DOWN: {migration_files}"

Agent(name: "verify-sql", subagent_type: "reviewer", run_in_background: true)
  → "Review SQL migration for safety: {migration_files}"
```

## Phase 5: Report

```markdown
## Migration Complete

### Migration: {description}
### Files: {migration file list}
### Backward Compatible: YES/NO
### Rollback Plan: {rollback command}
### Data Loss Risk: NONE/LOW/MEDIUM/HIGH
### Ready to apply? → user approval
```

## Rules

- **Rollback plan mandatory** — no migration without DOWN script
- **Backup before apply** — always dump before running
- Data loss detected → BLOCK and require user confirmation
- Zero-downtime preferred — additive changes first, then cleanup migration
- Never DROP columns without data migration first
- Test UP + DOWN in sequence before applying
