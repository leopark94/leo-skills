---
name: investigate
description: "경쟁 가설 패턴으로 문제 진단 — 복잡한 버그는 병렬 에이전트 자동 투입"
disable-model-invocation: false
user-invocable: true
---

# /investigate — 경쟁 가설 진단 (자동 팀 확장)

Anthropic 권장 디버깅 패턴.
버그 복잡도에 따라 순차 검증 또는 **병렬 에이전트 팀 자동 투입**.

## 사용법

```
/investigate <문제 설명>
/investigate --parallel            # 강제 병렬 모드
/investigate --error "<에러 메시지>"
```

## Step 0: 모드 결정

**기본값은 PARALLEL (팀 모드).** 순차로 하려면 명시적 opt-out 필요.

### PARALLEL 모드 [기본값]
→ 각 가설을 별도 에이전트에 배정하여 동시 검증
→ Explorer로 증상 수집 선행

### SERIAL 모드 (--serial 명시 시에만)
→ 메인 컨텍스트에서 순차적으로 가설 검증
→ 비용 절감 목적

**SERIAL은 사용자가 `/investigate --serial`로 명시한 경우에만.** 그 외 모든 경우 PARALLEL.
모드를 사용자에게 한 줄로 알리고 바로 진행.

## 공통: 증상 수집

### Explorer 에이전트 투입 (PARALLEL 모드만)

```
Agent(name: "symptom-collector")
  → 에러 메시지/스택 트레이스
  → 관련 파일과 코드 경로
  → 최근 변경사항 (git log)
  → 환경 정보
  → 재현 조건
```

### 직접 수집 (SERIAL 모드)

메인 컨텍스트에서 직접:
```bash
git log --oneline -10
git diff
# 에러 로그 확인
# 환경 정보 확인
```

## 공통: 가설 수립 (최소 5개)

```markdown
| # | 가설 | 확률 | 검증 방법 | 검증 명령/파일 |
|---|------|------|-----------|---------------|
| 1 | {가설} | 40% | {방법} | {명령} |
| 2 | {가설} | 25% | {방법} | {명령} |
| 3 | {가설} | 15% | {방법} | {명령} |
| 4 | {가설} | 10% | {방법} | {명령} |
| 5 | {가설} | 10% | {방법} | {명령} |
```

가설은 **서로 독립적으로 검증 가능해야** 함 (PARALLEL 모드의 전제조건).

## SERIAL 모드 실행

확률 높은 가설부터 순차 검증:

```
for each hypothesis (by probability desc):
  1. 검증 명령 실행
  2. 결과 기록: CONFIRMED / REJECTED / INCONCLUSIVE
  3. CONFIRMED → 즉시 수정 단계로
  4. 2개 연속 REJECTED → 새 가설 추가 고려
```

## PARALLEL 모드 실행

### 병렬 가설 검증

5개 가설 각각에 에이전트 동시 스폰:

```
Agent(name: "hypothesis-1", run_in_background: true)
  → "가설: {h1}, 검증방법: {m1}, 관련파일: {files}
     판정: CONFIRMED/REJECTED/INCONCLUSIVE + 근거"

Agent(name: "hypothesis-2", run_in_background: true)
  → 동일 구조

... (5개 동시)
```

**5개를 하나의 메시지에서 동시 스폰.**

### 결과 수집

```
모든 에이전트 완료 후:
  CONFIRMED 있음 → 가장 확률 높은 CONFIRMED 기반 수정
  여러 CONFIRMED → 근본 원인 분석 (연관 가능성)
  모두 REJECTED → 추가 가설 수립 (Phase 2 복귀, 최대 2회)
  INCONCLUSIVE만 → 추가 정보 수집 필요 (사용자에게 질문)
```

## 공통: 수정 & 검증

```
수정:
  - 최소한의 변경으로 root cause만 수정
  - 수정 전 git stash 또는 상태 확인
  - 관련 없는 코드 수정 금지

검증:
  - 빌드 확인
  - 원래 에러 재현 시도 (더 이상 발생하지 않아야 함)
  - 관련 테스트 실행
```

## 공통: 보고

```markdown
## 진단 결과

### 모드: {SERIAL / PARALLEL}
### 투입 에이전트: {있으면 목록}

### 원인
{확인된 근본 원인}

### 가설 검증 결과
| # | 가설 | 확률 | 판정 | 핵심 근거 |
|---|------|------|------|----------|
| 1 | ... | 40% | CONFIRMED | ... |
| 2 | ... | 25% | REJECTED | ... |
| ... | ... | ... | ... | ... |

### 수정 내용
| 파일 | 변경 | 이유 |
|------|------|------|
| ... | ... | ... |

### 검증
- [x] 빌드 통과
- [x] 에러 해결 확인
- [x] 회귀 없음

### 기각된 가설 (참고)
{향후 디버깅 참고용}
```

## 규칙

- 가설은 반드시 **5개 이상** (터널 비전 방지)
- 모드 판단 결과를 사용자에게 **먼저 알림**
- 2번 연속 같은 수정 실패 → 접근 방식 전환
- PARALLEL 루프 (가설 전체 기각 → 재수립) 최대 2회
- 수정은 **root cause만** — 증상 치료 금지
- brute force 금지 — 반드시 가설 기반
