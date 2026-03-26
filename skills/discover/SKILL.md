---
name: discover
description: "GitHub에서 Claude Code 커뮤니티 스킬/에이전트/훅을 검색하고 설치"
disable-model-invocation: false
user-invocable: true
---

# /discover — 커뮤니티 스킬 검색 & 설치

GitHub에서 Claude Code 스킬, 에이전트, 훅을 검색하고 설치.
레지스트리(`registry/REGISTRY.md`)를 먼저 확인하고, 없으면 GitHub 실시간 검색.

## 사용법

```
/discover                     # 인기 스킬 목록
/discover <keyword>           # 키워드 검색 (security, planning, hooks, ...)
/discover install <repo>      # 특정 레포에서 스킬 설치
/discover update              # 레지스트리 업데이트 (GitHub 최신 검색)
```

## 검색 프로세스

### 1. 로컬 레지스트리 검색
```bash
# registry/REGISTRY.md에서 키워드 매칭
grep -i "$KEYWORD" ~/utils/leo-skills/registry/REGISTRY.md
```

### 2. GitHub 실시간 검색 (로컬에 없을 때)
```bash
# GitHub API로 스킬 레포 검색
gh search repos "claude code $KEYWORD skills" --sort stars --limit 10 --json name,url,description,stargazersCount

# 또는 topic 기반
gh search repos --topic claude-code-skills --sort stars --limit 10
```

### 3. 설치
```bash
# 임시 디렉토리에 클론
gh repo clone <owner>/<repo> /tmp/claude-skill-<repo>

# 스킬 구조 확인
ls /tmp/claude-skill-<repo>/skills/ 2>/dev/null
ls /tmp/claude-skill-<repo>/agents/ 2>/dev/null
ls /tmp/claude-skill-<repo>/hooks/ 2>/dev/null

# 선택적 복사 (사용자 승인 후)
cp -r /tmp/claude-skill-<repo>/skills/<name> ~/.claude/skills/
cp -r /tmp/claude-skill-<repo>/agents/<name>.md ~/.claude/agents/
```

## 추천 스킬 (즉시 설치 가능)

### 필수급
| 스킬 | 소스 | 이유 |
|------|------|------|
| planning-with-files | OthmanAdi | 17.2K stars, 96.7% 벤치마크 |
| taskmaster | blader | 에이전트 조기 종료 방지 Stop 훅 |
| prompt-improver | severity1 | 모호한 프롬프트 자동 개선 |

### 보안
| 스킬 | 소스 | 이유 |
|------|------|------|
| trailofbits/skills | Trail of Bits | 업계 최고 보안 연구소의 스킬셋 |

### 개발 워크플로우
| 스킬 | 소스 | 이유 |
|------|------|------|
| superpowers | obra | TDD 기반 자율 개발, 시간 단위 자율 실행 |
| context-engineering-kit | NeoLabHQ | Spec-Driven Development |

## 규칙

- 설치 전 README 확인 (보안 점검)
- 훅은 설치 전 스크립트 내용 확인 필수
- 충돌하는 스킬 이름 확인
- 설치 후 REGISTRY.md에 기록
