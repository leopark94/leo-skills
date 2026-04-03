#!/bin/zsh
# stop-loop-guard.sh — Stop hook: infinite loop prevention
# If stop_hook_active is true, exit immediately to break the loop

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // "false"')

if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Normal stop — notify user
osascript -e 'display notification "Claude Code session ended" with title "Claude Code" sound name "Submarine"' 2>/dev/null || true

exit 0
