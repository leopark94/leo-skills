#!/bin/zsh
# discover.sh — Search Claude Code skills on GitHub
# Usage: ./discover.sh [search <keyword>] [install <owner/repo>] [popular]

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SKILLS_ROOT="${0:A:h:h}"
REGISTRY="$SKILLS_ROOT/registry/REGISTRY.md"
INSTALL_DIR="$HOME/.claude/skills"

log_info() { echo "${GREEN}[discover]${NC} $1"; }
log_warn() { echo "${YELLOW}[discover]${NC} $1"; }
log_title() { echo "\n${BOLD}${CYAN}$1${NC}\n"; }

# Check gh CLI
if ! command -v gh &>/dev/null; then
  log_warn "gh CLI required: brew install gh && gh auth login"
  exit 1
fi

case "${1:-popular}" in
  search|s)
    KEYWORD="${2:?Provide a keyword: ./discover.sh search security}"
    log_title "Registry search: $KEYWORD"

    # Check local registry first
    if [[ -f "$REGISTRY" ]]; then
      RESULTS=$(grep -i "$KEYWORD" "$REGISTRY" 2>/dev/null | grep -E '^\|' | head -10 || true)
      if [[ -n "$RESULTS" ]]; then
        log_info "Local registry results:"
        echo "$RESULTS"
        echo ""
      fi
    fi

    # Live GitHub search
    log_info "Searching GitHub..."
    gh search repos "claude code $KEYWORD skills" --sort stars --limit 10 \
      --json name,url,description,stargazersCount \
      --template '{{range .}}{{printf "* %-6d %-40s %s\n" .stargazersCount .name .description}}{{end}}'
    ;;

  install|i)
    REPO="${2:?Provide a repo: ./discover.sh install owner/repo}"
    TMPDIR="/tmp/claude-skill-$(echo "$REPO" | tr '/' '-')"

    log_title "Installing: $REPO"

    # Clone
    if [[ -d "$TMPDIR" ]]; then
      log_info "Using cache: $TMPDIR"
      git -C "$TMPDIR" pull --rebase 2>/dev/null || true
    else
      log_info "Cloning..."
      gh repo clone "$REPO" "$TMPDIR" 2>/dev/null
    fi

    # Check structure
    echo ""
    log_info "Found items:"

    FOUND=0
    if [[ -d "$TMPDIR/skills" ]]; then
      echo "  Skills:"
      for d in "$TMPDIR"/skills/*/; do
        [[ -d "$d" ]] && echo "    - $(basename "$d")" && FOUND=$((FOUND+1))
      done
    fi
    if [[ -d "$TMPDIR/agents" ]]; then
      echo "  Agents:"
      for f in "$TMPDIR"/agents/*.md; do
        [[ -f "$f" ]] && echo "    - $(basename "$f" .md)" && FOUND=$((FOUND+1))
      done
    fi

    # SKILL.md at root (single skill repo)
    if [[ -f "$TMPDIR/SKILL.md" ]]; then
      SKILL_NAME=$(grep -m1 'name:' "$TMPDIR/SKILL.md" | sed 's/name: *//' | tr -d '"' || basename "$REPO")
      echo "  Skill (root): $SKILL_NAME"
      FOUND=$((FOUND+1))
    fi

    # .claude/skills path
    if [[ -d "$TMPDIR/.claude/skills" ]]; then
      echo "  Skills (.claude/):"
      for d in "$TMPDIR"/.claude/skills/*/; do
        [[ -d "$d" ]] && echo "    - $(basename "$d")" && FOUND=$((FOUND+1))
      done
    fi

    if [[ $FOUND -eq 0 ]]; then
      log_warn "No skill/agent structure found. Check the README."
      echo "  README: $TMPDIR/README.md"
    else
      echo ""
      log_info "To install:"
      echo "  cp -r $TMPDIR/skills/<name> $INSTALL_DIR/"
      echo "  or: ln -sf $TMPDIR/skills/<name> $INSTALL_DIR/<name>"
    fi
    ;;

  popular|p|"")
    log_title "Popular Claude Code Skill Repos (by stars)"
    gh search repos "claude code skills" --sort stars --limit 15 \
      --json name,url,stargazersCount,description \
      --template '{{range .}}{{printf "* %-7d %-35s %s\n" .stargazersCount .name .description}}{{end}}'
    echo ""
    log_info "Search: ./discover.sh search <keyword>"
    log_info "Install: ./discover.sh install <owner/repo>"
    ;;

  update|u)
    log_title "Registry Update"
    log_info "Searching latest skill repos on GitHub..."

    # Search by category
    for QUERY in "claude code skills" "claude-code-agents" "claude-code-hooks" "claude skills security"; do
      log_info "Query: $QUERY"
      gh search repos "$QUERY" --sort stars --limit 5 \
        --json name,url,stargazersCount,description \
        --template '{{range .}}{{printf "* %-7d %-35s %s\n" .stargazersCount .name .description}}{{end}}'
    done

    log_info "Add new repos to REGISTRY.md"
    ;;

  *)
    echo "Usage: $0 [search <keyword>] [install <owner/repo>] [popular] [update]"
    ;;
esac
