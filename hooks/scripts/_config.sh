#!/bin/zsh
# _config.sh — Shared hook config loader (with deep-merge)
# Merges config from three layers: default < global < project
# Project config merges ON TOP of global, global merges ON TOP of default.
# Requires: python3 with PyYAML (preferred) or yq v4+
# Fallback: first-match-wins if neither merge tool is available
# Usage: source this file, then call leo_config_get "path.to.key" [default]

_LEO_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
_LEO_PROJECT_CONFIG="$_LEO_PROJECT_ROOT/.leo-hooks.yaml"
_LEO_GLOBAL_CONFIG="$HOME/.leo/hooks.yaml"
_LEO_DEFAULT_CONFIG="$HOME/utils/leo-skills/hooks/leo-hooks.yaml"

# --- Merged config (cached as shell variable — no temp file needed) ---
_LEO_MERGED_YAML=""

_leo_build_merged_config() {
  # Collect config files that exist, in merge order (base first)
  local -a config_files=()
  [[ -f "$_LEO_DEFAULT_CONFIG" ]] && config_files+=("$_LEO_DEFAULT_CONFIG")
  [[ -f "$_LEO_GLOBAL_CONFIG" ]]  && config_files+=("$_LEO_GLOBAL_CONFIG")
  [[ -f "$_LEO_PROJECT_CONFIG" ]] && config_files+=("$_LEO_PROJECT_CONFIG")

  # Nothing found at all
  if (( ${#config_files[@]} == 0 )); then
    _LEO_MERGED_YAML=""
    return
  fi

  # Only one file — no merge needed, read it directly
  if (( ${#config_files[@]} == 1 )); then
    _LEO_MERGED_YAML=$(cat "${config_files[1]}")
    return
  fi

  # Multiple files — deep merge required
  # Try python3 + PyYAML first (preferred — always available on macOS)
  if command -v python3 &>/dev/null && python3 -c "import yaml" &>/dev/null; then
    local pyfiles=""
    for f in "${config_files[@]}"; do
      pyfiles+="'$f',"
    done

    local merged_output
    merged_output=$(python3 -c "
import yaml, sys, copy

def deep_merge(base, overlay):
    \"\"\"Recursively merge overlay dict into base dict. Overlay wins on conflict.\"\"\"
    if not isinstance(base, dict) or not isinstance(overlay, dict):
        return copy.deepcopy(overlay)
    result = copy.deepcopy(base)
    for key, val in overlay.items():
        if key in result and isinstance(result[key], dict) and isinstance(val, dict):
            result[key] = deep_merge(result[key], val)
        else:
            result[key] = copy.deepcopy(val)
    return result

files = [$pyfiles]
merged = {}
for path in files:
    try:
        with open(path) as f:
            data = yaml.safe_load(f)
        if isinstance(data, dict):
            merged = deep_merge(merged, data)
    except Exception:
        pass

print(yaml.dump(merged, default_flow_style=False, allow_unicode=True, sort_keys=False), end='')
" 2>/dev/null)

    if [[ $? -eq 0 && -n "$merged_output" ]]; then
      _LEO_MERGED_YAML="$merged_output"
      return
    fi
  fi

  # Try yq v4 merge (yq eval-all with ireduce)
  if command -v yq &>/dev/null; then
    local yq_args=""
    for f in "${config_files[@]}"; do
      yq_args+=" '$f'"
    done
    local merged_output
    merged_output=$(eval "yq eval-all '. as \$item ireduce({}; . * \$item)' $yq_args" 2>/dev/null)
    if [[ $? -eq 0 && -n "$merged_output" ]]; then
      _LEO_MERGED_YAML="$merged_output"
      return
    fi
  fi

  # Both merge methods failed — fall back to highest-priority single file
  _leo_fallback_first_match
}

# Fallback: pick the highest-priority single file (original behavior)
_leo_fallback_first_match() {
  local fallback=""
  if [[ -f "$_LEO_PROJECT_CONFIG" ]]; then
    fallback="$_LEO_PROJECT_CONFIG"
  elif [[ -f "$_LEO_GLOBAL_CONFIG" ]]; then
    fallback="$_LEO_GLOBAL_CONFIG"
  elif [[ -f "$_LEO_DEFAULT_CONFIG" ]]; then
    fallback="$_LEO_DEFAULT_CONFIG"
  fi
  if [[ -n "$fallback" ]]; then
    _LEO_MERGED_YAML=$(cat "$fallback")
  else
    _LEO_MERGED_YAML=""
  fi
}

# Build the merged config on source
_leo_build_merged_config

# --- Public API (unchanged) ---

# Config reader: tries yq first, falls back to python3
leo_config_get() {
  local key="$1"
  local default="${2:-}"

  if [[ -z "$_LEO_MERGED_YAML" ]]; then
    echo "$default"
    return
  fi

  local result=""

  # Try yq first (fastest for single lookups)
  if command -v yq &>/dev/null; then
    result=$(echo "$_LEO_MERGED_YAML" | yq -r ".$key // empty" 2>/dev/null)
  # Fallback to python3
  elif command -v python3 &>/dev/null; then
    result=$(python3 -c "
import sys
try:
    import yaml
    data = yaml.safe_load(sys.stdin)
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
" <<< "$_LEO_MERGED_YAML" 2>/dev/null)
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
