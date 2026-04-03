---
name: guard
description: "Runs MASTER.md compliance checklist before and after work"
disable-model-invocation: false
user-invocable: true
---

# /guard — Master Reference Compliance Check

Runs a MASTER.md-based checklist before/after work.
Used across all leo-* projects.

## Usage

```
/guard              # check current project
/guard --post       # post-work check
```

## Checklist

### Environment
- [ ] CLAUDE.md exists and is up to date
- [ ] No secrets in code (`leo secret` used properly)
- [ ] .env files in .gitignore

### Code Quality
- [ ] Logging: pino (TS) / log_* (zsh) — console.log forbidden
- [ ] Config: config.getSettings() — no hard-coded values
- [ ] Errors: withRetry() for external APIs — error suppression forbidden
- [ ] Build passes (`npm run build` / project build command)

### Git
- [ ] Conventional Commits format
- [ ] VERSION updated (on feature changes)
- [ ] CHANGELOG updated (on feature changes)

### Stability (Anthropic patterns)
- [ ] Single feature focus (One-Feature-Per-Session)
- [ ] Context not overloaded
- [ ] Switched approach after 2 failures

## On Failure

For each failed checklist item:
1. Suggest specific fix
2. Auto-fix if possible
3. Alert user if manual action needed
