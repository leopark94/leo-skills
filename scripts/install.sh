#!/bin/zsh
# install.sh — Leo Master Skills global installation
# Registers hooks in ~/.claude/settings.json + symlinks agents/skills

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SKILLS_ROOT="${SCRIPT_DIR:h}"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo "${GREEN}[leo-skills]${NC} $1"; }
log_warn() { echo "${YELLOW}[leo-skills]${NC} $1"; }
log_error() { echo "${RED}[leo-skills]${NC} $1"; }

# Check jq dependency
if ! command -v jq &>/dev/null; then
  log_error "jq required: brew install jq"
  exit 1
fi

# Ensure directory exists
[[ -d "$CLAUDE_DIR" ]] || mkdir -p "$CLAUDE_DIR"

# Make scripts executable
chmod +x "$SKILLS_ROOT"/hooks/scripts/*.sh

# Backup settings.json
if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  log_info "settings.json backed up"
fi

# Merge hooks
log_info "Registering hooks..."

# Read existing settings.json
if [[ -f "$SETTINGS" ]]; then
  EXISTING=$(cat "$SETTINGS")
else
  EXISTING='{}'
fi

# Add hooks key if missing
if ! echo "$EXISTING" | jq -e '.hooks' &>/dev/null; then
  EXISTING=$(echo "$EXISTING" | jq '. + {"hooks": {}}')
fi

# Merge each event from hooks.json
HOOKS_JSON="$SKILLS_ROOT/hooks/hooks.json"
for EVENT in $(jq -r 'keys[] | select(. != "$schema" and . != "_comment")' "$HOOKS_JSON"); do
  EVENT_HOOKS=$(jq ".[\"$EVENT\"]" "$HOOKS_JSON")
  EXISTING=$(echo "$EXISTING" | jq --arg event "$EVENT" --argjson hooks "$EVENT_HOOKS" '.hooks[$event] = $hooks')
done

# Save
echo "$EXISTING" | jq '.' > "$SETTINGS"
log_info "Hooks registered"

# Symlink agents
AGENTS_TARGET="$CLAUDE_DIR/agents"
[[ -d "$AGENTS_TARGET" ]] || mkdir -p "$AGENTS_TARGET"

for agent_file in "$SKILLS_ROOT"/agents/*.md; do
  agent_name=$(basename "$agent_file")
  if [[ ! -L "$AGENTS_TARGET/$agent_name" ]] || [[ "$(readlink "$AGENTS_TARGET/$agent_name")" != "$agent_file" ]]; then
    ln -sf "$agent_file" "$AGENTS_TARGET/$agent_name"
    log_info "Agent registered: $agent_name"
  fi
done

# Symlink skills
SKILLS_TARGET="$CLAUDE_DIR/skills"
[[ -d "$SKILLS_TARGET" ]] || mkdir -p "$SKILLS_TARGET"

for skill_dir in "$SKILLS_ROOT"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  if [[ ! -L "$SKILLS_TARGET/$skill_name" ]] || [[ "$(readlink "$SKILLS_TARGET/$skill_name")" != "$skill_dir" ]]; then
    ln -sf "$skill_dir" "$SKILLS_TARGET/$skill_name"
    log_info "Skill registered: $skill_name"
  fi
done

# Check for leo-cli (secret management handled by leo-cli)
if command -v leo &>/dev/null; then
  log_info "leo-cli detected — secret management via \`leo secret\`"
else
  log_warn "leo-cli not installed — recommend installing for secret management"
fi

log_info ""
log_info "========================================="
log_info "  Leo Master Skills installed!"
log_info "========================================="
log_info ""
log_info "Registered hooks:"
for EVENT in $(jq -r '.hooks | keys[]' "$SETTINGS" 2>/dev/null); do
  HOOK_COUNT=$(jq -r ".hooks[\"$EVENT\"] | length" "$SETTINGS")
  log_info "  - $EVENT (${HOOK_COUNT})"
done
log_info ""
log_info "Registered agents:"
ls -1 "$AGENTS_TARGET"/*.md 2>/dev/null | while read f; do
  log_info "  - $(basename "$f" .md)"
done
log_info ""
log_info "Registered skills:"
ls -1d "$SKILLS_TARGET"/*/ 2>/dev/null | while read d; do
  log_info "  - /$(basename "$d")"
done
