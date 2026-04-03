---
name: review
description: "변경사항 규모에 따라 단일 리뷰 또는 전문 에이전트 팀 리뷰를 자동 선택"
disable-model-invocation: false
user-invocable: true
---

# /review — 코드 리뷰 (자동 팀 확장)

변경사항 규모와 성격을 분석하여 **자동으로 리뷰 깊이를 결정**.

## 사용법

```
/review                    # staged + unstaged 리뷰
/review <file>             # 특정 파일 리뷰
/review --pr <n>           # PR 리뷰
/review --deep             # 강제 팀 리뷰
/review --quick            # 강제 단일 리뷰
```

## Step 0: 모드 결정

**기본값은 STANDARD (팀 모드).** 솔로로 하려면 명시적 opt-out 필요.

```bash
# 변경 규모 파악
git diff --stat
git diff --numstat
```

### STANDARD 모드 [기본값]
→ reviewer + 상황별 전문 에이전트 선택 스폰 (최소 2개)

### DEEP 모드 (자동 승격 또는 --deep)
자동 승격 조건:
- 변경 파일 10개 초과
- 변경 라인 500줄 초과
- 인증/보안/결제 관련 파일 포함

→ 5개 전문 에이전트 전체 병렬 스폰

### QUICK 모드 (--quick 명시 시에만)
→ 메인 컨텍스트에서 직접 리뷰 (에이전트 스폰 없음)

**QUICK은 사용자가 `/review --quick`으로 명시한 경우에만.** 그 외 모든 경우 STANDARD 이상.

## QUICK 모드 실행

에이전트 스폰 없이 메인 컨텍스트에서 직접:

```markdown
## 리뷰 결과

### Must Fix
- ...

### Should Fix
- ...

### Nit
- ...

### 잘된 부분
- ...

### 판정: APPROVE / REQUEST CHANGES
```

## STANDARD 모드 실행

변경사항 성격에 따라 **필요한 에이전트만 선택적 스폰**:

```
항상 스폰:
  Agent(name: "review-quality", run_in_background: true)
    → reviewer: 코드 품질 + leo-* 규칙

조건부 스폰:
  새 타입/인터페이스 있으면:
    Agent(name: "review-types", run_in_background: true)
      → type-analyzer: 타입 설계 분석

  try-catch/에러 핸들링 변경 있으면:
    Agent(name: "review-errors", run_in_background: true)
      → error-hunter: 사일런트 에러 탐지

  테스트 파일 미포함인데 소스 변경 있으면:
    Agent(name: "review-tests", run_in_background: true)
      → test-analyzer: 테스트 커버리지 분석
```

선택된 에이전트를 **하나의 메시지에서 동시 스폰**.

결과 통합:
```markdown
## 리뷰 결과 (STANDARD — {N}개 에이전트)

### 투입 에이전트
- [x] reviewer (코드 품질)
- [x] type-analyzer (타입 설계) ← 새 인터페이스 감지
- [ ] error-hunter — 해당 없음
- [ ] test-analyzer — 테스트 포함됨

### Must Fix
{통합 Critical 이슈}

### Should Fix
{통합 Warning 이슈}

### Nit
{통합}

### 잘된 부분
{통합}

### 판정: APPROVE / REQUEST CHANGES
```

## DEEP 모드 실행

5개 에이전트 전체 병렬 스폰:

```
Agent(name: "review-quality", run_in_background: true)    → reviewer
Agent(name: "review-types", run_in_background: true)      → type-analyzer
Agent(name: "review-tests", run_in_background: true)      → test-analyzer
Agent(name: "review-errors", run_in_background: true)     → error-hunter
Agent(name: "review-security", run_in_background: true)   → security-auditor
```

5개를 **하나의 메시지에서 동시 스폰**.

결과 통합:
```markdown
## 리뷰 결과 (DEEP — 5개 에이전트)

### 참여 에이전트
- [x] reviewer: 완료
- [x] type-analyzer: 완료
- [x] test-analyzer: 완료
- [x] error-hunter: 완료
- [x] security-auditor: 완료

### Critical (Must Fix)
{모든 에이전트 Critical 통합, 중복 제거}

### High (Should Fix)
{통합}

### Medium (Nit)
{통합}

### 잘된 부분
{통합}

### 판정: APPROVE / REQUEST CHANGES
- Critical 1개 이상 → REQUEST CHANGES
```

## 리뷰 완료 후: 마커 정리

리뷰가 끝나면 반드시 다음 명령을 실행하여 커밋 차단 마커를 제거:

```bash
rm -f .claude-needs-review .claude-edit-count
```

이 마커가 남아있으면 pre-commit-guard 훅이 git commit을 차단함.

## 규칙

- 모드 판단 결과를 사용자에게 **먼저 한 줄로 알림** ("STANDARD 모드 (변경 8파일/320줄, 새 타입 감지)")
- 에이전트 결과 통합 시 **중복 이슈 제거**
- QUICK에서도 보안 키워드(auth, token, password, secret, permission) 감지 시 → STANDARD로 자동 승격
- 사용자가 `--deep`/`--quick` 으로 강제 지정 가능
- **리뷰 완료 후 반드시 `.claude-needs-review`, `.claude-edit-count` 마커 파일 삭제**
