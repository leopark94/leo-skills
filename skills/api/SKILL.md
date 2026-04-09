---
name: api
description: "API design + implementation — api-designer → api-developer → contract-validator → integration-tester"
disable-model-invocation: false
user-invocable: true
---

# /api — API Design & Implementation

Full API lifecycle: design → implement → validate contract → integration test.

## Usage

```
/api <api description>
/api --design-only             # OpenAPI spec only, no implementation
/api --from-spec <spec.yaml>   # implement from existing spec
/api --graphql                 # GraphQL instead of REST
```

## Issue Tracking

```bash
gh issue create --title "api: {endpoint/service}" --body "API development tracking" --label "api"
```

## Team Composition & Flow

```
Phase 1: Design (sequential)
  api-designer → OpenAPI spec + error response standards
       |
Phase 2: Implementation (sequential)
  api-developer → controllers, routes, middleware, validators (worktree)
       |
Phase 3: Contract Validation (parallel)
  +-- api-contract-validator → spec vs implementation drift
  +-- reviewer               → code quality
       |
Phase 4: Integration Testing (sequential)
  integration-tester → E2E API tests (worktree)
       |
Phase 5: Documentation (sequential)
  doc-writer → API reference docs (worktree)
```

## Phase 1: API Design

```
Agent(
  prompt: "Design API:
    Requirements: {api_description}
    - RESTful resource design (or GraphQL schema)
    - OpenAPI 3.0 spec generation
    - Error response standards (RFC 7807)
    - Versioning strategy
    - Rate limiting / pagination
    - Authentication/authorization requirements
    Project: {project_root}",
  name: "api-design",
  subagent_type: "api-designer"
)
```

User approval of spec before implementation.

## Phase 2: Implementation

```
Agent(
  prompt: "Implement API from spec:
    Spec: {openapi_spec}
    - Controllers / route handlers
    - Request/response validators (Zod)
    - Middleware (auth, rate-limit, error handling)
    - Repository integration
    - Build order: validators → middleware → routes → controllers
    Project: {project_root}",
  name: "api-impl",
  subagent_type: "api-developer",
  isolation: "worktree"
)
```

## Phase 3: Validation (2 agents parallel)

```
Agent(name: "validate-contract", subagent_type: "api-contract-validator", run_in_background: true)
  → "Check API implementation matches OpenAPI spec: {spec} vs {implementation}"

Agent(name: "validate-quality", subagent_type: "reviewer", run_in_background: true)
  → "Review API implementation quality: {diff}"
```

## Phase 4: Integration Testing

```
Agent(
  prompt: "Write API integration tests:
    Spec: {openapi_spec}
    - Test every endpoint (happy path + error cases)
    - Request/response validation
    - Auth flow testing
    - Pagination/filtering tests
    Project: {project_root}",
  name: "api-tests",
  subagent_type: "integration-tester",
  isolation: "worktree"
)
```

## Phase 5: Report

```markdown
## API Complete

### Endpoints: {list}
### Spec: {openapi spec location}
### Contract Valid: YES/NO
### Tests: {n} passing
### Docs: {location}
### Ready to commit? → user approval
```

## Rules

- OpenAPI spec BEFORE implementation
- Zod validators for all request/response
- Error responses follow RFC 7807
- Contract validation mandatory before merge
- Integration tests cover every endpoint
- API versioning strategy documented
