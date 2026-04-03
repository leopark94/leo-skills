#!/bin/zsh
# prompt-guard.sh — UserPromptSubmit hook: prompt quality check + skill routing hints
# Detects ambiguous prompts, recommends relevant skills, reminds about architecture decisions

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[[ -z "$PROMPT" ]] && exit 0

HINTS=""

# 1. Bug/error keywords -> recommend /investigate
if echo "$PROMPT" | grep -qiE 'bug|error|broken|fix|crash|fail|not working|exception'; then
  HINTS="${HINTS}\nHint: Bug/error detected -> try /investigate (PARALLEL default, team hypothesis verification)"
fi

# 2. Feature implementation keywords -> recommend /sprint
if echo "$PROMPT" | grep -qiE 'implement|build|create|add|feature|develop|make'; then
  HINTS="${HINTS}\nHint: Feature implementation detected -> try /sprint (STANDARD default, architect + verification team)"
fi

# 3. Review keywords -> recommend /review
if echo "$PROMPT" | grep -qiE 'review|check|inspect|PR|pull request'; then
  HINTS="${HINTS}\nHint: Review request detected -> try /review (STANDARD default, team review)"
fi

# 4. Architecture keywords -> ADR reminder
if echo "$PROMPT" | grep -qiE 'architect|structure|design|pattern|monorepo|microservice|refactor.*large'; then
  HINTS="${HINTS}\nArchitecture decision detected -> must record in ADR (docs/adr/). Follow TDD+DDD+CA+CQRS principles."
fi

# 5. Secret/env keywords -> leo secret reminder
if echo "$PROMPT" | grep -qiE 'api.?key|secret|token|password|credential|env.?var'; then
  HINTS="${HINTS}\nSensitive info detected -> store via \`leo secret add <name>\` in Keychain. NEVER hard-code in source."
fi

# 6. Ambiguous prompt warning (under 10 chars)
PROMPT_LEN=${#PROMPT}
if [[ $PROMPT_LEN -lt 10 ]] && ! echo "$PROMPT" | grep -qE '^/'; then
  HINTS="${HINTS}\nWarning: Prompt is very short. Adding specific context will improve results."
fi

# Output hints if any
if [[ -n "$HINTS" ]]; then
  echo -e "$HINTS"
fi

exit 0
