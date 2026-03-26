#!/bin/zsh
# notify.sh — Notification 훅: Claude가 사용자 응답 대기 시 macOS 알림
# 터미널을 계속 보지 않아도 됨

INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
BODY=$(echo "$INPUT" | jq -r '.body // "작업 완료 — 확인 필요"')

# macOS 네이티브 알림
osascript -e "display notification \"$BODY\" with title \"$TITLE\" sound name \"Submarine\"" 2>/dev/null || true

exit 0
