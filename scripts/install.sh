#!/bin/zsh
# install.sh — Leo Master Skills 글로벌 설치
# ~/.claude/settings.json에 훅 등록 + 에이전트/스킬 심링크

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SKILLS_ROOT="${SCRIPT_DIR:h}"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo "${GREEN}[leo-skills]${NC} $1"; }
log_warn() { echo "${YELLOW}[leo-skills]${NC} $1"; }
log_error() { echo "${RED}[leo-skills]${NC} $1"; }

# jq 체크
if ! command -v jq &>/dev/null; then
  log_error "jq 필요: brew install jq"
  exit 1
fi

# 디렉토리 확인
[[ -d "$CLAUDE_DIR" ]] || mkdir -p "$CLAUDE_DIR"

# 스크립트 실행 권한
chmod +x "$SKILLS_ROOT"/hooks/scripts/*.sh

# settings.json 백업
if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  log_info "settings.json 백업 완료"
fi

# 훅 병합
log_info "훅 등록 중..."

# 기존 settings.json 읽기
if [[ -f "$SETTINGS" ]]; then
  EXISTING=$(cat "$SETTINGS")
else
  EXISTING='{}'
fi

# hooks 키가 없으면 추가
if ! echo "$EXISTING" | jq -e '.hooks' &>/dev/null; then
  EXISTING=$(echo "$EXISTING" | jq '. + {"hooks": {}}')
fi

# hooks.json에서 각 이벤트를 병합
HOOKS_JSON="$SKILLS_ROOT/hooks/hooks.json"
for EVENT in $(jq -r 'keys[] | select(. != "$schema" and . != "_comment")' "$HOOKS_JSON"); do
  EVENT_HOOKS=$(jq ".[\"$EVENT\"]" "$HOOKS_JSON")
  EXISTING=$(echo "$EXISTING" | jq --arg event "$EVENT" --argjson hooks "$EVENT_HOOKS" '.hooks[$event] = $hooks')
done

# 저장
echo "$EXISTING" | jq '.' > "$SETTINGS"
log_info "훅 등록 완료"

# 에이전트 심링크
AGENTS_TARGET="$CLAUDE_DIR/agents"
[[ -d "$AGENTS_TARGET" ]] || mkdir -p "$AGENTS_TARGET"

for agent_file in "$SKILLS_ROOT"/agents/*.md; do
  agent_name=$(basename "$agent_file")
  if [[ ! -L "$AGENTS_TARGET/$agent_name" ]] || [[ "$(readlink "$AGENTS_TARGET/$agent_name")" != "$agent_file" ]]; then
    ln -sf "$agent_file" "$AGENTS_TARGET/$agent_name"
    log_info "에이전트 등록: $agent_name"
  fi
done

# 스킬 심링크
SKILLS_TARGET="$CLAUDE_DIR/skills"
[[ -d "$SKILLS_TARGET" ]] || mkdir -p "$SKILLS_TARGET"

for skill_dir in "$SKILLS_ROOT"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  if [[ ! -L "$SKILLS_TARGET/$skill_name" ]] || [[ "$(readlink "$SKILLS_TARGET/$skill_name")" != "$skill_dir" ]]; then
    ln -sf "$skill_dir" "$SKILLS_TARGET/$skill_name"
    log_info "스킬 등록: $skill_name"
  fi
done

log_info ""
log_info "========================================="
log_info "  Leo Master Skills 설치 완료!"
log_info "========================================="
log_info ""
log_info "등록된 훅:"
for EVENT in $(jq -r '.hooks | keys[]' "$SETTINGS" 2>/dev/null); do
  COUNT=$(jq -r ".hooks[\"$EVENT\"] | length" "$SETTINGS")
  log_info "  - $EVENT ($COUNT개)"
done
log_info ""
log_info "등록된 에이전트:"
ls -1 "$AGENTS_TARGET"/*.md 2>/dev/null | while read f; do
  log_info "  - $(basename "$f" .md)"
done
log_info ""
log_info "등록된 스킬:"
ls -1d "$SKILLS_TARGET"/*/ 2>/dev/null | while read d; do
  log_info "  - /$(basename "$d")"
done
