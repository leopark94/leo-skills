---
name: progress
description: "Tracks multi-session work progress via JSON file"
disable-model-invocation: false
user-invocable: true
---

# /progress — Progress Tracking

Anthropic-recommended multi-session progress tracking pattern.
Uses JSON format for feature list management (less susceptible to model corruption than markdown).

## Usage

```
/progress                    # show current progress
/progress init <feature list>  # create new progress file
/progress update <id> pass   # update feature status
/progress summary            # add session summary
```

## File Format

`claude-progress.json`:

```json
{
  "project": "leo-bot",
  "created": "2026-03-26",
  "features": [
    {
      "id": 1,
      "name": "Sentry integration",
      "status": "pass",
      "sprint": 1,
      "notes": "API integration complete"
    },
    {
      "id": 2,
      "name": "GitHub Issue auto-creation",
      "status": "in_progress",
      "sprint": 2,
      "notes": ""
    }
  ],
  "sessions": [
    {
      "date": "2026-03-26",
      "focus": "Sentry API integration",
      "completed": [1],
      "notes": "Rate limit issue resolved"
    }
  ]
}
```

## Rules

- Auto-load at session start
- Update immediately on feature completion
- Add summary at session end
- 200+ detailed features recommended (Anthropic data)
