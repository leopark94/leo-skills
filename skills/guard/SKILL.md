---
name: guard
description: "작업 전 MASTER.md 기반 준수 확인 체크리스트 실행"
disable-model-invocation: false
user-invocable: true
---

# /guard — 마스터 레퍼런스 준수 확인

작업 시작 전/후에 MASTER.md 기반 체크리스트 실행.
모든 leo-* 프로젝트에서 사용.

## 사용법

```
/guard              # 현재 프로젝트 체크
/guard --post       # 작업 완료 후 체크
```

## 체크리스트

### 환경
- [ ] CLAUDE.md 존재 및 최신
- [ ] 민감정보 코드 내 없음 (`leo secret` 사용)
- [ ] .env 파일 .gitignore에 포함

### 코드 품질
- [ ] 로깅: pino (TS) / log_* (zsh) — console.log 금지
- [ ] 설정: config.getSettings() — 하드코딩 금지
- [ ] 에러: withRetry() 외부 API — 에러 무시 금지
- [ ] 빌드 통과 (`npm run build` / 프로젝트 빌드 명령)

### Git
- [ ] Conventional Commits
- [ ] VERSION 업데이트 (기능 변경 시)
- [ ] CHANGELOG 업데이트 (기능 변경 시)

### 안정성 (Anthropic 패턴)
- [ ] 단일 기능에 집중 (One-Feature-Per-Session)
- [ ] 컨텍스트 과부하 아닌지 확인
- [ ] 2번 실패 시 접근 전환했는지

## 실패 시

체크리스트 미통과 항목에 대해:
1. 구체적 수정 사항 제안
2. 자동 수정 가능하면 수정
3. 사용자 확인 필요하면 알림
