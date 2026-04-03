---
name: sprint
description: "Anthropic 삼중 에이전트 하네스로 기능 구현 — 상황에 따라 전문 에이전트 자동 투입"
disable-model-invocation: false
user-invocable: true
---

# /sprint — 삼중 에이전트 하네스 + 자동 팀 확장

Anthropic "Harness Design" 패턴 기반.
복잡도에 따라 전문 에이전트를 **자동으로 투입**하여 품질 강화.

## 사용법

```
/sprint <기능 설명>
```

## Step 0: 모드 결정

**기본값은 STANDARD (팀 모드).** 솔로로 하려면 명시적 opt-out 필요.

```
STANDARD 모드 [기본값]:
  → Architect 에이전트 투입 (구체적 블루프린트)
  → 구현 완료 후 검증팀 병렬 스폰
  → Simplifier로 정리

FULL 모드 (자동 승격 또는 --full):
  → Architect + Explorer 선행
  → 각 스프린트 완료 시 검증팀 스폰
  → Security Auditor 추가 투입
  → Simplifier로 정리

LIGHT 모드 (--light 명시 시에만):
  → 기존 하네스 (Planner → Generator → Evaluator)
  → 전문 에이전트 없음
```

자동 승격 조건 (STANDARD → FULL):
- 5+ 스프린트 예상
- 인증/보안/결제 관련
- 새 아키텍처 패턴 도입

**LIGHT는 사용자가 `/sprint --light`로 명시한 경우에만.** 그 외 모든 경우 STANDARD 이상.
모드를 사용자에게 한 줄로 알리고 바로 진행.

## LIGHT 모드

기존 하네스 동일:

```
Phase 1: Planner → 스펙 → 사용자 승인
Phase 2: Generator (스프린트 구현)
Phase 3: Evaluator (라이브 테스트)
Phase 4: 커밋
```

## STANDARD 모드

### Phase 1: 설계

Architect 에이전트 스폰:
```
→ 기존 코드 패턴 분석
→ 구체적 블루프린트 (파일목록, 컴포넌트, 데이터흐름, 빌드순서)
→ 사용자 승인 대기
```

Planner가 "무엇을"이라면 Architect는 "어떻게"까지.
블루프린트에 유사 기존 파일을 레퍼런스로 포함.

### Phase 2: 구현 (스프린트 단위)

각 스프린트마다:
1. 블루프린트의 빌드 순서대로 구현
2. 빌드 확인
3. 빌드 실패 시 다음 스프린트 진행 금지

### Phase 3: 검증팀 투입

모든 스프린트 구현 완료 후, **4개 에이전트 동시 스폰:**

```
Agent(name: "verify-quality", run_in_background: true)
  → reviewer 역할: 코드 품질, 네이밍, 구조, leo-* 규칙

Agent(name: "verify-tests", run_in_background: true)
  → test-analyzer 역할: 테스트 커버리지, 누락 케이스

Agent(name: "verify-errors", run_in_background: true)
  → error-hunter 역할: 사일런트 에러, 빈 catch, 에러 삼킴

Agent(name: "verify-types", run_in_background: true)
  → type-analyzer 역할: 타입 설계 품질 (새 타입이 있을 때만)
```

4개 에이전트를 **하나의 메시지에서 동시에 스폰**.
새 타입이 없으면 verify-types 생략 (3개만 스폰).

### Phase 4: 결과 처리

```
검증 결과 수집:
  Critical 이슈 있음 → Phase 2로 복귀하여 수정 (최대 3회)
  Critical 없음 → Simplifier 에이전트 스폰
    → 단순화 제안 검토 → 적용 → 커밋
```

### Phase 5: 마무리

```markdown
## Sprint 완료 보고

### 모드: STANDARD
### 투입 에이전트: architect, reviewer, test-analyzer, error-hunter, [type-analyzer], simplifier

### 구현 요약
- ...

### 검증 결과
| 에이전트 | 판정 | 주요 발견 |
|----------|------|----------|
| reviewer | PASS | ... |
| test-analyzer | PASS | ... |
| error-hunter | PASS | ... |
| type-analyzer | PASS | ... |

### 단순화 적용
- ...

### 커밋 준비?
```

## FULL 모드

STANDARD에 추가:

### Phase 1 확장: Architect + Explorer

```
Agent(name: "architect") → 블루프린트
Agent(name: "explorer") → 기존 코드 분석 (아키텍트 결과 기반)
두 결과를 사용자에게 통합 보고 → 승인
```

### Phase 3 확장: 보안 감사 추가

검증팀이 5개로 확장:
```
기존 4개 + Agent(name: "verify-security", run_in_background: true)
  → security-auditor 역할: OWASP Top 10 감사
```

### 스프린트별 검증

FULL 모드에서는 **각 스프린트 완료 시마다** 검증팀 투입 (마지막에만이 아님).
단, 비용 절감을 위해 각 스프린트에서는 reviewer + error-hunter 2개만 스폰.
마지막 스프린트 완료 후에만 5개 전체 스폰.

## 비용 가이드

| 모드 | 예상 비용 | 예시 |
|------|-----------|------|
| LIGHT | $5-15 | API 엔드포인트 1개, 간단한 버그 수정 |
| STANDARD | $20-60 | 새 서비스 모듈, CRUD, 대시보드 컴포넌트 |
| FULL | $80-200+ | 인증 시스템, 결제 연동, 대규모 리팩토링 |

## 회로 차단기 (Circuit Breaker)

```
실패 1회 → 경고 + 접근 방식 전환
실패 2회 → 강한 경고 + 근본 원인 재분석
실패 3회 → 자동 중단 + 사용자에게 상황 보고
```

중단 후 사용자가 명시적으로 재개 지시해야 계속.

## 에이전트 토큰 예산

에이전트 결과가 메인 컨텍스트를 과도하게 소비하지 않도록 압축 강제:

| 에이전트 | 최대 토큰 | 형식 |
|----------|----------|------|
| architect | 2000 | 블루프린트 요약 |
| 검증팀 각각 | 800 | Critical/High만 |
| simplifier | 500 | 변경 제안 목록만 |

## 규칙

- 하나의 기능 = 하나의 세션
- 빌드 실패 시 다음 스프린트/Phase 진행 금지
- **3번 연속 실패 → 회로 차단기 발동 (자동 중단)**
- 검증팀은 반드시 **동시 스폰** (순차 금지)
- 모드 판단 결과를 사용자에게 **먼저 보여주고 승인** 후 진행
- Critical 이슈 수정 루프는 최대 3회
- 에이전트 결과는 토큰 예산 내로 압축
- **아키텍처 결정 시 ADR 파일 필수 생성** (docs/adr/)
- **민감정보 발견 시 `leo secret` 강제** (코드 하드코딩 절대 금지)
