#!/bin/zsh
# stop-loop-guard.sh — Stop 훅: 무한 루프 방지
# stop_hook_active가 true이면 즉시 종료하여 루프 차단

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // "false"')

if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# 정상 Stop — 알림
osascript -e 'display notification "Claude Code 세션 종료" with title "Claude Code" sound name "Submarine"' 2>/dev/null || true

exit 0
