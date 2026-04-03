---
name: discover
description: "Searches and installs Claude Code community skills, agents, and hooks from GitHub"
disable-model-invocation: false
user-invocable: true
---

# /discover — Community Skill Search & Install

Searches and installs Claude Code skills, agents, and hooks from GitHub.
Checks the local registry (`registry/REGISTRY.md`) first, then falls back to live GitHub search.

## Usage

```
/discover                     # popular skill list
/discover <keyword>           # keyword search (security, planning, hooks, ...)
/discover install <repo>      # install skills from specific repo
/discover update              # update registry (latest GitHub search)
```

## Search Process

### 1. Local Registry Search
```bash
# Match keyword in registry/REGISTRY.md
grep -i "$KEYWORD" ~/utils/leo-skills/registry/REGISTRY.md
```

### 2. Live GitHub Search (when not found locally)
```bash
# Search skill repos via GitHub API
gh search repos "claude code $KEYWORD skills" --sort stars --limit 10 --json name,url,description,stargazersCount

# Or topic-based search
gh search repos --topic claude-code-skills --sort stars --limit 10
```

### 3. Installation
```bash
# Clone to temp directory
gh repo clone <owner>/<repo> /tmp/claude-skill-<repo>

# Check skill structure
ls /tmp/claude-skill-<repo>/skills/ 2>/dev/null
ls /tmp/claude-skill-<repo>/agents/ 2>/dev/null
ls /tmp/claude-skill-<repo>/hooks/ 2>/dev/null

# Selective copy (after user approval)
cp -r /tmp/claude-skill-<repo>/skills/<name> ~/.claude/skills/
cp -r /tmp/claude-skill-<repo>/agents/<name>.md ~/.claude/agents/
```

## Recommended Skills (ready to install)

### Essential
| Skill | Source | Reason |
|-------|--------|--------|
| planning-with-files | OthmanAdi | 17.2K stars, 96.7% benchmark |
| taskmaster | blader | Agent early termination prevention via Stop hook |
| prompt-improver | severity1 | Auto-improves ambiguous prompts |

### Security
| Skill | Source | Reason |
|-------|--------|--------|
| trailofbits/skills | Trail of Bits | Industry-leading security research lab's skill set |

### Development Workflow
| Skill | Source | Reason |
|-------|--------|--------|
| superpowers | obra | TDD-based autonomous development, hour-long autonomous runs |
| context-engineering-kit | NeoLabHQ | Spec-Driven Development |

## Rules

- Check README before installing (security review)
- Review hook script contents before installing hooks
- Check for skill name conflicts
- Record installations in REGISTRY.md
