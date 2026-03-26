#!/bin/zsh
# discover.sh — GitHub에서 Claude Code 스킬 검색
# 사용법: ./discover.sh [search <keyword>] [install <owner/repo>] [popular]

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

# gh CLI 체크
if ! command -v gh &>/dev/null; then
  log_warn "gh CLI 필요: brew install gh && gh auth login"
  exit 1
fi

case "${1:-popular}" in
  search|s)
    KEYWORD="${2:?키워드를 입력하세요: ./discover.sh search security}"
    log_title "레지스트리 검색: $KEYWORD"

    # 로컬 레지스트리 먼저
    if [[ -f "$REGISTRY" ]]; then
      RESULTS=$(grep -i "$KEYWORD" "$REGISTRY" 2>/dev/null | grep -E '^\|' | head -10 || true)
      if [[ -n "$RESULTS" ]]; then
        log_info "로컬 레지스트리 결과:"
        echo "$RESULTS"
        echo ""
      fi
    fi

    # GitHub 실시간 검색
    log_info "GitHub 검색 중..."
    gh search repos "claude code $KEYWORD skills" --sort stars --limit 10 \
      --json name,url,description,stargazersCount \
      --template '{{range .}}{{printf "⭐ %-6d %-40s %s\n" .stargazersCount .name .description}}{{end}}'
    ;;

  install|i)
    REPO="${2:?레포를 입력하세요: ./discover.sh install owner/repo}"
    TMPDIR="/tmp/claude-skill-$(echo "$REPO" | tr '/' '-')"

    log_title "설치: $REPO"

    # 클론
    if [[ -d "$TMPDIR" ]]; then
      log_info "캐시 사용: $TMPDIR"
      git -C "$TMPDIR" pull --rebase 2>/dev/null || true
    else
      log_info "클론 중..."
      gh repo clone "$REPO" "$TMPDIR" 2>/dev/null
    fi

    # 구조 확인
    echo ""
    log_info "발견된 항목:"

    FOUND=0
    if [[ -d "$TMPDIR/skills" ]]; then
      echo "  스킬:"
      for d in "$TMPDIR"/skills/*/; do
        [[ -d "$d" ]] && echo "    - $(basename "$d")" && FOUND=$((FOUND+1))
      done
    fi
    if [[ -d "$TMPDIR/agents" ]]; then
      echo "  에이전트:"
      for f in "$TMPDIR"/agents/*.md; do
        [[ -f "$f" ]] && echo "    - $(basename "$f" .md)" && FOUND=$((FOUND+1))
      done
    fi

    # SKILL.md가 루트에 있는 경우 (단일 스킬 레포)
    if [[ -f "$TMPDIR/SKILL.md" ]]; then
      SKILL_NAME=$(grep -m1 'name:' "$TMPDIR/SKILL.md" | sed 's/name: *//' | tr -d '"' || basename "$REPO")
      echo "  스킬 (루트): $SKILL_NAME"
      FOUND=$((FOUND+1))
    fi

    # .claude/skills 경로
    if [[ -d "$TMPDIR/.claude/skills" ]]; then
      echo "  스킬 (.claude/):"
      for d in "$TMPDIR"/.claude/skills/*/; do
        [[ -d "$d" ]] && echo "    - $(basename "$d")" && FOUND=$((FOUND+1))
      done
    fi

    if [[ $FOUND -eq 0 ]]; then
      log_warn "스킬/에이전트 구조를 찾을 수 없음. README 확인 필요."
      echo "  README: $TMPDIR/README.md"
    else
      echo ""
      log_info "설치하려면:"
      echo "  cp -r $TMPDIR/skills/<name> $INSTALL_DIR/"
      echo "  또는: ln -sf $TMPDIR/skills/<name> $INSTALL_DIR/<name>"
    fi
    ;;

  popular|p|"")
    log_title "인기 Claude Code 스킬 레포 (Stars 기준)"
    gh search repos "claude code skills" --sort stars --limit 15 \
      --json name,url,stargazersCount,description \
      --template '{{range .}}{{printf "⭐ %-7d %-35s %s\n" .stargazersCount .name .description}}{{end}}'
    echo ""
    log_info "검색: ./discover.sh search <keyword>"
    log_info "설치: ./discover.sh install <owner/repo>"
    ;;

  update|u)
    log_title "레지스트리 업데이트"
    log_info "GitHub에서 최신 스킬 레포 검색 중..."

    # 카테고리별 검색
    for QUERY in "claude code skills" "claude-code-agents" "claude-code-hooks" "claude skills security"; do
      log_info "검색: $QUERY"
      gh search repos "$QUERY" --sort stars --limit 5 \
        --json name,url,stargazersCount,description \
        --template '{{range .}}{{printf "⭐ %-7d %-35s %s\n" .stargazersCount .name .description}}{{end}}'
    done

    log_info "새 레포를 REGISTRY.md에 추가하세요"
    ;;

  *)
    echo "사용법: $0 [search <keyword>] [install <owner/repo>] [popular] [update]"
    ;;
esac
