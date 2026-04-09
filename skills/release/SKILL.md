---
name: release
description: "Automated release — Conventional Commits analysis, SemVer, CHANGELOG, tag, GitHub Release"
disable-model-invocation: false
user-invocable: true
---

# /release — Automated Release Pipeline

Analyzes Conventional Commits, determines SemVer bump, generates CHANGELOG, tags, and creates GitHub Release.

## Usage

```
/release                    # auto-detect version bump
/release --major            # force major bump
/release --minor            # force minor bump
/release --patch            # force patch bump
/release --dry-run          # preview release without executing
```

## Issue Tracking

Before any work, create a GitHub issue:
```bash
gh issue create --title "Release: v{version}" --body "Release tracking issue" --label "release"
```
All agents comment progress to this issue. Close on completion.

## Team Composition & Flow

```
Phase 1: Analysis (sequential)
  release-coordinator → commit analysis + SemVer determination
       |
Phase 2: Review (sequential)
  reviewer → CHANGELOG + release notes review
       |
Phase 3: Execute (sequential)
  git-master → version bump, tag, push
       |
Phase 4: Publish
  GitHub Release creation
```

## Phase 1: Release Analysis

```
Agent(
  prompt: "Analyze commits for release:
    - Parse Conventional Commits since last tag
    - Determine SemVer bump (major/minor/patch)
    - Generate CHANGELOG entries
    - Draft release notes (user-facing)
    - List breaking changes (if any)
    Project: {project_root}",
  name: "release-analysis",
  subagent_type: "release-coordinator"
)
```

Show analysis to user. **Wait for approval.**

## Phase 2: Review

```
Agent(
  prompt: "Review release artifacts:
    Analysis: {release_output}
    - CHANGELOG accuracy
    - Release notes clarity
    - Breaking changes documented
    - Version number correct
    Project: {project_root}",
  name: "release-review",
  subagent_type: "reviewer"
)
```

## Phase 3: Execute

After user approval:
```
Agent(
  prompt: "Execute release:
    Version: {version}
    CHANGELOG: {changelog}
    - Update version in package.json / pyproject.toml / etc.
    - Update CHANGELOG.md
    - Create git tag v{version}
    - Push tag to remote
    Project: {project_root}",
  name: "release-exec",
  subagent_type: "git-master",
  isolation: "worktree"
)
```

## Phase 4: Report

```markdown
## Release Complete

### Version: v{version} ({major|minor|patch})
### Commits Included: {n}
### Breaking Changes: {list or NONE}
### CHANGELOG: Updated
### Tag: v{version} pushed
### GitHub Release: {url}
```

## Rules

- Conventional Commits required — reject if commit history is non-standard
- Breaking changes → major bump (unless pre-1.0)
- User approval before tagging
- --dry-run shows everything but executes nothing
- Always create GitHub issue for tracking
