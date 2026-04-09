#!/bin/zsh
# detect-secrets.sh — PreToolUse hook: detect secrets in file content
# Blocks Edit/Write/Bash when API keys, tokens, or credentials are detected
# Recommends storing via leo secret (leo-cli Keychain)
# Reads config from .leo-hooks.yaml; falls back to hardcoded defaults

set -euo pipefail

# --- Config loading ---
SCRIPT_DIR="${0:A:h}"
_CONFIG_LOADED=false
if [[ -f "$SCRIPT_DIR/_config.sh" ]]; then
  source "$SCRIPT_DIR/_config.sh" && _CONFIG_LOADED=true
fi

# Check if detect-secrets is enabled (default: true)
if $_CONFIG_LOADED && ! leo_config_enabled "detect-secrets.enabled"; then
  exit 0
fi

# --- Input parsing ---
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Only inspect Edit/Write/Bash tools
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# For Bash tool: inspect the command for secrets
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  [[ -z "$COMMAND" ]] && exit 0
  CONTENT="$COMMAND"
  FILE_PATH=""
fi

# --- Hardcoded fallback patterns ---
FALLBACK_PATTERNS=(
  'sk-[a-zA-Z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  'ghp_[a-zA-Z0-9]{36}'
  'gho_[a-zA-Z0-9]{36}'
  'glpat-[a-zA-Z0-9\-]{20}'
  'xoxb-[0-9]+-[a-zA-Z0-9]+'
  'xoxp-[0-9]+-[a-zA-Z0-9]+'
  'AIza[0-9A-Za-z\-_]{35}'
  'ya29\.[0-9A-Za-z\-_]+'
  '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'
  '-----BEGIN OPENSSH PRIVATE KEY-----'
)

FALLBACK_BLOCKED_EXTENSIONS=(.pem .key)

# --- Build active patterns from config (or use fallback) ---
PATTERNS=()
_PATTERNS_FROM_CONFIG=false

if $_CONFIG_LOADED && [[ -n "${_LEO_MERGED_YAML:-}" ]]; then
  # Read patterns array from config using yq or python3
  _PATTERN_LIST=""
  if command -v yq &>/dev/null; then
    _PATTERN_LIST=$(echo "$_LEO_MERGED_YAML" | yq -r '.detect-secrets.patterns[] | select(.enabled == true) | .regex' 2>/dev/null || true)
  elif command -v python3 &>/dev/null; then
    _PATTERN_LIST=$(python3 -c "
import sys, yaml
try:
    data = yaml.safe_load(sys.stdin)
    patterns = data.get('detect-secrets', {}).get('patterns', [])
    for p in patterns:
        if p.get('enabled', True):
            print(p['regex'])
except Exception:
    pass
" <<< "$_LEO_MERGED_YAML" 2>/dev/null || true)
  fi

  if [[ -n "$_PATTERN_LIST" ]]; then
    while IFS= read -r regex; do
      [[ -z "$regex" ]] && continue
      PATTERNS+=("$regex")
    done <<< "$_PATTERN_LIST"
    _PATTERNS_FROM_CONFIG=true
  fi
fi

# Fallback: use hardcoded patterns if config read failed or returned nothing
if [[ ${#PATTERNS[@]} -eq 0 ]]; then
  PATTERNS=("${FALLBACK_PATTERNS[@]}")
fi

# --- Build blocked extensions list from config (or use fallback) ---
BLOCKED_EXTENSIONS=()

if $_CONFIG_LOADED && [[ -n "${_LEO_MERGED_YAML:-}" ]]; then
  _EXT_LIST=$(leo_config_get_array "detect-secrets.blocked-extensions")
  if [[ -n "$_EXT_LIST" ]]; then
    while IFS= read -r ext; do
      [[ -z "$ext" ]] && continue
      BLOCKED_EXTENSIONS+=("$ext")
    done <<< "$_EXT_LIST"
  fi
fi

if [[ ${#BLOCKED_EXTENSIONS[@]} -eq 0 ]]; then
  BLOCKED_EXTENSIONS=("${FALLBACK_BLOCKED_EXTENSIONS[@]}")
fi

# --- Read allow-env-files setting (default: true) ---
ALLOW_ENV_FILES=true
if $_CONFIG_LOADED; then
  _ENV_VAL=$(leo_config_get "detect-secrets.allow-env-files" "true")
  if [[ "$_ENV_VAL" == "false" ]]; then
    ALLOW_ENV_FILES=false
  fi
fi

# --- Block sensitive file types ---
if [[ -n "$FILE_PATH" ]]; then
  # Block .env files if allow-env-files is false
  if ! $ALLOW_ENV_FILES && [[ "$FILE_PATH" =~ \.env(\..*)?$ ]]; then
    echo "BLOCKED: Direct editing of .env files is forbidden ($FILE_PATH)"
    echo "-> Store in Keychain via leo secret add <name> (leo-cli)"
    exit 2
  fi

  # Block configured extensions (.pem, .key, etc.)
  for ext in "${BLOCKED_EXTENSIONS[@]}"; do
    if [[ "$FILE_PATH" =~ "${ext}"$ ]]; then
      echo "BLOCKED: Direct editing of sensitive files is forbidden ($FILE_PATH)"
      echo "-> Store in Keychain via leo secret add <name> (leo-cli)"
      exit 2
    fi
  done
fi

# --- Inspect content for secret patterns ---
if [[ -n "$CONTENT" ]]; then
  for pattern in "${PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qP -- "$pattern" 2>/dev/null || echo "$CONTENT" | grep -qE -- "$pattern" 2>/dev/null; then
      MATCHED=$(echo "$CONTENT" | grep -oP -- "$pattern" 2>/dev/null | head -1 || echo "$CONTENT" | grep -oE -- "$pattern" 2>/dev/null | head -1)
      REDACTED="${MATCHED:0:8}***"
      echo "BLOCKED: Secret detected — $REDACTED"
      echo "-> Store in Keychain via leo secret add <name> then use process.env.XXX"
      exit 2
    fi
  done
fi

# --- Bash-specific: detect secrets in shell commands ---
if [[ "$TOOL_NAME" == "Bash" ]] && [[ -n "$CONTENT" ]]; then
  # Read bash-guard settings from config (or use hardcoded defaults)
  _BLOCK_EXPORTS=true
  _BLOCK_AUTH_HEADERS=true

  if $_CONFIG_LOADED; then
    if ! leo_config_enabled "detect-secrets.bash-guard.enabled"; then
      # bash-guard entirely disabled — skip bash-specific checks
      exit 0
    fi
    _EXP_VAL=$(leo_config_get "detect-secrets.bash-guard.block-secret-exports" "true")
    [[ "$_EXP_VAL" == "false" ]] && _BLOCK_EXPORTS=false
    _AUTH_VAL=$(leo_config_get "detect-secrets.bash-guard.block-hardcoded-auth-headers" "true")
    [[ "$_AUTH_VAL" == "false" ]] && _BLOCK_AUTH_HEADERS=false
  fi

  if $_BLOCK_EXPORTS; then
    if echo "$CONTENT" | grep -qE "export\s+\w*(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)\w*\s*=\s*[a-zA-Z0-9_-]{8,}"; then
      echo "BLOCKED: Secret export detected in Bash command"
      echo "-> Use leo secret add <name>"
      exit 2
    fi
  fi

  if $_BLOCK_AUTH_HEADERS; then
    if echo "$CONTENT" | grep -qE 'curl\s.*-H\s.*Authorization:\s*Bearer\s+[a-zA-Z0-9_./-]{20,}'; then
      echo "BLOCKED: Hardcoded auth token in curl command"
      echo "-> Use leo secret get <name> to inject the token"
      exit 2
    fi
  fi
fi

exit 0
