#!/bin/zsh
# uninstall.sh — Leo Master Skills 제거
# 훅, 에이전트, 스킬 심링크 정리

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
SKILLS_ROOT="${0:A:h:h}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info() { echo "${GREEN}[leo-skills]${NC} $1"; }
log_warn() { echo "${YELLOW}[leo-skills]${NC} $1"; }

# settings.json에서 hooks 제거
if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  jq 'del(.hooks)' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
  log_info "훅 제거 완료"
fi

# 에이전트 심링크 제거
for agent_file in "$CLAUDE_DIR"/agents/*.md; do
  [[ -L "$agent_file" ]] && [[ "$(readlink "$agent_file")" == "$SKILLS_ROOT"* ]] && {
    rm "$agent_file"
    log_info "에이전트 제거: $(basename "$agent_file")"
  }
done

# 스킬 심링크 제거
for skill_dir in "$CLAUDE_DIR"/skills/*/; do
  [[ -L "$skill_dir" ]] && [[ "$(readlink "$skill_dir")" == "$SKILLS_ROOT"* ]] && {
    rm "$skill_dir"
    log_info "스킬 제거: $(basename "$skill_dir")"
  }
done

log_info "Leo Master Skills 제거 완료"
