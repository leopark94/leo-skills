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
CONTEXT

# leo-* 프로젝트면 CLAUDE.md 존재 확인
if [[ "$PROJECT_NAME" == leo-* ]] && [[ ! -f "$PROJECT_ROOT/CLAUDE.md" ]]; then
  echo "⚠️ CLAUDE.md 없음 — 'leo-skills/MASTER.md' 패턴으로 생성 권장"
fi
