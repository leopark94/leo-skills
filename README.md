# Leo Master Skills

Claude Code 마스터 에이전트/스킬/훅 레퍼런스 시스템.

Anthropic Engineering 블로그 전체 패턴 + 커뮤니티 베스트프랙티스 + leo-* 프로젝트 학습을 통합한 범용 Claude Code 설정.

## 설치

```bash
cd ~/utils/leo-skills
./scripts/install.sh
```

## 구성

### 훅 (7개)

| 이벤트 | 훅 | 설명 |
|--------|-----|------|
| SessionStart(startup\|resume) | session-checklist | 세션 시작 체크리스트 + 마스터 참조 알림 |
| SessionStart(compact) | compact-reinject | Compaction 후 핵심 규칙 재주입 |
| PreToolUse(Edit\|Write) | detect-secrets | 민감정보 탐지 → 차단 → `leo secret` 안내 |
| PreToolUse(Edit\|Write) | protect-files | .env, lock파일, .git 편집 차단 |
| PostToolUse(Edit\|Write) | auto-format | prettier/black/shfmt 자동 포맷팅 |
| Notification | notify | macOS 알림 (터미널 안 봐도 됨) |
| Stop | stop-loop-guard | 무한 루프 방지 + 종료 알림 |

### 에이전트 (5개)

| 에이전트 | 모델 | 설명 |
|----------|------|------|
| planner | opus | 기능 스펙 → 상세 구현 계획 (스프린트 분해) |
| evaluator | opus | 라이브 테스트 + 품질 평가 (회의적 시각) |
| security-reviewer | opus | OWASP 기반 보안 취약점 검토 |
| explorer | sonnet | 코드베이스 빠른 탐색 + 요약 (fork 컨텍스트) |
| debugger | opus | 경쟁 가설 패턴으로 체계적 버그 진단 |
| reviewer | sonnet | 품질/보안/성능 병렬 코드 리뷰 (fork 컨텍스트) |

### 스킬 (5개)

| 스킬 | 설명 |
|------|------|
| `/sprint` | 삼중 에이전트 하네스로 기능 구현 |
| `/investigate` | 경쟁 가설 패턴 버그 진단 |
| `/review` | 3-관점 병렬 코드 리뷰 |
| `/guard` | MASTER.md 준수 확인 체크리스트 |
| `/progress` | JSON 기반 멀티세션 진행 추적 |

## 기반 소스

- [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Building a C Compiler with Parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler)
- [Claude Code Auto Mode](https://www.anthropic.com/engineering/claude-code-auto-mode)
- [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [The "think" Tool](https://www.anthropic.com/engineering/claude-think-tool)
- [Writing Effective Tools for Agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
- 30 Tips for Claude Code Agent Teams (Reddit/Substack)
- Awesome Claude Code (GitHub)

## 업데이트

```bash
./scripts/sync.sh  # git pull + 재설치
```

## 제거

```bash
./scripts/uninstall.sh
```
