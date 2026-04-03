#!/bin/zsh
# session-checklist.sh — SessionStart(startup|resume) hook: session start checklist

# Detect current project
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
PROJECT_NAME=$(basename "$PROJECT_ROOT")

cat <<CONTEXT
## Session Start Checklist

- Project: $PROJECT_NAME ($PROJECT_ROOT)
- Master reference: ~/utils/leo-skills/MASTER.md
- Secrets must use \`leo secret\` (leo-cli Keychain)
- Check CLAUDE.md and MASTER.md before starting work

## IMPORTANT: Team-First Principle

All tasks default to agent team deployment:
- /sprint -> STANDARD mode (architect + verification team + simplifier)
- /review -> STANDARD mode (reviewer + specialist agents in parallel)
- /investigate -> PARALLEL mode (per-hypothesis agent verification)
- Solo mode only via explicit opt-out: --light, --quick, --serial flags
- After 3+ edits, /review is enforced before commit (pre-commit-guard hook)
CONTEXT

# Check CLAUDE.md exists for leo-* projects
if [[ "$PROJECT_NAME" == leo-* ]] && [[ ! -f "$PROJECT_ROOT/CLAUDE.md" ]]; then
  echo "WARNING: CLAUDE.md not found — recommend creating one based on leo-skills/MASTER.md patterns"
fi

# Check for leftover review markers from previous session
if [[ -f "$PROJECT_ROOT/.claude-needs-review" ]]; then
  EDIT_COUNT=$(cat "$PROJECT_ROOT/.claude-needs-review" 2>/dev/null || echo "?")
  echo "WARNING: Review marker found from previous session (${EDIT_COUNT} edits). Run /review or delete the marker."
fi

# Secret check: uses leo-cli's leo secret (Keychain service="leo-cli")
if command -v leo &>/dev/null; then
  MANIFEST="$PROJECT_ROOT/.leo-secrets.yaml"
  if [[ -f "$MANIFEST" ]]; then
    MISSING=0
    while IFS= read -r line; do
      SECRET_NAME=$(echo "$line" | sed 's/.*name: *//;s/ *$//')
      [[ -z "$SECRET_NAME" ]] && continue
      REQUIRED=$(grep -A2 "name: *${SECRET_NAME}" "$MANIFEST" | grep "required:" | grep -q "true" && echo "true" || echo "false")
      if [[ "$REQUIRED" == "true" ]]; then
        # leo-cli Keychain: internet-password (Apple Passwords) or generic fallback
        if ! security find-internet-password -s "leo-cli" -a "${SECRET_NAME}" -w >/dev/null 2>&1 && \
           ! security find-generic-password -s "leo-cli" -a "leo-cli-${SECRET_NAME}" -w >/dev/null 2>&1; then
          MISSING=$((MISSING + 1))
        fi
      fi
    done < <(grep "name:" "$MANIFEST" | grep -v "^#" | grep -v "^secrets:")
    if [[ $MISSING -gt 0 ]]; then
      echo "WARNING: ${MISSING} required secret(s) missing! Run \`leo secret check\` to verify."
    fi
  fi
fi
