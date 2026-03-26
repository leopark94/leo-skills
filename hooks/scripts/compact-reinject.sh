#!/bin/zsh
# compact-reinject.sh — SessionStart(compact) 훅: 컨텍스트 압축 후 핵심 정보 재주입
# Anthropic 블로그 권장: compaction 후 중요한 규칙들이 사라지므로 재주입 필요

cat <<'CONTEXT'
## Leo 프로젝트 핵심 규칙 (compaction 재주입)

1. 민감정보 → `leo secret add <name>` (절대 코드에 하드코딩 금지)
2. 로깅: pino (TS), log_* (zsh). console.log 금지
3. 설정: config.getSettings() 접근. 하드코딩 금지
4. 에러: withRetry() 래퍼. 에러 무시 금지
5. Git: Conventional Commits. 기능별 버전 업데이트 (SemVer)
6. 테스트: 변경 후 반드시 빌드 확인 (`npm run build`)
7. 서비스 포트: leo-bot(3848), leo-secretary(3849), slack(3847)
8. 팀 작업 시 MASTER.md (/Users/leo/utils/leo-skills/MASTER.md) 참조 확인
CONTEXT
