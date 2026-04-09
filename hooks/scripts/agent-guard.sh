#!/bin/zsh
# agent-guard.sh — PreToolUse(Agent) hook: force custom agent usage + worktree isolation
# 1. Blocks generic/general-purpose Agent calls
# 2. Forces isolation: "worktree" on file-modifying agents

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only inspect Agent tool
[[ "$TOOL_NAME" != "Agent" ]] && exit 0

AGENTS_DIR="$HOME/utils/leo-skills/agents"
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')
ISOLATION=$(echo "$INPUT" | jq -r '.tool_input.isolation // empty')

# === CHECK 1: Block generic agents ===
if [[ -z "$SUBAGENT_TYPE" ]] || [[ "$SUBAGENT_TYPE" == "general-purpose" ]]; then
  AVAILABLE=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort | tr '\n' ', ' | sed 's/,$//')
  cat <<BLOCK
BLOCKED: Generic agent not allowed — use a specialized agent.

Available agents (~/utils/leo-skills/agents/):
${AVAILABLE}

If no matching agent exists for this task:
1. Create a new agent definition at ${AGENTS_DIR}/<name>.md
2. Run: ./scripts/sync.sh
3. Then retry with subagent_type: "<name>"

RULE: Every Agent call MUST specify subagent_type matching an agent definition.
BLOCK
  exit 2
fi

# Allow plugin agents (contain ":") — skip further checks
if echo "$SUBAGENT_TYPE" | grep -q ':'; then
  exit 0
fi

# Allow built-in utility agents (non-overlapping with custom agents) — skip further checks
BUILTIN_ALLOWED=("Explore" "Plan" "statusline-setup" "claude-code-guide")
for builtin in "${BUILTIN_ALLOWED[@]}"; do
  if [[ "$SUBAGENT_TYPE" == "$builtin" ]]; then
    exit 0
  fi
done

# === CHECK 2: Verify agent exists ===
if [[ ! -f "$AGENTS_DIR/${SUBAGENT_TYPE}.md" ]]; then
  AVAILABLE=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort | tr '\n' ', ' | sed 's/,$//')
  cat <<BLOCK
BLOCKED: Unknown agent '${SUBAGENT_TYPE}'

Available agents: ${AVAILABLE}

If '${SUBAGENT_TYPE}' is needed:
1. Create the agent definition: ${AGENTS_DIR}/${SUBAGENT_TYPE}.md
2. Run: ./scripts/sync.sh
3. Then retry the Agent tool call.
BLOCK
  exit 2
fi

# === CHECK 3: Worktree isolation for file-modifying agents ===
# Dynamically detect from agent .md frontmatter: if tools contains Edit or Write → file-modifying
AGENT_FILE="$AGENTS_DIR/${SUBAGENT_TYPE}.md"
TOOLS_LINE=$(head -10 "$AGENT_FILE" | grep -E '^tools:' | head -1)
HAS_WRITE_TOOLS=false

if echo "$TOOLS_LINE" | grep -qE '\bEdit\b|\bWrite\b'; then
  HAS_WRITE_TOOLS=true
fi

if [[ "$HAS_WRITE_TOOLS" == "true" ]] && [[ "$ISOLATION" != "worktree" ]]; then
  cat <<BLOCK
BLOCKED: File-modifying agent '${SUBAGENT_TYPE}' requires worktree isolation.
(Detected Edit/Write in tools: ${TOOLS_LINE})

Add isolation: "worktree" to the Agent tool call.
This ensures the agent works on an isolated copy and changes can be reviewed before merge.

Example:
  Agent(subagent_type: "${SUBAGENT_TYPE}", isolation: "worktree", prompt: "...")
BLOCK
  exit 2
fi

exit 0
