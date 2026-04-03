#!/bin/zsh
# pre-commit-guard.sh — PreToolUse(Bash) 훅: git commit 감지 시 리뷰 강제
# .claude-needs-review 마커가 있으면 커밋 차단

INPUT=$(cat)

# Bash 명령어에서 git commit 감지
COMMAND=$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

# git commit 패턴 매칭 (git commit, git commit -m, etc.)
if ! echo "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  exit 0
fi

# 프로젝트 루트
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
MARKER="$PROJECT_ROOT/.claude-needs-review"

if [[ -f "$MARKER" ]]; then
  EDIT_COUNT=$(cat "$MARKER" 2>/dev/null || echo "?")
  cat <<BLOCK
🚫 COMMIT BLOCKED — 팀 리뷰 미완료

${EDIT_COUNT}회 이상 편집 후 /review가 실행되지 않았습니다.

다음 중 하나를 실행하세요:
  1. /review          — 팀 리뷰 실행 (권장, STANDARD 모드 자동)
  2. /review --quick  — 빠른 리뷰 (간단한 변경만)

리뷰 완료 후 자동으로 마커가 제거되며 커밋이 가능합니다.

마커 위치: $MARKER
BLOCK
  exit 2
fi

exit 0
