---
name: review
description: "변경사항을 품질/보안/성능 관점에서 체계적 리뷰"
disable-model-invocation: false
user-invocable: true
---

# /review — 코드 리뷰

변경사항을 3개 관점에서 병렬 리뷰 (Anthropic Parallelization 패턴).

## 사용법

```
/review              # staged + unstaged 변경사항 리뷰
/review <file>       # 특정 파일 리뷰
/review --pr <n>     # PR 리뷰
```

## 리뷰 관점 (병렬)

### 1. 코드 품질
- 네이밍, 구조, 중복, 복잡도
- leo-* 프로젝트 규칙 준수 (MASTER.md)
- CLAUDE.md 컨벤션 준수

### 2. 보안
- OWASP Top 10
- 민감정보 노출
- 인젝션 취약점
- 인증/인가 누락

### 3. 성능 + 테스트
- N+1 쿼리, 메모리 누수
- 테스트 커버리지
- 엣지 케이스

## 출력

```markdown
## 리뷰 결과

### Must Fix 🔴 (merge 차단)
- ...

### Should Fix 🟡 (권장)
- ...

### Nit 🟢 (선택)
- ...

### 👍 잘된 부분
- ...

### 요약: APPROVE / REQUEST CHANGES
```
