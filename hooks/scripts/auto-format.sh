#!/bin/zsh
# auto-format.sh — PostToolUse 훅: 파일 편집 후 자동 포맷팅
# prettier, eslint --fix, black 등 프로젝트에 맞는 포맷터 실행

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Edit/Write만 대상
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# 파일 확장자 확인
EXT="${FILE_PATH##*.}"

# 프로젝트 루트 찾기
PROJECT_ROOT=$(cd "$(dirname "$FILE_PATH")" && git rev-parse --show-toplevel 2>/dev/null || echo "")

case "$EXT" in
  ts|tsx|js|jsx|json|css|scss|html|md|yaml|yml)
    # prettier 존재 시 실행
    if [[ -n "$PROJECT_ROOT" ]] && [[ -f "$PROJECT_ROOT/node_modules/.bin/prettier" ]]; then
      "$PROJECT_ROOT/node_modules/.bin/prettier" --write "$FILE_PATH" 2>/dev/null || true
    elif command -v prettier &>/dev/null; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  py)
    if command -v black &>/dev/null; then
      black --quiet "$FILE_PATH" 2>/dev/null || true
    elif command -v ruff &>/dev/null; then
      ruff format "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  sh|zsh|bash)
    if command -v shfmt &>/dev/null; then
      shfmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
