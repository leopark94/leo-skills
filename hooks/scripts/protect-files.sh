#!/bin/zsh
# protect-files.sh — PreToolUse hook: block editing of protected files
# Prevents direct editing of lock files, .git/, credential files, etc.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only inspect Edit/Write
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

[[ -z "$FILE_PATH" ]] && exit 0

# Protected file patterns
PROTECTED_PATTERNS=(
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

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qE "$pattern"; then
    echo "BLOCKED: Direct editing of protected file forbidden ($FILE_PATH)"
    echo "-> Lock files: use package manager. .git: use git commands."
    exit 2
  fi
done

exit 0
