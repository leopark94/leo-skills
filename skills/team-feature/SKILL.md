---
name: team-feature
description: "아키텍트-탐색-구현-검증 팀으로 피처를 개발하는 순차+병렬 팀 오케스트레이터"
disable-model-invocation: false
user-invocable: true
---

# /team-feature — 에이전트 팀 피처 개발

아키텍트 → 탐색 → 구현 → 검증(병렬) → 단순화 흐름으로 피처 개발.
`/sprint`의 하네스 패턴과 달리 **각 단계에 전문 에이전트 팀**을 투입.

## 사용법

```
/team-feature <기능 설명>
/team-feature --spec <spec-file.md>    # 스펙 파일 기반
```

## 팀 구성 & 실행 흐름

```
Phase 1: 설계 (순차)
  architect ──→ 블루프린트 출력
       ↓
Phase 2: 탐색 (순차)
  explorer ──→ 기존 코드 분석 출력
       ↓
Phase 3: 구현 (메인 컨텍스트)
  [사용자 + Claude 직접 구현]
       ↓
Phase 4: 검증 (병렬)
  ┌─ test-analyzer ──→ 테스트 분석
  ├─ error-hunter ──→ 에러 핸들링 분석
  ├─ type-analyzer ──→ 타입 설계 분석
  └─ reviewer ──→ 코드 품질 분석
       ↓
Phase 5: 정리 (순차)
  simplifier ──→ 단순화 제안
       ↓
Phase 6: 마무리
  사용자 승인 → 커밋
```

## 상세 프로세스

### Phase 1: 아키텍처 설계

```
Agent(
  prompt: "다음 기능을 위한 아키텍처 블루프린트를 설계해줘: {feature_description}
    - 기존 코드베이스 패턴 분석
    - 생성/수정할 파일 목록
    - 컴포넌트 설계, 데이터 흐름
    - 빌드 순서
    프로젝트: {project_root}
    CLAUDE.md: {claude_md_path}",
  name: "architect"
)
```

아키텍트 결과를 사용자에게 보여주고 **승인 대기**.
승인 후 다음 단계 진행.

### Phase 2: 코드베이스 탐색

```
Agent(
  prompt: "아키텍트가 제안한 블루프린트를 기반으로 관련 기존 코드를 분석해줘:
    블루프린트: {architect_output}
    - 수정 대상 파일의 현재 구조
    - 유사 기능의 기존 구현 패턴
    - 의존성 관계
    프로젝트: {project_root}",
  name: "explorer"
)
```

탐색 결과를 메인 컨텍스트에 요약 주입.

### Phase 3: 구현

**에이전트가 아닌 메인 컨텍스트에서 직접 구현.**

```
1. 블루프린트의 빌드 순서대로 구현
2. 각 단계 후 빌드 확인 (npm run build / 프로젝트 빌드 명령)
3. 빌드 실패 시 다음 단계 진행 금지
4. 구현 완료 후 Phase 4로
```

### Phase 4: 병렬 검증

구현 완료 후, **4개 에이전트를 동시에 스폰하여 검증:**

```
Agent(test-analyzer 역할, run_in_background: true, name: "verify-tests")
Agent(error-hunter 역할, run_in_background: true, name: "verify-errors")
Agent(type-analyzer 역할, run_in_background: true, name: "verify-types")
Agent(reviewer 역할, run_in_background: true, name: "verify-quality")
```

각 에이전트에게 전달할 정보:
- 아키텍트 블루프린트 (원래 의도)
- 변경된 파일 목록과 diff
- 프로젝트 CLAUDE.md

### Phase 5: 검증 결과 분석 & 정리

```
4개 에이전트 결과를 수집:
1. Critical 이슈가 있으면 → Phase 3으로 돌아가 수정 (최대 3회)
2. Critical 없으면 → simplifier 에이전트 스폰

Agent(
  prompt: "다음 변경사항을 단순화할 기회를 분석해줘:
    변경된 파일: {file_list}
    - 불필요한 복잡성 제거
    - 가독성 개선
    기능은 반드시 보존",
  name: "simplifier"
)
```

### Phase 6: 마무리

```markdown
## Team Feature 완료 보고

### 구현 요약
- 기능: {feature_name}
- 생성 파일: {n}개
- 수정 파일: {n}개

### 검증 결과
| 에이전트 | 판정 | 이슈 |
|----------|------|------|
| test-analyzer | PASS/FAIL | {요약} |
| error-hunter | PASS/FAIL | {요약} |
| type-analyzer | PASS/FAIL | {요약} |
| reviewer | PASS/FAIL | {요약} |

### 단순화 적용
- {적용한 단순화 목록}

### 커밋 준비 완료?
→ 사용자 승인 대기
```

## /sprint와의 차이

| 항목 | /sprint | /team-feature |
|------|---------|---------------|
| 계획 | Planner (추상적) | Architect (구체적 블루프린트) |
| 구현 | Generator (단일) | 메인 컨텍스트 (직접) |
| 평가 | Evaluator (라이브 테스트) | 4개 전문 에이전트 (병렬 정적 분석) |
| 정리 | 없음 | Simplifier |
| 반복 | Eval-Gen 루프 | Critical 시에만 재구현 |
| 적합성 | 대규모 다중 스프린트 | 단일 피처 정밀 구현 |

## 규칙

- Phase 1 아키텍트 결과는 반드시 **사용자 승인** 후 진행
- Phase 4 검증은 반드시 **4개 에이전트 동시 스폰**
- Phase 3 → Phase 4 → Phase 3 루프는 **최대 3회**
- 빌드 실패 시 다음 Phase 진행 금지
- 각 Phase 전환 시 사용자에게 진행 상황 보고
