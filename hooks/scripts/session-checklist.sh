#!/bin/zsh
# session-checklist.sh — SessionStart(startup|resume) 훅: 세션 시작 시 체크리스트
# Anthropic 권장 세션 시작 패턴 구현

# 현재 프로젝트 감지
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
PROJECT_NAME=$(basename "$PROJECT_ROOT")

cat <<CONTEXT
## 세션 시작 체크리스트

- 프로젝트: $PROJECT_NAME ($PROJECT_ROOT)
- 마스터 참조: ~/utils/leo-skills/MASTER.md
- 민감정보는 반드시 \`leo secret\` 사용
- 작업 전 CLAUDE.md 및 MASTER.md 기반 확인 필요

## IMPORTANT: 팀 퍼스트 원칙

모든 작업에서 에이전트 팀을 기본으로 투입합니다:
- /sprint → STANDARD 모드 (architect + 검증팀 + simplifier)
- /review → STANDARD 모드 (reviewer + 전문 에이전트 병렬)
- /investigate → PARALLEL 모드 (가설별 에이전트 병렬)
- 솔로 모드는 --light, --quick, --serial 플래그로 명시적 opt-out만 가능
- 편집 3회+ 누적 시 커밋 전 /review 강제 (pre-commit-guard 훅)
CONTEXT

# leo-* 프로젝트면 CLAUDE.md 존재 확인
if [[ "$PROJECT_NAME" == leo-* ]] && [[ ! -f "$PROJECT_ROOT/CLAUDE.md" ]]; then
  echo "⚠️ CLAUDE.md 없음 — 'leo-skills/MASTER.md' 패턴으로 생성 권장"
fi

# 이전 세션 마커 잔여 확인
if [[ -f "$PROJECT_ROOT/.claude-needs-review" ]]; then
  EDIT_COUNT=$(cat "$PROJECT_ROOT/.claude-needs-review" 2>/dev/null || echo "?")
  echo "⚠️ 이전 세션에서 리뷰 마커 발견 (편집 ${EDIT_COUNT}회). /review 실행 또는 마커 삭제 필요."
fi
