#!/bin/zsh
# detect-secrets.sh — PreToolUse 훅: 파일 내 민감정보 탐지
# Edit/Write 시 새로 작성되는 내용에 API 키, 토큰 등이 포함되면 차단
# 탐지 시 leo secret에 저장 권고

set -euo pipefail

# stdin에서 훅 데이터 읽기
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.command // empty')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty')

# Edit/Write 도구만 검사
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

# 민감정보 패턴
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

# .env 파일이면 무조건 차단
if [[ "$FILE_PATH" =~ \.env(\..*)?$ ]] || [[ "$FILE_PATH" =~ \.pem$ ]] || [[ "$FILE_PATH" =~ \.key$ ]]; then
  echo "BLOCKED: 민감 파일 직접 편집 금지 ($FILE_PATH)"
  echo "→ 환경변수는 'leo secret add <name>' 으로 Keychain에 저장하세요"
  exit 2
fi

# 내용 검사
if [[ -n "$CONTENT" ]]; then
  for pattern in "${PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qP "$pattern" 2>/dev/null || echo "$CONTENT" | grep -qE "$pattern" 2>/dev/null; then
      MATCHED=$(echo "$CONTENT" | grep -oP "$pattern" 2>/dev/null | head -1 || echo "$CONTENT" | grep -oE "$pattern" 2>/dev/null | head -1)
      REDACTED="${MATCHED:0:8}***"
      echo "BLOCKED: 민감정보 탐지됨 — $REDACTED"
      echo "→ 'leo secret add <name>' 으로 Keychain에 저장 후 환경변수로 참조하세요"
      echo "→ 코드에서는 process.env.XXX 또는 \$XXX 로 사용"
      exit 2
    fi
  done
fi

exit 0
