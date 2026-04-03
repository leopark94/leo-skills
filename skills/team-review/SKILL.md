---
name: team-review
description: "5개 전문 에이전트를 병렬로 스폰하여 다각도 코드 리뷰를 수행하는 팀 오케스트레이터"
disable-model-invocation: false
user-invocable: true
---

# /team-review — 에이전트 팀 코드 리뷰

5개 전문 에이전트를 **병렬로 동시 스폰**하여 다각도 코드 리뷰.
기존 `/review`의 단일 에이전트 방식 대비 훨씬 깊은 분석.

## 사용법

```
/team-review                    # git diff (staged + unstaged) 리뷰
/team-review <file>             # 특정 파일 리뷰
/team-review --pr <n>           # PR 리뷰
/team-review --commit <hash>    # 특정 커밋 리뷰
```

## 팀 구성 (5 에이전트, 병렬 스폰)

**모든 에이전트를 하나의 메시지에서 Agent tool로 동시에 스폰해야 함.**

### 에이전트 스폰 명세

#### 1. code-quality (reviewer 에이전트)
```
Agent(
  subagent: "reviewer" 에이전트의 역할 수행,
  prompt: "다음 변경사항의 코드 품질을 리뷰해줘: {diff_summary}
    - 네이밍, 구조, 중복, 복잡도
    - leo-* 프로젝트 규칙 (MASTER.md)
    - CLAUDE.md 컨벤션
    변경된 파일: {file_list}",
  run_in_background: true,
  name: "code-quality"
)
```

#### 2. type-review (type-analyzer 에이전트)
```
Agent(
  prompt: "다음 변경사항에서 타입/인터페이스 설계를 분석해줘: {diff_summary}
    - 캡슐화, 불변식, 유용성, 강제성 관점
    - 새로 추가/수정된 타입만 집중
    변경된 파일: {file_list}",
  run_in_background: true,
  name: "type-review"
)
```

#### 3. test-review (test-analyzer 에이전트)
```
Agent(
  prompt: "다음 변경사항의 테스트 커버리지를 분석해줘: {diff_summary}
    - 새 기능에 테스트가 충분한지
    - 엣지 케이스 누락 여부
    - 에러 경로 테스트 존재 여부
    변경된 파일: {file_list}",
  run_in_background: true,
  name: "test-review"
)
```

#### 4. error-review (error-hunter 에이전트)
```
Agent(
  prompt: "다음 변경사항에서 사일런트 에러와 부적절한 에러 핸들링을 찾아줘: {diff_summary}
    - 빈 catch, 에러 삼킴, 위험한 폴백
    - Promise 에러 무시
    - 리소스 정리 누락
    변경된 파일: {file_list}",
  run_in_background: true,
  name: "error-review"
)
```

#### 5. security-review (security-auditor 에이전트)
```
Agent(
  prompt: "다음 변경사항을 OWASP Top 10 기반으로 보안 감사해줘: {diff_summary}
    - 인증/인가, 인젝션, 데이터 노출
    - 변경된 코드 + 관련 보안 경계 함께 분석
    변경된 파일: {file_list}",
  run_in_background: true,
  name: "security-review"
)
```

## 실행 프로세스

### Step 1: 사전 데이터 수집 (Bash 단계 — 메인 컨텍스트)

에이전트 스폰 전에 **메인 컨텍스트에서 Bash로 데이터를 미리 수집**하여 에이전트 프롬프트에 포함.
(분석 에이전트는 Bash 없이 Read/Grep/Glob만 사용 → 도구 호출 최대 10개 병렬 배칭)

```bash
# 1. diff stat + 파일 목록
DIFF_STAT=$(git diff --stat)
FILE_LIST=$(git diff --name-only)

# 2. diff 내용 (변경 요약)
DIFF_CONTENT=$(git diff)

# 3. 새 타입/인터페이스 감지
NEW_TYPES=$(git diff | grep -E '^\+.*(interface|type|class|enum)\s')

# 4. 에러 핸들링 변경 감지
ERROR_CHANGES=$(git diff | grep -E '^\+.*(catch|throw|Error|reject|finally)')

# PR 모드면: gh pr diff <n>, gh pr view <n> --json files
```

이 데이터를 각 에이전트 프롬프트의 `{diff_summary}`, `{file_list}`에 주입.

### Step 2: 5개 에이전트 병렬 스폰

**반드시 하나의 메시지에서 5개 Agent tool을 동시에 호출.**
각 에이전트에게 사전 수집된 diff 데이터와 파일 목록을 전달.
모든 에이전트는 `run_in_background: true`로 실행.
에이전트는 Bash 없이 Read/Grep/Glob만 사용하므로 내부 도구 호출도 병렬 배칭.

### Step 3: 결과 수집 & 통합

모든 에이전트 완료 후 결과를 통합 보고서로 합침:

```markdown
## Team Review 결과

### 참여 에이전트
- [x] code-quality: 완료
- [x] type-review: 완료
- [x] test-review: 완료
- [x] error-review: 완료
- [x] security-review: 완료

### Critical (Must Fix)
{모든 에이전트의 Critical 이슈 통합, 중복 제거}

### High (Should Fix)
{모든 에이전트의 High 이슈 통합}

### Medium (Nit)
{모든 에이전트의 Medium 이슈 통합}

### Well Done
{잘된 부분 통합}

### 최종 판정: APPROVE / REQUEST CHANGES
- 기준: Critical 1개 이상 → REQUEST CHANGES
```

## 규칙

- 5개 에이전트는 반드시 **동시에** 스폰 (순차 금지)
- 각 에이전트는 **독립적으로** 분석 (에이전트 간 의존성 없음)
- 결과 통합 시 중복 이슈 제거
- Critical 이슈가 1개 이상이면 반드시 REQUEST CHANGES
- 프로젝트 CLAUDE.md가 있으면 각 에이전트에 전달
