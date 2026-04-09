#!/bin/zsh
# compact-reinject.sh — SessionStart(compact) hook: re-inject core context after compaction
# Anthropic blog recommended: critical rules vanish after compaction, so re-inject them

cat <<'CONTEXT'
## Leo Project Core Rules (compaction re-injection)

1. Secrets -> `leo secret add <name>` (NEVER hard-code in source)
2. Logging: pino (TS), log_* (zsh). console.log forbidden
3. Config: config.getSettings() access. No hard-coded values
4. Errors: withRetry() wrapper. Error suppression forbidden
5. Git: Conventional Commits. SemVer version updates per feature
6. Testing: Always verify build after changes (`npm run build`)
7. Service ports: leo-bot(3848), leo-secretary(3849), slack(3847)
8. Reference: MASTER.md (/Users/leo/utils/leo-skills/MASTER.md)

## IMPORTANT: Team-First Principle (never forget)

- /sprint, /review, /investigate default to team mode
- Deploy specialist agents (architect, reviewer, type-analyzer, test-analyzer, error-hunter, simplifier, security-auditor) in parallel as needed
- Solo mode only via explicit opt-out: --light, --quick, --serial
- /review enforced before commit (marker auto-created after 3+ edits)

## IMPORTANT: Agent Enforcement (agent-guard.sh active)

- NEVER use generic/general-purpose agents — BLOCKED by hook
- Every Agent call MUST use subagent_type from ~/utils/leo-skills/agents/
- No matching agent? CREATE one at agents/<name>.md first, then use it
- Parallel work: TeamCreate (native teammates), NEVER tmux

## IMPORTANT: Documentation Discipline (작업 전후 필수)

BEFORE: gh issue create → 진행상황 확인 → 계획 문서화 → ADR
AFTER: 이슈 결과 코멘트 → close → progress 업데이트 → 문서 반영 → 커밋에 이슈번호
CONTEXT
