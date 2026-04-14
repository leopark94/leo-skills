#!/bin/zsh
# rule-id: no-sql-join
# Block SQL JOIN in .ts / .sql. App-level merge only (MASTER.md §7.4).
# 3-pass: strip comments → strip quoted strings (NOT template literals) → detect SQL JOIN patterns.

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
    *.ts|*.tsx|*.js|*.jsx|*.sql) ;;
    *) exit 0 ;;
esac

case "$FILE_PATH" in
    */migrations/*) exit 0 ;;
    */seed/*|*/seeds/*) exit 0 ;;
    */drizzle/*|*/prisma/migrations/*) exit 0 ;;
esac

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')
[[ -z "$CONTENT" ]] && exit 0

# 3-pass analysis via python3: strip comments → strip quoted strings (not template literals) → detect SQL JOIN
HIT=$(printf '%s' "$CONTENT" | python3 -c '
import sys, re
text = sys.stdin.read()
text = re.sub(r"/\*[\s\S]*?\*/", "", text)
text = re.sub(r"//[^\n]*", "", text)

def strip_regular_strings(s):
    out = []
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c == "\"" or c == "'"'"'":
            quote = c
            i += 1
            while i < n:
                if s[i] == "\\" and i + 1 < n:
                    i += 2
                    continue
                if s[i] == quote:
                    i += 1
                    break
                i += 1
            out.append(" ")
        else:
            out.append(c)
            i += 1
    return "".join(out)

text = strip_regular_strings(text)

patterns = [
    r"\bINNER\s+JOIN\b",
    r"\bLEFT\s+(OUTER\s+)?JOIN\b",
    r"\bRIGHT\s+(OUTER\s+)?JOIN\b",
    r"\bFULL\s+(OUTER\s+)?JOIN\b",
    r"\bCROSS\s+JOIN\b",
    r"\bJOIN\s+\w+\s+ON\b",
]
for p in patterns:
    if re.search(p, text, re.IGNORECASE):
        print("HIT")
        sys.exit(0)
print("")
' 2>/dev/null)

if [[ "$HIT" == "HIT" ]]; then
    cat <<EOF >&2
BLOCKED: SQL JOIN detected in ${FILE_PATH}
Per MASTER.md rule-id: no-sql-join — use single-table queries + app-level merge.
Allowlist: **/migrations/**, **/seed/**, **/drizzle/**, **/prisma/migrations/**
EOF
    exit 2
fi

exit 0
