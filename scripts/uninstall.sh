#!/bin/zsh
# uninstall.sh — Leo Master Skills removal
# Cleans up hooks, agent symlinks, and skill symlinks

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
SKILLS_ROOT="${0:A:h:h}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info() { echo "${GREEN}[leo-skills]${NC} $1"; }
log_warn() { echo "${YELLOW}[leo-skills]${NC} $1"; }

# Remove hooks from settings.json
if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  jq 'del(.hooks)' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
  log_info "Hooks removed"
fi

# Remove agent symlinks
for agent_file in "$CLAUDE_DIR"/agents/*.md; do
  [[ -L "$agent_file" ]] && [[ "$(readlink "$agent_file")" == "$SKILLS_ROOT"* ]] && {
    rm "$agent_file"
    log_info "Agent removed: $(basename "$agent_file")"
  }
done

# Remove skill symlinks
for skill_dir in "$CLAUDE_DIR"/skills/*/; do
  [[ -L "$skill_dir" ]] && [[ "$(readlink "$skill_dir")" == "$SKILLS_ROOT"* ]] && {
    rm "$skill_dir"
    log_info "Skill removed: $(basename "$skill_dir")"
  }
done

log_info "Leo Master Skills uninstalled"
