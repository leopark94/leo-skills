#!/bin/zsh
# detect-secrets.sh — PreToolUse hook: detect secrets in file content
# Blocks Edit/Write when API keys, tokens, or credentials are detected
# Recommends storing via leo secret (leo-cli Keychain)

set -euo pipefail

# Read hook data from stdin
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.command // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Only inspect Edit/Write tools
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

# Secret patterns
PATTERNS=(
  # API Keys
  'sk-[a-zA-Z0-9]{20,}'          # OpenAI/Anthropic API key
  'AKIA[0-9A-Z]{16}'             # AWS Access Key
  'ghp_[a-zA-Z0-9]{36}'          # GitHub PAT
  'gho_[a-zA-Z0-9]{36}'          # GitHub OAuth
  'glpat-[a-zA-Z0-9\-]{20}'     # GitLab PAT
  'xoxb-[0-9]+-[a-zA-Z0-9]+'    # Slack Bot Token
  'xoxp-[0-9]+-[a-zA-Z0-9]+'    # Slack User Token
  # Generic patterns
  'AIza[0-9A-Za-z\-_]{35}'      # Google API Key
  'ya29\.[0-9A-Za-z\-_]+'       # Google OAuth
  # Private keys
  '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'
  '-----BEGIN OPENSSH PRIVATE KEY-----'
  # Passwords in config
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'
  'secret\s*[:=]\s*["\x27][^"\x27]{8,}'
  'token\s*[:=]\s*["\x27][^"\x27]{20,}'
)

# Block sensitive file types unconditionally
if [[ "$FILE_PATH" =~ \.env(\..*)?$ ]] || [[ "$FILE_PATH" =~ \.pem$ ]] || [[ "$FILE_PATH" =~ \.key$ ]]; then
  echo "BLOCKED: Direct editing of sensitive files is forbidden ($FILE_PATH)"
  echo "-> Store environment variables in Keychain via 'leo secret add <name>' (leo-cli)"
  exit 2
fi

# Inspect content for secret patterns
if [[ -n "$CONTENT" ]]; then
  for pattern in "${PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qP "$pattern" 2>/dev/null || echo "$CONTENT" | grep -qE "$pattern" 2>/dev/null; then
      MATCHED=$(echo "$CONTENT" | grep -oP "$pattern" 2>/dev/null | head -1 || echo "$CONTENT" | grep -oE "$pattern" 2>/dev/null | head -1)
      REDACTED="${MATCHED:0:8}***"
      echo "BLOCKED: Secret detected — $REDACTED"
      echo "-> Store in Keychain via 'leo secret add <name>' then reference as environment variable (leo-cli)"
      echo "-> Use process.env.XXX or \$XXX in code"
      exit 2
    fi
  done
fi

exit 0
