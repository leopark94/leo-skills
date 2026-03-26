# Leo Master Skills

Claude Code 마스터 에이전트/스킬/훅 레퍼런스 시스템.
모든 leo-* 프로젝트는 이 레포를 참조해야 함.

## 구조

```
leo-skills/
├── CLAUDE.md           # 이 파일
├── MASTER.md           # 마스터 레퍼런스 (Anthropic 패턴 + 커뮤니티 베스트프랙티스)
├── hooks/              # 범용 훅 설정
│   ├── hooks.json      # 글로벌 훅 정의
│   └── scripts/        # 훅 실행 스크립트
├── agents/             # 범용 에이전트 정의
├── skills/             # 범용 스킬 정의
├── scripts/            # 유틸리티 스크립트
└── docs/               # 상세 문서
```

## 명령어

```bash
./scripts/install.sh    # 글로벌 설정에 훅/에이전트 등록
./scripts/sync.sh       # 업데이트 시 재동기화
```

## 규칙

- CLAUDE.md는 간결하게 유지 (이 파일 참고)
- 민감정보 발견 시 `leo secret`으로 강제 저장
- 훅은 반드시 테스트 후 등록
- 에이전트/스킬 추가 시 MASTER.md에 반영
