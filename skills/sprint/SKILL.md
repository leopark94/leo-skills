---
name: sprint
description: "Anthropic 삼중 에이전트 하네스로 기능 구현 (Planner → Generator → Evaluator)"
disable-model-invocation: false
user-invocable: true
---

# /sprint — 삼중 에이전트 하네스 실행

Anthropic "Harness Design for Long-Running Apps" 패턴 구현.
하나의 기능을 Planner → Generator → Evaluator 흐름으로 안정적으로 구현.

## 사용법

```
/sprint <기능 설명>
```

## 프로세스

### Phase 1: Planning
1. CLAUDE.md, MASTER.md 읽기
2. 기존 코드베이스 탐색 (Explorer 에이전트)
3. 상세 구현 계획 수립 (Planner 에이전트)
4. 스프린트 분해 + 성공 기준 정의
5. 사용자 승인 대기

### Phase 2: Generation (스프린트 단위)
각 스프린트에 대해:
1. 성공 기준 확인
2. 구현
3. 빌드 확인 (`npm run build` 또는 프로젝트 빌드 명령)
4. 자체 기본 검증

### Phase 3: Evaluation
1. 라이브 앱/서버 테스트
2. 각 성공 기준 pass/fail 판정
3. FAIL 시 Generator에 구체적 피드백
4. 재구현 → 재평가 (최대 5회)

### Phase 4: Wrap-up
1. 전체 결과 요약
2. 커밋 (사용자 승인 시)
3. 다음 스프린트 또는 완료

## 비용/시간 가이드

| 규모 | 예상 시간 | 예상 비용 | 예시 |
|------|-----------|-----------|------|
| 단일 기능 (1 스프린트) | 15-30분 | $5-15 | API 엔드포인트 추가, 버그 수정 |
| 소규모 (2-3 스프린트) | 30분-1.5시간 | $15-40 | 새 서비스 모듈, CRUD 기능 |
| 중규모 (5-7 스프린트) | 2-4시간 | $50-130 | 인증 시스템, 대시보드 |
| 대규모 (10+ 스프린트) | 5-6시간 | $130-200 | 풀 앱 (Anthropic 블로그 수준) |

Evaluator 없이 삽질 → `/clear` 반복이 오히려 더 비쌀 수 있음.

## 규칙

- 하나의 기능 = 하나의 세션
- 빌드 실패 시 다음 스프린트 진행 금지
- 2번 연속 실패 시 접근 방식 전환
