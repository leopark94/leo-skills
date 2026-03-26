---
name: progress
description: "멀티세션 작업 진행 상황을 JSON 파일로 추적"
disable-model-invocation: false
user-invocable: true
---

# /progress — 진행 추적

Anthropic 권장 멀티세션 진행 추적 패턴.
JSON 형식으로 기능 목록 관리 (마크다운보다 모델 오염 가능성 낮음).

## 사용법

```
/progress                    # 현재 진행 상황 표시
/progress init <기능 목록>    # 새 진행 파일 생성
/progress update <id> pass   # 기능 상태 업데이트
/progress summary            # 세션 요약 추가
```

## 파일 형식

`claude-progress.json`:

```json
{
  "project": "leo-bot",
  "created": "2026-03-26",
  "features": [
    {
      "id": 1,
      "name": "Sentry 연동",
      "status": "pass",
      "sprint": 1,
      "notes": "API 연동 완료"
    },
    {
      "id": 2,
      "name": "GitHub Issue 자동 생성",
      "status": "in_progress",
      "sprint": 2,
      "notes": ""
    }
  ],
  "sessions": [
    {
      "date": "2026-03-26",
      "focus": "Sentry API 연동",
      "completed": [1],
      "notes": "rate limit 이슈 해결"
    }
  ]
}
```

## 규칙

- 세션 시작 시 자동 로드
- 기능 완료 시 즉시 업데이트
- 세션 종료 시 요약 추가
- 200개+ 세부 기능 권장 (Anthropic 데이터)
