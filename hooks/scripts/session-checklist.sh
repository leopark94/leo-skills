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

## IMPORTANT: Agent Enforcement (agent-guard.sh active)

- NEVER use generic/general-purpose agents — BLOCKED by hook
- Every Agent call MUST use subagent_type from ~/utils/leo-skills/agents/
- If no agent exists for a task: CREATE one at agents/<name>.md first, then use it
- For parallel work: use TeamCreate (native teammates), NEVER tmux
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

# Frontend project check: DS + skeleton validation
SCRIPT_DIR="${0:A:h}"
if [[ -f "$SCRIPT_DIR/_config.sh" ]]; then
  source "$SCRIPT_DIR/_config.sh"

  if leo_config_enabled "frontend-guard.enabled"; then
    DS_PATH=$(leo_config_get "frontend-guard.design-system.path" "")
    if [[ -n "$DS_PATH" ]] && [[ ! -d "$PROJECT_ROOT/$DS_PATH" ]]; then
      echo "WARNING: Design system directory not found ($DS_PATH). Create it or update .leo-hooks.yaml"
    fi

    REQUIRED_DIRS=$(leo_config_get_array "frontend-guard.skeleton.required-dirs")
    if [[ -n "$REQUIRED_DIRS" ]]; then
      while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
          echo "WARNING: Required directory missing: $dir"
        fi
      done <<< "$REQUIRED_DIRS"
    fi

    echo "Frontend project detected — DS guard active, check .leo-hooks.yaml for rules"
  fi

  if leo_config_enabled "tdd-guard.enabled"; then
    echo "TDD enforced — tests required for every commit"
  fi
fi
