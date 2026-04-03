#!/bin/zsh
# notify.sh — Notification hook: macOS notification when Claude awaits user response
# No need to keep watching the terminal

INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
BODY=$(echo "$INPUT" | jq -r '.body // "Task complete — action required"')

# macOS native notification
osascript -e "display notification \"$BODY\" with title \"$TITLE\" sound name \"Submarine\"" 2>/dev/null || true

exit 0
