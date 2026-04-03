# Leo Master Skills

Master agent/skill/hook reference system for Claude Code.

Comprehensive integration of Anthropic Engineering blog patterns + community best practices + leo-* project learnings into a universal Claude Code configuration.

## Installation

```bash
cd ~/utils/leo-skills
./scripts/install.sh
```

## Secret Management

Secrets are managed via **leo-cli's `leo secret`** command (not included in this project).

```bash
leo secret add OPENAI_API_KEY      # Store in Keychain
leo secret get OPENAI_API_KEY      # Retrieve
leo secret check                   # Check missing per .leo-secrets.yaml manifest
leo secret sync push               # Cross-device sync
```

The session start hook auto-checks `.leo-secrets.yaml` manifest and warns on missing secrets.

## Components

### Hooks (9)

| Event | Hook | Description |
|-------|------|-------------|
| SessionStart(startup\|resume) | session-checklist | Session checklist + **team-first principle injection** |
| SessionStart(compact) | compact-reinject | Core rules + **team-first principle re-injection** |
| PreToolUse(Edit\|Write) | detect-secrets | Secret detection -> block -> `leo secret` guidance |
| PreToolUse(Edit\|Write) | protect-files | Block editing .env, lock files, .git |
| **PreToolUse(Bash)** | **pre-commit-guard** | **Detect git commit -> check review marker -> block if not reviewed** |
| PostToolUse(Edit\|Write) | auto-format | prettier/black/shfmt auto-formatting |
| **PostToolUse(Edit\|Write)** | **edit-tracker** | **Track edit count -> create review marker at 3+ edits** |
| Notification | notify | macOS notification (no need to watch terminal) |
| Stop | stop-loop-guard | Infinite loop prevention + exit notification |

### Agents (17)

#### Core Agents (harness/workflow)

| Agent | Model | Context | Description |
|-------|-------|---------|-------------|
| planner | opus | full | Feature spec -> detailed implementation plan (sprint decomposition) |
| evaluator | opus | full | Live testing + quality evaluation (skeptical perspective) |
| explorer | sonnet | fork | Rapid codebase exploration + summary |
| debugger | opus | full | Systematic bug diagnosis via competing hypotheses |
| reviewer | sonnet | fork | Quality/security/performance code review |

#### Specialist Agents (team building blocks)

| Agent | Model | Context | Description |
|-------|-------|---------|-------------|
| architect | opus | full | Existing pattern analysis -> concrete architecture blueprint |
| developer | opus | full | Production code implementation following TDD cycle |
| test-writer | opus | full | TDD Red phase — writes failing tests before implementation |
| type-analyzer | sonnet | fork | Type design: encapsulation, invariants, usefulness, enforcement |
| test-analyzer | sonnet | fork | Test coverage quality + missing case identification |
| error-hunter | sonnet | fork | Silent error, empty catch, dangerous fallback hunting |
| simplifier | sonnet | fork | Unnecessary complexity removal, readability improvement |
| security-auditor | opus | full | OWASP Top 10 systematic security audit |

#### Operations Agents

| Agent | Model | Context | Description |
|-------|-------|---------|-------------|
| pm | opus | full | Sprint planning, priority/risk management, progress tracking |
| release-coordinator | sonnet | full | Automated release: SemVer, CHANGELOG, tag, GitHub Release |
| incident-commander | opus | full | Production incident triage, RCA, runbook, postmortem |
| perf-monitor | sonnet | fork | Build time, memory, latency profiling |

### Skills (9)

#### Workflow Skills (automatic team scaling)

Auto-assess complexity and **deploy specialist agents as needed**.

| Skill | Modes | Description |
|-------|-------|-------------|
| `/sprint` | LIGHT / STANDARD / FULL | Feature implementation. Deploys architect, verification team (4-5 agents), simplifier based on complexity |
| `/review` | QUICK / STANDARD / DEEP | Code review. Selectively spawns specialist agents based on change scope (up to 5 parallel) |
| `/investigate` | SERIAL / PARALLEL | Bug diagnosis. Spawns per-hypothesis agents for complex bugs |

```
Example: /sprint "Add OAuth login"
-> Step 0 auto-determines: "STANDARD mode (2-3 sprints expected, auth-related)"
-> Architect -> implementation -> [reviewer + test-analyzer + error-hunter + security-auditor parallel] -> Simplifier
```

#### Explicit Team Skills (direct invocation)

For when you always want the full team without auto-assessment:

| Skill | Team Composition | Description |
|-------|-----------------|-------------|
| `/team-review` | 5 agents parallel | reviewer + type-analyzer + test-analyzer + error-hunter + security-auditor |
| `/team-feature` | Sequential+parallel hybrid | architect -> explorer -> implement -> [4 parallel verification] -> simplifier |
| `/team-debug` | Parallel hypothesis verification | explorer -> hypotheses -> [5 parallel verification] -> fix |

#### Utility Skills

| Skill | Description |
|-------|-------------|
| `/guard` | MASTER.md compliance checklist |
| `/progress` | JSON-based multi-session progress tracking |
| `/discover` | GitHub community skill search & install |

### Community Skill Registry (43+ repos)

`registry/REGISTRY.md` indexes 43+ GitHub repos of skills/agents/hooks.

```bash
# Search
./scripts/discover.sh search security

# Popular repos
./scripts/discover.sh popular

# Install from specific repo
./scripts/discover.sh install trailofbits/skills

# Update registry
./scripts/discover.sh update
```

## Reference Sources

- [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Building a C Compiler with Parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler)
- [Claude Code Auto Mode](https://www.anthropic.com/engineering/claude-code-auto-mode)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [The "think" Tool](https://www.anthropic.com/engineering/claude-think-tool)
- [Writing Effective Tools for Agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
- 30 Tips for Claude Code Agent Teams (Reddit/Substack)
- Awesome Claude Code (GitHub)

## Update

```bash
./scripts/sync.sh  # git pull + reinstall
```

## Uninstall

```bash
./scripts/uninstall.sh
```
