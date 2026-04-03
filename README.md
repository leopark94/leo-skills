# Leo Master Skills

Claude Code 마스터 에이전트/스킬/훅 레퍼런스 시스템.

Anthropic Engineering 블로그 전체 패턴 + 커뮤니티 베스트프랙티스 + leo-* 프로젝트 학습을 통합한 범용 Claude Code 설정.

## 설치

```bash
cd ~/utils/leo-skills
./scripts/install.sh
```

## 시크릿 관리

시크릿은 **leo-cli의 `leo secret`** 커맨드로 관리 (이 프로젝트에 포함되지 않음).

```bash
leo secret add OPENAI_API_KEY      # Keychain 저장
leo secret get OPENAI_API_KEY      # 조회
leo secret check                   # .leo-secrets.yaml 기준 누락 확인
leo secret sync push               # 크로스 디바이스 동기화
```

세션 시작 훅이 `.leo-secrets.yaml` 매니페스트를 자동 체크하여 누락 시 경고.

## 구성

### 훅 (9개)

| 이벤트 | 훅 | 설명 |
|--------|-----|------|
| SessionStart(startup\|resume) | session-checklist | 세션 체크리스트 + **팀 퍼스트 원칙 주입** |
| SessionStart(compact) | compact-reinject | 핵심 규칙 + **팀 퍼스트 원칙 재주입** |
| PreToolUse(Edit\|Write) | detect-secrets | 민감정보 탐지 → 차단 → `leo secret` 안내 |
| PreToolUse(Edit\|Write) | protect-files | .env, lock파일, .git 편집 차단 |
| **PreToolUse(Bash)** | **pre-commit-guard** | **git commit 감지 → 리뷰 마커 확인 → 미실행 시 차단** |
| PostToolUse(Edit\|Write) | auto-format | prettier/black/shfmt 자동 포맷팅 |
| **PostToolUse(Edit\|Write)** | **edit-tracker** | **편집 횟수 추적 → 3회+ 시 리뷰 마커 생성** |
| Notification | notify | macOS 알림 (터미널 안 봐도 됨) |
| Stop | stop-loop-guard | 무한 루프 방지 + 종료 알림 |

### 에이전트 (11개)

#### 코어 에이전트 (하네스/워크플로우)

| 에이전트 | 모델 | 컨텍스트 | 설명 |
|----------|------|----------|------|
| planner | opus | full | 기능 스펙 → 상세 구현 계획 (스프린트 분해) |
| evaluator | opus | full | 라이브 테스트 + 품질 평가 (회의적 시각) |
| explorer | sonnet | fork | 코드베이스 빠른 탐색 + 요약 |
| debugger | opus | full | 경쟁 가설 패턴으로 체계적 버그 진단 |
| reviewer | sonnet | fork | 품질/보안/성능 병렬 코드 리뷰 |

#### 전문 에이전트 (팀 빌딩블록)

| 에이전트 | 모델 | 컨텍스트 | 설명 |
|----------|------|----------|------|
| architect | opus | full | 기존 패턴 분석 → 구체적 아키텍처 블루프린트 |
| type-analyzer | sonnet | fork | 타입 설계: 캡슐화, 불변식, 유용성, 강제성 분석 |
| test-analyzer | sonnet | fork | 테스트 커버리지 품질 + 누락 케이스 식별 |
| error-hunter | sonnet | fork | 사일런트 에러, 빈 catch, 위험한 폴백 사냥 |
| simplifier | sonnet | fork | 불필요한 복잡성 제거, 가독성 개선 제안 |
| security-auditor | opus | full | OWASP Top 10 기반 체계적 보안 감사 |

### 스킬 (9개)

#### 워크플로우 스킬 (자동 팀 확장)

복잡도를 자동 판단하여 필요한 전문 에이전트를 **알아서 투입**.

| 스킬 | 모드 | 설명 |
|------|------|------|
| `/sprint` | LIGHT / STANDARD / FULL | 기능 구현. 복잡도에 따라 architect, 검증팀(4-5에이전트), simplifier 자동 투입 |
| `/review` | QUICK / STANDARD / DEEP | 코드 리뷰. 변경 규모에 따라 전문 에이전트 선택적 스폰 (최대 5개 병렬) |
| `/investigate` | SERIAL / PARALLEL | 버그 진단. 복잡한 버그 시 가설별 에이전트 병렬 스폰 |

```
예: /sprint "OAuth 로그인 추가"
→ Step 0에서 자동 판단: "STANDARD 모드 (2-3 스프린트 예상, 인증 관련)"
→ Architect 투입 → 구현 → [reviewer + test-analyzer + error-hunter + security-auditor 병렬] → Simplifier
```

#### 명시적 팀 스킬 (직접 호출용)

자동 판단 없이 항상 풀 팀으로 실행하고 싶을 때:

| 스킬 | 팀 구성 | 설명 |
|------|---------|------|
| `/team-review` | 5 에이전트 병렬 | reviewer + type-analyzer + test-analyzer + error-hunter + security-auditor |
| `/team-feature` | 순차+병렬 하이브리드 | architect → explorer → 구현 → [4개 병렬 검증] → simplifier |
| `/team-debug` | 병렬 가설 검증 | explorer → 가설수립 → [5개 가설 병렬 검증] → 수정 |

#### 유틸리티 스킬

| 스킬 | 설명 |
|------|------|
| `/guard` | MASTER.md 준수 확인 체크리스트 |
| `/progress` | JSON 기반 멀티세션 진행 추적 |
| `/discover` | GitHub 커뮤니티 스킬 검색 & 설치 |

### 커뮤니티 스킬 레지스트리 (43+ 레포)

`registry/REGISTRY.md`에 43개+ GitHub 레포의 스킬/에이전트/훅 인덱스 보유.

```bash
# 검색
./scripts/discover.sh search security

# 인기 레포 목록
./scripts/discover.sh popular

# 특정 레포에서 설치
./scripts/discover.sh install trailofbits/skills

# 레지스트리 업데이트
./scripts/discover.sh update
```

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
