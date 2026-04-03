#!/bin/zsh
# prompt-guard.sh — UserPromptSubmit 훅: 프롬프트 품질 체크 + 스킬 라우팅 힌트
# 모호한 프롬프트 감지, 관련 스킬 추천, 아키텍처 결정 리마인드

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[[ -z "$PROMPT" ]] && exit 0

HINTS=""

# 1. 버그/에러 키워드 → /investigate 추천
if echo "$PROMPT" | grep -qiE '버그|bug|에러|error|안됨|안돼|깨졌|broken|fix|수정|왜.*안'; then
  HINTS="${HINTS}\n💡 버그/에러 감지 → /investigate 추천 (PARALLEL 기본, 팀 가설 검증)"
fi

# 2. 기능 구현 키워드 → /sprint 추천
if echo "$PROMPT" | grep -qiE '구현|만들어|추가|feature|implement|build|개발'; then
  HINTS="${HINTS}\n💡 기능 구현 감지 → /sprint 추천 (STANDARD 기본, architect + 검증팀)"
fi

# 3. 리뷰 키워드 → /review 추천
if echo "$PROMPT" | grep -qiE '리뷰|review|확인|체크|검토|PR'; then
  HINTS="${HINTS}\n💡 리뷰 요청 감지 → /review 추천 (STANDARD 기본, 팀 리뷰)"
fi

# 4. 아키텍처 키워드 → ADR 리마인드
if echo "$PROMPT" | grep -qiE '아키텍|architect|구조|설계|design|패턴|pattern|모노레포|monorepo|마이크로서비스'; then
  HINTS="${HINTS}\n📐 아키텍처 결정 감지 → ADR(docs/adr/)에 기록 필수. TDD+DDD+CA+CQRS 원칙 확인."
fi

# 5. 시크릿/환경변수 키워드 → leo secret 리마인드
if echo "$PROMPT" | grep -qiE 'api.?key|secret|token|password|credential|환경변수|env|인증.?키'; then
  HINTS="${HINTS}\n🔐 민감정보 감지 → \`leo secret add <name>\`으로 Keychain 저장 필수. 코드 하드코딩 절대 금지."
fi

# 6. 모호한 프롬프트 경고 (10자 미만)
PROMPT_LEN=${#PROMPT}
if [[ $PROMPT_LEN -lt 10 ]] && ! echo "$PROMPT" | grep -qE '^/'; then
  HINTS="${HINTS}\n⚠️ 프롬프트가 짧습니다. 구체적인 컨텍스트를 추가하면 결과가 좋아집니다."
fi

# 힌트가 있으면 출력
if [[ -n "$HINTS" ]]; then
  echo -e "$HINTS"
fi

exit 0
