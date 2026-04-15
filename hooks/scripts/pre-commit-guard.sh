#!/bin/zsh
# rule-id: tdd-required
# pre-commit-guard.sh — PreToolUse(Bash) hook: block git commit when review is pending
# Blocks commit if .claude-needs-review marker exists

INPUT=$(cat)

# Detect git commit in Bash command (handle both input formats)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null)
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

# === TDD Guard: require test files when source files are staged ===
SCRIPT_DIR="${0:A:h}"
if [[ -f "$SCRIPT_DIR/_config.sh" ]]; then
  source "$SCRIPT_DIR/_config.sh"

  if leo_config_enabled "tdd-guard.enabled" && leo_config_enabled "tdd-guard.require-tests-for-commit"; then
    # Check staged files for source changes (non-test, non-config)
    STAGED=$(git diff --cached --name-only 2>/dev/null || true)
    HAS_SOURCE=false
    HAS_TESTS=false

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      # Skip config/doc files
      if echo "$file" | grep -qE '\.(md|json|yaml|yml)$|\.gitignore|CLAUDE\.md'; then
        continue
      fi
      # Check if it's a test file
      if echo "$file" | grep -qE '\.(test|spec)\.|__tests__/'; then
        HAS_TESTS=true
      else
        HAS_SOURCE=true
      fi
    done <<< "$STAGED"

    if [[ "$HAS_SOURCE" == "true" ]] && [[ "$HAS_TESTS" == "false" ]]; then
      cat <<BLOCK
COMMIT BLOCKED — TDD required: no test files in staged changes

Source files are staged but no test files detected.
TDD is mandatory: write tests before or alongside source changes.

Options:
  1. Add test files to the commit
  2. Run /test to generate tests for your changes
  3. Disable tdd-guard in .leo-hooks.yaml (not recommended)
BLOCK
      exit 2
    fi
  fi
fi

# === Issue Reference Guard: commit message must contain issue number ===
# The full command contains the commit message — check the entire command string
COMMIT_MSG="$COMMAND"

# If we can extract the message, check for issue reference
if [[ -n "$COMMIT_MSG" ]]; then
  # Check for #N pattern (issue reference)
  if ! echo "$COMMIT_MSG" | grep -qE '#[0-9]+'; then
    # Allow certain commit types without issue reference
    if ! echo "$COMMIT_MSG" | grep -qE '(chore|docs|style|ci|build|initial):'; then
      cat <<BLOCK
COMMIT BLOCKED — Issue reference required

Commit message must include a GitHub issue number (e.g., #123).
Format: "feat: implement login (#42)"

If no issue exists yet, run:
  /issue create "description"

Exempt commit types (no issue needed): chore, docs, style, ci, build, initial
BLOCK
      exit 2
    fi
  fi
fi

exit 0
