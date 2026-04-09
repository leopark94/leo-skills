#!/bin/zsh
# _config.sh — Shared hook config loader
# Sources .leo-hooks.yaml from project root, falls back to global ~/.leo/hooks.yaml
# Requires: yq (brew install yq) or python3 with PyYAML
# Usage: source this file, then call leo_config_get "path.to.key" [default]

_LEO_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
_LEO_PROJECT_CONFIG="$_LEO_PROJECT_ROOT/.leo-hooks.yaml"
_LEO_GLOBAL_CONFIG="$HOME/.leo/hooks.yaml"
_LEO_DEFAULT_CONFIG="$HOME/utils/leo-skills/hooks/leo-hooks.yaml"

# Find the active config file (project > global > default)
_LEO_CONFIG=""
if [[ -f "$_LEO_PROJECT_CONFIG" ]]; then
  _LEO_CONFIG="$_LEO_PROJECT_CONFIG"
elif [[ -f "$_LEO_GLOBAL_CONFIG" ]]; then
  _LEO_CONFIG="$_LEO_GLOBAL_CONFIG"
elif [[ -f "$_LEO_DEFAULT_CONFIG" ]]; then
  _LEO_CONFIG="$_LEO_DEFAULT_CONFIG"
fi

# Config reader: tries yq first, falls back to python3
leo_config_get() {
  local key="$1"
  local default="${2:-}"

  if [[ -z "$_LEO_CONFIG" ]]; then
    echo "$default"
    return
  fi

  local result=""

  # Try yq first (fastest)
  if command -v yq &>/dev/null; then
    result=$(yq -r ".$key // empty" "$_LEO_CONFIG" 2>/dev/null)
  # Fallback to python3
  elif command -v python3 &>/dev/null; then
    result=$(python3 -c "
import sys
try:
    import yaml
    with open('$_LEO_CONFIG') as f:
        data = yaml.safe_load(f)
    keys = '$key'.split('.')
    val = data
    for k in keys:
        if isinstance(val, dict) and k in val:
            val = val[k]
        else:
            val = None
            break
    if val is not None:
        if isinstance(val, list):
            print('\n'.join(str(x) for x in val))
        elif isinstance(val, bool):
            print('true' if val else 'false')
        else:
            print(val)
except Exception:
    pass
" 2>/dev/null)
  fi

  if [[ -n "$result" && "$result" != "null" ]]; then
    echo "$result"
  else
    echo "$default"
  fi
}

# Array reader: returns items one per line
leo_config_get_array() {
  local key="$1"
  leo_config_get "$key"
}

# Boolean reader
leo_config_enabled() {
  local key="$1"
  local val=$(leo_config_get "$key" "false")
  [[ "$val" == "true" ]]
}
