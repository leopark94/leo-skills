#!/bin/zsh
# sync.sh — Leo Master Skills 동기화
# git pull 후 install.sh 재실행

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
SKILLS_ROOT="${SCRIPT_DIR:h}"

GREEN='\033[0;32m'
NC='\033[0m'
log_info() { echo "${GREEN}[leo-skills]${NC} $1"; }

cd "$SKILLS_ROOT"

# git pull (레포가 있으면)
if [[ -d .git ]]; then
  log_info "최신 버전 가져오는 중..."
  git pull --rebase 2>/dev/null || log_info "git pull 스킵 (오프라인 또는 권한 문제)"
fi

# 재설치
log_info "설정 동기화 중..."
"$SCRIPT_DIR/install.sh"

log_info "동기화 완료!"
