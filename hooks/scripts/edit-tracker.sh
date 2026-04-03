#!/bin/zsh
# edit-tracker.sh — PostToolUse(Edit|Write) 훅: 편집 횟수 추적 + 검증 마커 생성
# 편집이 누적되면 .claude-needs-review 마커를 생성하여 커밋 전 리뷰 강제

INPUT=$(cat)

# 프로젝트 루트 찾기
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
MARKER="$PROJECT_ROOT/.claude-needs-review"
COUNTER="$PROJECT_ROOT/.claude-edit-count"

# 편집 카운터 증가
if [[ -f "$COUNTER" ]]; then
  COUNT=$(cat "$COUNTER")
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi
echo "$COUNT" > "$COUNTER"

# 3회 이상 편집 시 리뷰 마커 생성
if [[ $COUNT -ge 3 ]] && [[ ! -f "$MARKER" ]]; then
  echo "$COUNT" > "$MARKER"
  echo "📋 편집 ${COUNT}회 누적 — 커밋 전 /review 필요 (마커 생성됨)"
fi

# 10회 이상이면 강하게 리마인드
if [[ $COUNT -ge 10 ]] && [[ $((COUNT % 5)) -eq 0 ]]; then
  echo "⚠️ 편집 ${COUNT}회 누적 — 검증 없이 진행 중. /review 실행을 강력 권장합니다."
fi

exit 0
