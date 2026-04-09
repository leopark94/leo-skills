---
name: docs
description: "Documentation generation — architect → doc-writer → reviewer pipeline"
disable-model-invocation: false
user-invocable: true
---

# /docs — Documentation Generation

Generates technical documentation from code analysis — API refs, architecture guides, and usage docs.

## Usage

```
/docs                          # auto-detect what needs docs
/docs <file or module>         # document specific target
/docs --api                    # API reference only
/docs --architecture           # architecture overview only
/docs --readme                 # generate/update README
```

## Issue Tracking

Before any work, create a GitHub issue:
```bash
gh issue create --title "docs: {target}" --body "Documentation generation tracking" --label "documentation"
```
All agents comment progress to this issue.

## Team Composition & Flow

```
Phase 1: Analysis (sequential)
  architect → code structure analysis + documentation plan
       |
Phase 2: Exploration (sequential)
  explorer → existing docs inventory + gap analysis
       |
Phase 3: Writing (sequential)
  doc-writer → generate documentation (worktree)
       |
Phase 4: Review (sequential)
  reviewer → accuracy + completeness check
```

## Phase 1: Code Analysis

```
Agent(
  prompt: "Analyze code for documentation:
    Target: {docs_target}
    - Map public APIs, types, interfaces
    - Identify architecture patterns
    - Note existing documentation (gaps + outdated)
    - Suggest documentation structure
    Project: {project_root}",
  name: "docs-architect",
  subagent_type: "architect"
)
```

## Phase 2: Gap Analysis

```
Agent(
  prompt: "Inventory existing documentation:
    Analysis: {architect_output}
    - Find all .md files, JSDoc, docstrings
    - Identify undocumented public APIs
    - Flag outdated documentation
    - Priority list for documentation work
    Project: {project_root}",
  name: "docs-explorer",
  subagent_type: "explorer"
)
```

## Phase 3: Write Documentation

```
Agent(
  prompt: "Generate documentation:
    Analysis: {architect_output}
    Gaps: {explorer_output}
    - API reference with examples
    - Architecture overview with diagrams (mermaid)
    - Usage guides for key workflows
    - Keep concise — no fluff
    Project: {project_root}",
  name: "docs-writer",
  subagent_type: "doc-writer",
  isolation: "worktree"
)
```

## Phase 4: Report

```markdown
## Documentation Complete

### Target: {what was documented}
### Files Created/Updated: {list}
### Coverage: {APIs documented / total APIs}
### Ready to commit? → user approval
```

## Rules

- Documentation must match actual code behavior
- Examples must be runnable
- No fluff — concise and actionable
- Mermaid diagrams for architecture
- Update existing docs before creating new ones
