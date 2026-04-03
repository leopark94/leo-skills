#!/bin/zsh
# sync.sh — Leo Master Skills synchronization
# Pulls latest from git then re-runs install.sh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SKILLS_ROOT="${SCRIPT_DIR:h}"

GREEN='\033[0;32m'
NC='\033[0m'
log_info() { echo "${GREEN}[leo-skills]${NC} $1"; }

cd "$SKILLS_ROOT"

# git pull (if repo exists)
if [[ -d .git ]]; then
  log_info "Fetching latest version..."
  git pull --rebase 2>/dev/null || log_info "git pull skipped (offline or permission issue)"
fi

# Re-install
log_info "Syncing configuration..."
"$SCRIPT_DIR/install.sh"

log_info "Sync complete!"
