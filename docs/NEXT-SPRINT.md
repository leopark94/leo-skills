# Next Sprint: 에이전트/스킬 영어 전환 + 품질 강화

## 목표

16개 에이전트 + 9개 스킬 전체를 영어로 전환하면서 품질 대폭 강화.

## 이유

1. Claude 학습 데이터 영어 위주 → 영어 지시를 더 정확히 따름
2. 토큰 효율 1.5~2배 개선
3. 커뮤니티 공유 가능
4. 코드 키워드와 언어 일치 → 파싱 효율

## 스프린트 범위

### Sprint 1: 작성 계열 에이전트 (developer, test-writer)
- 영어 전환
- DDD 레이어별 구현 템플릿 구체화
- TDD 사이클 단계별 상세 지시
- 프로젝트 타입별 분기 (TS/Python/zsh)

### Sprint 2: 설계 계열 에이전트 (architect, planner)
- 영어 전환
- architect: 규모별 DDD 템플릿 (소/중/대) 구체화
- planner: 성공 기준 자동 생성 패턴
- ADR 생성 프로세스 자동화

### Sprint 3: 분석 계열 에이전트 (reviewer, type-analyzer, test-analyzer, error-hunter, simplifier, security-auditor)
- 영어 전환
- 각 에이전트의 체크리스트 확장
- confidence-based filtering 강화
- 프로젝트 타입별 룰 분기

### Sprint 4: 실행 + 운영 계열 (evaluator, debugger, explorer, release-coordinator, incident-commander, perf-monitor)
- 영어 전환
- evaluator: Playwright 통합 패턴
- debugger: 가설 템플릿 자동 생성
- 운영 에이전트: leo-bot/secretary 도메인 지식 내장

### Sprint 5: 스킬 전환 + 오케스트레이션 강화
- 9개 스킬 영어 전환
- /sprint: developer + test-writer 통합 (TDD 사이클)
- /team-feature: 전체 팀 흐름 재설계
- /team-review: 16개 에이전트 중 상황별 최적 조합

### Sprint 6: 훅 + 문서 + 테스트
- 훅 메시지 영어 전환
- MASTER.md 영어 전환
- README.md 영어 전환
- 각 에이전트 smoke test

## 실행 방법

```bash
cd ~/utils/leo-skills
# 새 세션에서
/sprint "Convert all 16 agents + 9 skills to English with quality enhancement"
```

## 예상

- 모드: FULL (6 스프린트)
- 비용: $100-150
- 시간: 3-4시간
