#!/bin/zsh
# protect-files.sh — PreToolUse 훅: 보호 파일 편집 차단
# package-lock.json, .git/, 인증 파일 등 직접 편집 방지

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Edit/Write만 검사
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

[[ -z "$FILE_PATH" ]] && exit 0

# 보호 대상 패턴
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
    echo "BLOCKED: 보호 파일 직접 편집 금지 ($FILE_PATH)"
    echo "→ lock 파일은 패키지 매니저로, .git은 git 명령어로 관리"
    exit 2
  fi
done

exit 0
