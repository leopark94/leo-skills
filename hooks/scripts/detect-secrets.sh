#!/bin/zsh
# detect-secrets.sh — PreToolUse hook: detect secrets in file content
# Blocks Edit/Write/Bash when API keys, tokens, or credentials are detected
# Recommends storing via leo secret (leo-cli Keychain)

set -euo pipefail

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

# Secret patterns
PATTERNS=(
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

# Block sensitive file types (.pem, .key — NOT .env, which is allowed)
if [[ -n "$FILE_PATH" ]] && ([[ "$FILE_PATH" =~ \.pem$ ]] || [[ "$FILE_PATH" =~ \.key$ ]]); then
  echo "BLOCKED: Direct editing of sensitive files is forbidden ($FILE_PATH)"
  echo "-> Store in Keychain via leo secret add <name> (leo-cli)"
  exit 2
fi

# Inspect content for secret patterns
if [[ -n "$CONTENT" ]]; then
  for pattern in "${PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qP "$pattern" 2>/dev/null || echo "$CONTENT" | grep -qE "$pattern" 2>/dev/null; then
      MATCHED=$(echo "$CONTENT" | grep -oP "$pattern" 2>/dev/null | head -1 || echo "$CONTENT" | grep -oE "$pattern" 2>/dev/null | head -1)
      REDACTED="${MATCHED:0:8}***"
      echo "BLOCKED: Secret detected — $REDACTED"
      echo "-> Store in Keychain via leo secret add <name> then use process.env.XXX"
      exit 2
    fi
  done
fi

# Bash-specific: detect secrets in shell commands
if [[ "$TOOL_NAME" == "Bash" ]] && [[ -n "$CONTENT" ]]; then
  if echo "$CONTENT" | grep -qE "export\s+\w*(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)\w*\s*=\s*[a-zA-Z0-9_-]{8,}"; then
    echo "BLOCKED: Secret export detected in Bash command"
    echo "-> Use leo secret add <name>"
    exit 2
  fi
  if echo "$CONTENT" | grep -qE 'curl\s.*-H\s.*Authorization:\s*Bearer\s+[a-zA-Z0-9_./-]{20,}'; then
    echo "BLOCKED: Hardcoded auth token in curl command"
    echo "-> Use leo secret get <name> to inject the token"
    exit 2
  fi
fi

exit 0
