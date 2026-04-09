# Leo Master Skills

Claude Code master agent/skill/hook reference system.
All leo-* projects should reference this repo.

## Structure

```
leo-skills/
├── CLAUDE.md           # This file
├── MASTER.md           # Master reference (Anthropic patterns + community best practices)
├── hooks/              # Universal hook configuration
│   ├── hooks.json      # Global hook definitions
│   └── scripts/        # Hook execution scripts
├── agents/             # Universal agent definitions
├── skills/             # Universal skill definitions
├── scripts/            # Utility scripts
└── docs/               # Detailed documentation
```

## Commands

```bash
./scripts/install.sh    # Register hooks/agents in global settings
./scripts/sync.sh       # Re-sync on updates
```

## Rules

- Keep CLAUDE.md concise (this file as reference)
- Use `leo secret` when secrets are detected (never hard-code)
- Hooks must be tested before registration
- Update MASTER.md when adding agents/skills

## IMPORTANT: Agent Enforcement (YOU MUST follow)

1. **NEVER use generic/general-purpose agents.** Every `Agent` tool call MUST specify `subagent_type` matching a definition in `agents/` directory.
2. **If no matching agent exists** for a task, CREATE a new agent definition at `agents/<name>.md` first, then use it via `subagent_type`.
3. **54 specialized agents available** — always pick the closest match before creating new ones.
4. **agent-guard.sh hook enforces this** — generic Agent calls will be BLOCKED at runtime.
5. **For parallel work, use TeamCreate** (native teammates), prefer over tmux. Team leader spawns and manages teammates via separate terminal instances.
6. **File-modifying agents MUST use `isolation: "worktree"`** — always work on isolated copy. Read-only agents (explorer, reviewer, analyzer, etc.) don't need worktree.
7. **Before spawning write agents, ensure latest code** — `git pull` on main branch before creating worktrees.
8. **모든 작업은 GitHub 이슈부터** — 스킬 실행 전 `gh issue create`로 이슈 생성, 에이전트들은 진행상황을 이슈 코멘트로 트래킹. 완료 시 이슈 close.
9. **TDD 필수** — 소스 코드 커밋 시 테스트 파일 없으면 pre-commit-guard가 차단.
10. **프론트엔드 프로젝트** → `.leo-hooks.yaml`에서 `frontend-guard`, `ds-guard` 활성화.
11. **테라폼 프로젝트** → `.leo-hooks.yaml`에서 `terraform-guard` 활성화.
