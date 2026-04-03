#!/bin/zsh
# edit-tracker.sh — PostToolUse(Edit|Write) hook: track edit count + create review marker
# Accumulates edits and creates .claude-needs-review marker to enforce review before commit

INPUT=$(cat)

# Find project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
MARKER="$PROJECT_ROOT/.claude-needs-review"
COUNTER="$PROJECT_ROOT/.claude-edit-count"

# Increment edit counter
if [[ -f "$COUNTER" ]]; then
  COUNT=$(cat "$COUNTER")
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi
echo "$COUNT" > "$COUNTER"

# Create review marker at 3+ edits
if [[ $COUNT -ge 3 ]] && [[ ! -f "$MARKER" ]]; then
  echo "$COUNT" > "$MARKER"
  echo "Review needed: ${COUNT} edits accumulated — run /review before committing (marker created)"
fi

# Strong reminder at 10+ edits (every 5)
if [[ $COUNT -ge 10 ]] && [[ $((COUNT % 5)) -eq 0 ]]; then
  echo "WARNING: ${COUNT} edits accumulated without verification. Strongly recommend running /review."
fi

exit 0
