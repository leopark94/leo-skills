#!/bin/zsh
# leo-secret.sh — 통합 시크릿 관리 (macOS Keychain + Apple Passwords 연동)
#
# 사용법:
#   leo secret add <name> [--value <value>] [--service <url>]
#   leo secret get <name>
#   leo secret list
#   leo secret check              # 현재 프로젝트 매니페스트 기준 누락 확인
#   leo secret sync               # 모든 leo-* 프로젝트 시크릿 체크
#   leo secret remove <name>
#
# Apple Passwords 연동:
#   --service <url> 옵션 사용 시 internet-password로 저장 → Apple Passwords 앱에 표시 + iCloud 동기화
#   --service 없으면 generic-password로 저장 → Keychain Access에서만 접근

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SERVICE_PREFIX="leo-project"
ACCOUNT_NAME="leo-skills"
MANIFEST_FILE=".leo-secrets.yaml"

log_info()  { echo "${GREEN}[leo-secret]${NC} $1"; }
log_warn()  { echo "${YELLOW}[leo-secret]${NC} $1"; }
log_error() { echo "${RED}[leo-secret]${NC} $1"; }
log_hint()  { echo "${CYAN}[leo-secret]${NC} $1"; }

# ─── ADD ────────────────────────────────────────────
cmd_add() {
  local NAME="$1"
  local VALUE=""
  local SERVICE_URL=""

  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --value)  VALUE="$2"; shift 2 ;;
      --service) SERVICE_URL="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # 값이 없으면 프롬프트
  if [[ -z "$VALUE" ]]; then
    echo -n "값 입력 (${NAME}): "
    read -rs VALUE
    echo ""
  fi

  if [[ -n "$SERVICE_URL" ]]; then
    # Apple Passwords 연동: internet-password → Passwords 앱 + iCloud 동기화
    security add-internet-password \
      -a "$NAME" \
      -s "$SERVICE_URL" \
      -l "leo: $NAME" \
      -w "$VALUE" \
      -U 2>/dev/null || \
    security add-internet-password \
      -a "$NAME" \
      -s "$SERVICE_URL" \
      -l "leo: $NAME" \
      -w "$VALUE"

    log_info "저장 완료: $NAME (Apple Passwords 연동 — $SERVICE_URL)"
    log_hint "→ Apple Passwords 앱에서 확인 가능, iCloud로 동기화됩니다"
  else
    # Keychain generic-password — Keychain Access에서만 접근
    security add-generic-password \
      -a "$ACCOUNT_NAME" \
      -s "${SERVICE_PREFIX}-${NAME}" \
      -l "leo: $NAME" \
      -w "$VALUE" \
      -U 2>/dev/null || \
    security add-generic-password \
      -a "$ACCOUNT_NAME" \
      -s "${SERVICE_PREFIX}-${NAME}" \
      -l "leo: $NAME" \
      -w "$VALUE"

    log_info "저장 완료: $NAME (Keychain — 모든 leo-* 프로젝트에서 접근 가능)"
  fi
}

# ─── GET ────────────────────────────────────────────
cmd_get() {
  local NAME="$1"

  # generic-password 먼저 시도
  local VALUE
  VALUE=$(security find-generic-password \
    -a "$ACCOUNT_NAME" \
    -s "${SERVICE_PREFIX}-${NAME}" \
    -w 2>/dev/null) && {
    echo "$VALUE"
    return 0
  }

  # internet-password 시도 (Apple Passwords 연동된 것)
  VALUE=$(security find-internet-password \
    -a "$NAME" \
    -w 2>/dev/null) && {
    echo "$VALUE"
    return 0
  }

  log_error "시크릿 '$NAME' 찾을 수 없음"
  log_hint "→ leo secret add $NAME 으로 추가하세요"
  return 1
}

# ─── LIST ───────────────────────────────────────────
cmd_list() {
  log_info "=== Keychain (generic) ==="
  security dump-keychain 2>/dev/null | grep -A4 "\"svce\".*\"${SERVICE_PREFIX}" | grep -oP '"leo: \K[^"]+' 2>/dev/null || \
  security dump-keychain 2>/dev/null | grep "\"${SERVICE_PREFIX}" | sed 's/.*"leo-project-//;s/".*//' || \
  echo "  (없음)"

  echo ""
  log_info "=== Apple Passwords (internet) ==="
  security dump-keychain 2>/dev/null | grep -B2 -A4 '"leo:' | grep '"acct"' | sed 's/.*"acct"<blob>="//;s/".*/    /' 2>/dev/null || \
  echo "  (없음)"
}

# ─── CHECK ──────────────────────────────────────────
cmd_check() {
  local PROJECT_ROOT
  PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
  local MANIFEST="$PROJECT_ROOT/$MANIFEST_FILE"

  if [[ ! -f "$MANIFEST" ]]; then
    log_warn "$MANIFEST_FILE 없음 — 시크릿 매니페스트를 생성하세요"
    log_hint "예시:"
    cat <<'EXAMPLE'
# .leo-secrets.yaml
secrets:
  - name: OPENAI_API_KEY
    description: "OpenAI API 키"
    required: true
  - name: DATABASE_URL
    description: "PostgreSQL 연결 문자열"
    required: true
  - name: SLACK_WEBHOOK
    description: "Slack 알림 웹훅"
    required: false
EXAMPLE
    return 1
  fi

  log_info "시크릿 체크: $(basename "$PROJECT_ROOT")"

  local MISSING=0
  local TOTAL=0

  # YAML 파싱 (간단한 grep 기반 — jq/yq 불필요)
  while IFS= read -r line; do
    local SECRET_NAME=$(echo "$line" | sed 's/.*name: *//;s/ *$//')
    [[ -z "$SECRET_NAME" ]] && continue

    TOTAL=$((TOTAL + 1))

    if cmd_get "$SECRET_NAME" >/dev/null 2>&1; then
      log_info "  ✅ $SECRET_NAME"
    else
      local REQUIRED=$(grep -A2 "name: *${SECRET_NAME}" "$MANIFEST" | grep "required:" | grep -q "true" && echo "true" || echo "false")
      if [[ "$REQUIRED" == "true" ]]; then
        log_error "  ❌ $SECRET_NAME (필수)"
        MISSING=$((MISSING + 1))
      else
        log_warn "  ⚠️  $SECRET_NAME (선택)"
      fi
    fi
  done < <(grep "name:" "$MANIFEST" | grep -v "^#" | grep -v "^secrets:")

  echo ""
  if [[ $MISSING -gt 0 ]]; then
    log_error "$MISSING개 필수 시크릿 누락 (전체 $TOTAL개)"
    log_hint "→ leo secret add <name> 으로 추가하세요"
    return 1
  else
    log_info "모든 필수 시크릿 확인 완료 ($TOTAL개)"
    return 0
  fi
}

# ─── SYNC ───────────────────────────────────────────
cmd_sync() {
  log_info "모든 leo-* 프로젝트 시크릿 체크..."
  echo ""

  local FAILED=0
  for project_dir in ~/utils/leo-*/; do
    [[ ! -d "$project_dir" ]] && continue
    local manifest="$project_dir/$MANIFEST_FILE"
    [[ ! -f "$manifest" ]] && continue

    local project_name=$(basename "$project_dir")
    log_info "── $project_name ──"

    (cd "$project_dir" && cmd_check) || FAILED=$((FAILED + 1))
    echo ""
  done

  if [[ $FAILED -gt 0 ]]; then
    log_error "$FAILED개 프로젝트에서 시크릿 누락 발견"
    return 1
  else
    log_info "모든 프로젝트 시크릿 동기화 확인 완료"
  fi
}

# ─── REMOVE ─────────────────────────────────────────
cmd_remove() {
  local NAME="$1"

  security delete-generic-password \
    -a "$ACCOUNT_NAME" \
    -s "${SERVICE_PREFIX}-${NAME}" 2>/dev/null && {
    log_info "삭제 완료: $NAME (Keychain)"
    return 0
  }

  security delete-internet-password \
    -a "$NAME" 2>/dev/null && {
    log_info "삭제 완료: $NAME (Apple Passwords)"
    return 0
  }

  log_error "시크릿 '$NAME' 찾을 수 없음"
  return 1
}

# ─── MAIN ───────────────────────────────────────────
case "${1:-help}" in
  add)    shift; cmd_add "$@" ;;
  get)    shift; cmd_get "$@" ;;
  list)   cmd_list ;;
  check)  cmd_check ;;
  sync)   cmd_sync ;;
  remove) shift; cmd_remove "$@" ;;
  *)
    cat <<USAGE
사용법: leo secret <command>

Commands:
  add <name> [--value <v>] [--service <url>]   시크릿 추가
  get <name>                                    시크릿 조회
  list                                          전체 목록
  check                                         현재 프로젝트 매니페스트 체크
  sync                                          모든 leo-* 프로젝트 체크
  remove <name>                                 시크릿 삭제

Apple Passwords 연동:
  --service 옵션으로 URL 지정 시 internet-password로 저장
  → Apple Passwords 앱에 표시, iCloud로 디바이스 간 동기화

예시:
  leo secret add OPENAI_API_KEY
  leo secret add GITHUB_TOKEN --service github.com
  leo secret get OPENAI_API_KEY
  leo secret check
  leo secret sync
USAGE
    ;;
esac
