#!/bin/zsh
# dangerous-command-guard.sh — PreToolUse(Bash) hook: block destructive commands
# Blocks rm -rf /, git push --force, git reset --hard, DROP TABLE, etc.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# === BLOCK: Clearly destructive commands ===

# rm -rf with dangerous targets (/, ~, ., .., $HOME, entire project roots)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|--force\s+)*(\/|~|\$HOME|\.\.?)\s*$'; then
  echo "BLOCKED: Destructive rm detected — '$COMMAND'"
  echo "-> Specify a safe, scoped target path instead."
  exit 2
fi

# git push --force to main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(main|master)' || \
   echo "$COMMAND" | grep -qE 'git\s+push\s+-f\s+.*\s+(main|master)'; then
  echo "BLOCKED: Force push to main/master — '$COMMAND'"
  echo "-> Force pushing to main/master can destroy shared history. Use a feature branch."
  exit 2
fi

# git reset --hard (without stash/backup)
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "BLOCKED: git reset --hard — '$COMMAND'"
  echo "-> This discards all uncommitted changes. Use 'git stash' first, or specify a safe ref."
  exit 2
fi

# git checkout . / git restore . (discard all changes)
if echo "$COMMAND" | grep -qE 'git\s+(checkout|restore)\s+\.\s*$'; then
  echo "BLOCKED: Discard all changes — '$COMMAND'"
  echo "-> This removes all uncommitted work. Specify individual files instead."
  exit 2
fi

# git clean -f (delete untracked files)
if echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
  echo "BLOCKED: git clean -f — '$COMMAND'"
  echo "-> This permanently deletes untracked files. Use 'git clean -n' (dry run) first."
  exit 2
fi

# SQL destructive operations
if echo "$COMMAND" | grep -qiE '(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX)|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\S+\s*$|DELETE\s+FROM\s+\S+\s*;)'; then
  echo "BLOCKED: Destructive SQL detected — '$COMMAND'"
  echo "-> Use migrations for schema changes. Never drop/truncate directly."
  exit 2
fi

# kill -9 (ungraceful process kill)
if echo "$COMMAND" | grep -qE 'kill\s+-9\s'; then
  echo "BLOCKED: kill -9 (SIGKILL) — '$COMMAND'"
  echo "-> Try 'kill -15' (SIGTERM) for graceful shutdown first."
  exit 2
fi

# Disk-level destructive (mkfs, dd)
if echo "$COMMAND" | grep -qE '(mkfs\.|dd\s+if=)'; then
  echo "BLOCKED: Disk-level destructive command — '$COMMAND'"
  exit 2
fi

# chmod -R 777
if echo "$COMMAND" | grep -qE 'chmod\s+(-R\s+)?777'; then
  echo "BLOCKED: chmod 777 — '$COMMAND'"
  echo "-> World-writable permissions are a security risk. Use specific permissions."
  exit 2
fi

# Fork bomb
if echo "$COMMAND" | grep -qF '(){'; then
  echo "BLOCKED: Potential fork bomb detected — '$COMMAND'"
  exit 2
fi

exit 0
