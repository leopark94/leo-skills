#!/bin/zsh
# rule-id: no-console-log
# Block console.log/debug/info/warn in .ts/.tsx/.js/.jsx. Allowlist: loggers, tests.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL_NAME" in
    Edit|Write|MultiEdit) ;;
    *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx) ;;
    *) exit 0 ;;
esac

case "$FILE_PATH" in
    */packages/shared/logger/*) exit 0 ;;
    */logger.ts|*/logger*.ts) exit 0 ;;
    *.test.ts|*.test.tsx|*.test.js|*.test.jsx) exit 0 ;;
    *.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx) exit 0 ;;
    */scripts/*) exit 0 ;;
esac

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')
[[ -z "$CONTENT" ]] && exit 0

# Python: strip // and /* */ comments, then check console.(log|debug|info|warn)
HIT=$(printf '%s' "$CONTENT" | python3 -c '
import sys, re
text = sys.stdin.read()
text = re.sub(r"/\*[\s\S]*?\*/", "", text)
text = re.sub(r"//[^\n]*", "", text)
m = re.search(r"\bconsole\.(log|debug|info|warn)\b", text)
print("HIT" if m else "")
' 2>/dev/null)

if [[ "$HIT" == "HIT" ]]; then
    cat <<EOF >&2
BLOCKED: console.{log,debug,info,warn} detected in ${FILE_PATH}
Use @leo/shared logger (pino). See MASTER.md rule-id: no-console-log.
Allowlist: packages/shared/logger/**, **/logger*.ts, **/*.test.ts, **/*.spec.ts, **/scripts/**
EOF
    exit 2
fi

exit 0
