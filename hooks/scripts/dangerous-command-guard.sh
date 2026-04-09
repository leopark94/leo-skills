#!/bin/zsh
# dangerous-command-guard.sh — PreToolUse(Bash) hook: block destructive commands
# Reads block patterns from .leo-hooks.yaml config (dangerous-commands section)
# Falls back to hardcoded patterns when no config is available

set -euo pipefail

# Load shared config (if available)
SCRIPT_DIR="${0:A:h}"
if [[ -f "$SCRIPT_DIR/_config.sh" ]]; then
  source "$SCRIPT_DIR/_config.sh"
fi

# Resolve config files: ordered by priority (project > global > default)
# Returns all existing config paths, highest priority first
_LEO_DEFAULT_CFG="$HOME/utils/leo-skills/hooks/leo-hooks.yaml"

_resolve_config_file() {
  if [[ -n "${_LEO_MERGED_CONFIG:-}" && -f "$_LEO_MERGED_CONFIG" ]]; then
    echo "$_LEO_MERGED_CONFIG"
    return
  fi
  local project_root
  project_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
  local candidates=(
    "$project_root/.leo-hooks.yaml"
    "$HOME/.leo/hooks.yaml"
    "$_LEO_DEFAULT_CFG"
  )
  for f in "${candidates[@]}"; do
    if [[ -f "$f" ]]; then
      echo "$f"
      return
    fi
  done
}

_ACTIVE_CONFIG=$(_resolve_config_file)

# Check if disabled via config
if [[ -n "$_ACTIVE_CONFIG" ]]; then
  _dc_enabled=""
  if command -v yq &>/dev/null; then
    _dc_enabled=$(yq -r '."dangerous-commands".enabled // empty' "$_ACTIVE_CONFIG" 2>/dev/null)
  elif command -v python3 &>/dev/null; then
    _dc_enabled=$(python3 -c "
import yaml
try:
    with open('$_ACTIVE_CONFIG') as f:
        data = yaml.safe_load(f)
    v = data.get('dangerous-commands', {}).get('enabled')
    if v is not None:
        print('true' if v else 'false')
except Exception:
    pass
" 2>/dev/null)
  fi
  if [[ "$_dc_enabled" == "false" ]]; then
    exit 0
  fi
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# === Load block patterns from config ===
# Returns "name<TAB>pattern" lines, one per entry
# Uses TAB as delimiter since | appears inside regex patterns
_read_block_from_file() {
  local config_file="$1"
  [[ -z "$config_file" || ! -f "$config_file" ]] && return 1

  local result=""

  # Try yq first
  if command -v yq &>/dev/null; then
    result=$(yq -r '."dangerous-commands".block[] | (.name + "\t" + .pattern)' "$config_file" 2>/dev/null)
  # Fallback to python3
  elif command -v python3 &>/dev/null; then
    result=$(python3 -c "
import yaml
try:
    with open('$config_file') as f:
        data = yaml.safe_load(f)
    blocks = data.get('dangerous-commands', {}).get('block', [])
    for b in blocks:
        name = b.get('name', '')
        pattern = b.get('pattern', '')
        if name and pattern:
            print(f'{name}\t{pattern}')
except Exception:
    pass
" 2>/dev/null)
  fi

  if [[ -n "$result" ]]; then
    echo "$result"
    return 0
  fi
  return 1
}

_load_block_patterns() {
  # Try active config first (project or global)
  _read_block_from_file "${_ACTIVE_CONFIG:-}" && return 0
  # Fall back to default config if active config had no block entries
  if [[ "${_ACTIVE_CONFIG:-}" != "$_LEO_DEFAULT_CFG" ]]; then
    _read_block_from_file "$_LEO_DEFAULT_CFG" && return 0
  fi
  return 1
}

# Try config-driven patterns first
BLOCK_PATTERNS=$(_load_block_patterns 2>/dev/null) && CONFIG_LOADED=true || CONFIG_LOADED=false

if [[ "$CONFIG_LOADED" == "true" && -n "$BLOCK_PATTERNS" ]]; then
  # Config-driven: iterate block entries (TAB-delimited)
  while IFS=$'\t' read -r name pattern; do
    [[ -z "$name" || -z "$pattern" ]] && continue
    if echo "$COMMAND" | grep -qE "$pattern" 2>/dev/null; then
      echo "BLOCKED [$name]: Destructive command detected — '$COMMAND'"
      exit 2
    fi
  done <<< "$BLOCK_PATTERNS"
else
  # === FALLBACK: Hardcoded patterns (no config available) ===

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
fi

exit 0
