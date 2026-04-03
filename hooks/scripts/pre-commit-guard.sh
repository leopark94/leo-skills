#!/bin/zsh
# pre-commit-guard.sh — PreToolUse(Bash) hook: block git commit when review is pending
# Blocks commit if .claude-needs-review marker exists

INPUT=$(cat)

# Detect git commit in Bash command
COMMAND=$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

# Match git commit pattern (git commit, git commit -m, etc.)
if ! echo "$COMMAND" | grep -qE '^\s*git\s+commit'; then
  exit 0
fi

# Find project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
MARKER="$PROJECT_ROOT/.claude-needs-review"

if [[ -f "$MARKER" ]]; then
  EDIT_COUNT=$(cat "$MARKER" 2>/dev/null || echo "?")
  cat <<BLOCK
COMMIT BLOCKED — Team review not completed

${EDIT_COUNT}+ edits detected without running /review.

Please run one of the following:
  1. /review          — Team review (recommended, STANDARD mode auto-selected)
  2. /review --quick  — Quick review (for simple changes only)

The marker will be removed after review, and commit will be allowed.

Marker location: $MARKER
BLOCK
  exit 2
fi

exit 0
