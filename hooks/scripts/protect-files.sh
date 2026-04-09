#!/bin/zsh
# protect-files.sh — PreToolUse hook: block editing of protected files
# Prevents direct editing of lock files, .git/, credential files, etc.
# Config: protect-files section in .leo-hooks.yaml

set -euo pipefail

# --- Config loader ---
_SCRIPT_DIR="${0:A:h}"
if [[ -f "$_SCRIPT_DIR/_config.sh" ]]; then
  source "$_SCRIPT_DIR/_config.sh"
else
  # No config loader — define stubs so script still works
  leo_config_get()     { echo "${2:-}"; }
  leo_config_get_array() { echo "${2:-}"; }
  leo_config_enabled() { [[ "${2:-true}" == "true" ]]; }
fi

# --- Enabled check (default: true) ---
_ENABLED=$(leo_config_get "protect-files.enabled" "true")
if [[ "$_ENABLED" == "false" ]]; then
  exit 0
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only inspect Edit/Write
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

[[ -z "$FILE_PATH" ]] && exit 0

# --- Hardcoded fallback patterns ---
FALLBACK_PATTERNS=(
  '\.git/'
  'package-lock\.json$'
  'pnpm-lock\.yaml$'
  'yarn\.lock$'
  'Podfile\.lock$'
  '\.DS_Store$'
  'node_modules/'
  '\.credentials'
  'serviceAccountKey'
)

# --- Build merged pattern list ---
PROTECTED_PATTERNS=()

# Read config patterns (one per line from leo_config_get_array)
_CONFIG_PATTERNS=$(leo_config_get_array "protect-files.patterns")
if [[ -n "$_CONFIG_PATTERNS" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && PROTECTED_PATTERNS+=("$line")
  done <<< "$_CONFIG_PATTERNS"
else
  # No config patterns — use hardcoded fallback
  PROTECTED_PATTERNS=("${FALLBACK_PATTERNS[@]}")
fi

# Read custom patterns (always merged on top)
_CUSTOM_PATTERNS=$(leo_config_get_array "protect-files.custom-patterns")
if [[ -n "$_CUSTOM_PATTERNS" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && PROTECTED_PATTERNS+=("$line")
  done <<< "$_CUSTOM_PATTERNS"
fi

# --- Check file against patterns ---
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qE "$pattern"; then
    echo "BLOCKED: Direct editing of protected file forbidden ($FILE_PATH)"
    echo "-> Lock files: use package manager. .git: use git commands."
    exit 2
  fi
done

exit 0
