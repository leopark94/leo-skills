---
name: team-debug
description: "병렬 가설 검증 에이전트를 스폰하여 버그를 체계적으로 진단하는 팀 오케스트레이터"
disable-model-invocation: false
user-invocable: true
---

# /team-debug — 에이전트 팀 디버깅

경쟁 가설 패턴을 **병렬 에이전트**로 실행.
기존 `/investigate`의 순차 검증 대비 **동시에 여러 가설을 검증**.

## 사용법

```
/team-debug <문제 설명>
/team-debug --error "<에러 메시지>"
/team-debug --log <로그 파일 경로>
```

## 팀 구성 & 실행 흐름

```
Phase 1: 증상 수집 (순차)
  explorer ──→ 코드베이스 + 에러 컨텍스트 수집
       ↓
Phase 2: 가설 수립 (메인 컨텍스트)
  5개 이상 가설 + 확률 추정
       ↓
Phase 3: 병렬 검증 (동시 스폰)
  ┌─ hypothesis-1 ──→ 검증 결과
  ├─ hypothesis-2 ──→ 검증 결과
  ├─ hypothesis-3 ──→ 검증 결과
  ├─ hypothesis-4 ──→ 검증 결과
  └─ hypothesis-5 ──→ 검증 결과
       ↓
Phase 4: 판정 & 수정 (메인 컨텍스트)
  가장 유력한 가설 기반 최소 수정
       ↓
Phase 5: 검증 (순차)
  빌드 + 재현 테스트
```

## 상세 프로세스

### Phase 1: 증상 수집

```
Agent(
  prompt: "다음 버그의 증상을 수집해줘: {problem_description}
    - 에러 메시지/스택 트레이스
    - 관련 파일과 코드 경로
    - 최근 변경사항 (git log --oneline -10)
    - 환경 정보 (Node 버전, 의존성)
    - 재현 조건
    프로젝트: {project_root}",
  name: "symptom-collector"
)
```

### Phase 2: 가설 수립

증상 수집 결과를 바탕으로 **메인 컨텍스트에서** 가설 수립:

```markdown
| # | 가설 | 확률 | 검증 방법 | 검증 명령 |
|---|------|------|-----------|----------|
| 1 | {가설 내용} | 40% | {방법} | {명령} |
| 2 | {가설 내용} | 25% | {방법} | {명령} |
| 3 | {가설 내용} | 15% | {방법} | {명령} |
| 4 | {가설 내용} | 10% | {방법} | {명령} |
| 5 | {가설 내용} | 10% | {방법} | {명령} |
```

**가설은 서로 독립적으로 검증 가능해야 함.**

### Phase 3: 병렬 가설 검증

5개 가설 각각에 대해 에이전트를 동시 스폰:

```
Agent(
  prompt: "다음 가설을 검증해줘:
    가설: {hypothesis_N}
    검증 방법: {verification_method}
    검증 명령: {verification_command}
    
    증상 컨텍스트: {symptom_summary}
    관련 파일: {related_files}
    
    출력 형식:
    - 판정: CONFIRMED / REJECTED / INCONCLUSIVE
    - 근거: {구체적 증거}
    - 추가 발견: {검증 중 발견한 추가 정보}",
  run_in_background: true,
  name: "hypothesis-{N}"
)
```

**5개 에이전트를 반드시 하나의 메시지에서 동시에 스폰.**

### Phase 4: 판정 & 수정

```
1. 모든 가설 검증 결과 수집
2. CONFIRMED 가설이 있으면 → 해당 가설 기반 수정
3. 여러 CONFIRMED → 가장 확률 높은 것 우선
4. 모두 REJECTED → 추가 가설 수립 (Phase 2로 복귀, 최대 2회)
5. INCONCLUSIVE만 → 추가 정보 요청

수정 원칙:
- 최소한의 변경 (root cause만 수정)
- 관련 없는 코드 수정 금지
- 수정 전 git stash로 백업
```

### Phase 5: 검증

```bash
# 빌드 확인
{project_build_command}

# 원래 에러 재현 시도 → 더 이상 발생하지 않아야 함
{reproduction_steps}

# 관련 테스트 실행
{test_command}
```

## 출력 형식

```markdown
## Team Debug 결과

### 증상 요약
- 에러: {에러 메시지}
- 재현: {재현 조건}

### 가설 검증 결과
| # | 가설 | 확률 | 판정 | 핵심 근거 |
|---|------|------|------|----------|
| 1 | ... | 40% | CONFIRMED | {증거} |
| 2 | ... | 25% | REJECTED | {증거} |
| 3 | ... | 15% | REJECTED | {증거} |
| 4 | ... | 10% | INCONCLUSIVE | {이유} |
| 5 | ... | 10% | REJECTED | {증거} |

### Root Cause
- 확정 가설: #{N} — {가설 내용}
- 근본 원인: {상세 설명}

### 수정 내용
| 파일 | 변경 | 이유 |
|------|------|------|
| ... | ... | ... |

### 검증
- 빌드: PASS/FAIL
- 재현 테스트: PASS/FAIL
- 관련 테스트: PASS/FAIL

### 기각된 가설 (참고)
{각 기각 가설의 기각 이유 — 향후 디버깅 참고용}
```

## /investigate와의 차이

| 항목 | /investigate | /team-debug |
|------|-------------|-------------|
| 검증 | 순차적 (높은 확률부터) | 병렬 (모두 동시) |
| 속도 | 느림 (직렬) | 빠름 (병렬) |
| 컨텍스트 | 단일 (오염 위험) | 격리 (에이전트별 fork) |
| 비용 | 낮음 | 높음 (5x 에이전트) |
| 적합성 | 간단한 버그, 비용 절감 | 복잡한 버그, 빠른 진단 필요 |

## 규칙

- 가설은 반드시 **5개 이상** (터널 비전 방지)
- 가설은 **서로 독립적**이어야 함 (의존적 가설은 분리)
- 가설 검증 에이전트는 반드시 **동시 스폰**
- Phase 2 → Phase 3 루프는 **최대 2회**
- 수정은 **root cause만** — 증상 치료 금지
- 수정 전 반드시 `git stash` 또는 현재 변경사항 확인
