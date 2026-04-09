#!/bin/zsh
# ds-guard.sh — PreToolUse hook: Design System rules enforcement
# Reads config from .leo-hooks.yaml (project root > global > default)
# Disabled by default — enable per-project via .leo-hooks.yaml

set -euo pipefail

# Load shared config
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/_config.sh"

# Check if ds-guard is enabled
if ! leo_config_enabled "ds-guard.enabled"; then
  exit 0
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Edit/Write only
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

# Get scope from config (e.g., 'screens-v2/')
DS_SCOPE=$(leo_config_get "ds-guard.scope" "")
if [[ -z "$DS_SCOPE" ]]; then
  exit 0
fi

# Only check files within scope
if ! echo "$FILE_PATH" | grep -q "$DS_SCOPE"; then
  exit 0
fi

# Check exclude patterns
EXCLUDES=$(leo_config_get_array "ds-guard.exclude-patterns")
if [[ -n "$EXCLUDES" ]]; then
  while IFS= read -r exclude; do
    [[ -z "$exclude" ]] && continue
    if echo "$FILE_PATH" | grep -qE "$exclude"; then
      exit 0
    fi
  done <<< "$EXCLUDES"
fi

[[ -z "$CONTENT" ]] && exit 0

ERRORS=""

# Rule: hardcoded-colors
if leo_config_enabled "ds-guard.rules.hardcoded-colors.enabled"; then
  COLOR_PATTERN=$(leo_config_get "ds-guard.rules.hardcoded-colors.pattern" "'#[0-9A-Fa-f]{3,8}'")
  COLOR_MSG=$(leo_config_get "ds-guard.rules.hardcoded-colors.message" "Use DS color tokens")
  HEX_MATCHES=$(echo "$CONTENT" | grep -oE "$COLOR_PATTERN" 2>/dev/null | head -3 || true)
  if [[ -n "$HEX_MATCHES" ]]; then
    ERRORS="${ERRORS}\n- Hardcoded color: ${HEX_MATCHES} -> ${COLOR_MSG}"
  fi
fi

# Rule: blocked-imports
if leo_config_enabled "ds-guard.rules.blocked-imports.enabled"; then
  BLOCKED_MSG=$(leo_config_get "ds-guard.rules.blocked-imports.message" "Use design system imports")
  BLOCKED_SOURCES=$(leo_config_get_array "ds-guard.rules.blocked-imports.sources")
  if [[ -n "$BLOCKED_SOURCES" ]]; then
    while IFS= read -r src; do
      [[ -z "$src" ]] && continue
      if echo "$CONTENT" | grep -q "from.*$src" 2>/dev/null; then
        ERRORS="${ERRORS}\n- Blocked import from $src -> ${BLOCKED_MSG}"
      fi
    done <<< "$BLOCKED_SOURCES"
  fi
fi

# Rule: blocked-utils
if leo_config_enabled "ds-guard.rules.blocked-utils.enabled"; then
  UTIL_MSG=$(leo_config_get "ds-guard.rules.blocked-utils.message" "Use DS utilities")
  BLOCKED_UTILS=$(leo_config_get_array "ds-guard.rules.blocked-utils.sources")
  if [[ -n "$BLOCKED_UTILS" ]]; then
    while IFS= read -r util; do
      [[ -z "$util" ]] && continue
      if echo "$CONTENT" | grep -q "from.*$util" 2>/dev/null; then
        ERRORS="${ERRORS}\n- Blocked utility import: $util -> ${UTIL_MSG}"
      fi
    done <<< "$BLOCKED_UTILS"
  fi
fi

# Rule: hardcoded-dimensions
if leo_config_enabled "ds-guard.rules.hardcoded-dimensions.enabled"; then
  DIM_PATTERN=$(leo_config_get "ds-guard.rules.hardcoded-dimensions.pattern" '(width|height|padding|margin|gap):\s*[0-9]{3,}')
  DIM_MSG=$(leo_config_get "ds-guard.rules.hardcoded-dimensions.message" "Use scale() or spacing tokens")
  HARDCODED=$(echo "$CONTENT" | grep -oE "$DIM_PATTERN" 2>/dev/null | head -3 || true)
  if [[ -n "$HARDCODED" ]]; then
    ERRORS="${ERRORS}\n- Hardcoded dimensions: ${HARDCODED} -> ${DIM_MSG}"
  fi
fi

# Report
if [[ -n "$ERRORS" ]]; then
  echo "DS Guard — design system rules violated:${ERRORS}"
  echo ""
  echo "Config: $_LEO_CONFIG (ds-guard section)"
  exit 2
fi

exit 0
