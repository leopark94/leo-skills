---
name: create
description: "Scaffolds new agents and skills from templates — analyzes existing patterns, generates definition files, registers in sync"
disable-model-invocation: false
user-invocable: true
---

# /create — Agent & Skill Creator

Scaffolds new agent definitions and skill definitions by analyzing existing patterns and generating well-structured files.

## Usage

```
/create agent <name> "<description>"
/create skill <name> "<description>"
/create agent <name> --like <existing-agent>    # clone + modify
/create skill <name> --like <existing-skill>    # clone + modify
```

## /create agent

### Step 1: Analyze Requirements

Determine agent characteristics from the description:

```
1. Role classification:
   - Read-only analysis? → tools: Read, Grep, Glob | model: sonnet | context: fork
   - Needs shell access? → add Bash
   - Writes/modifies code? → add Edit, Write | model: opus
   - Needs web access? → add WebFetch, WebSearch

2. Model selection:
   - opus: complex reasoning, code writing, architecture decisions
   - sonnet: analysis, review, exploration (cheaper, parallel-safe)

3. Effort level:
   - high: complex tasks requiring deep analysis
   - medium: standard analysis tasks

4. Context:
   - fork: read-only agents (prevents main context pollution)
   - (omit): agents that need main context access
```

### Step 2: Check for Conflicts

```bash
# Check agent doesn't already exist
ls ~/utils/leo-skills/agents/<name>.md 2>/dev/null

# Check for similar agents
ls ~/utils/leo-skills/agents/ | grep -i "<keyword>"

# If similar exists → suggest using existing or explain differentiation
```

### Step 3: Generate Agent Definition

Write to `~/utils/leo-skills/agents/<name>.md`:

```markdown
---
name: {name}
description: "{one-line description — specific, not generic}"
tools: {tool list based on Step 1}
model: {opus|sonnet}
effort: {high|medium}
{context: fork  # only for read-only agents}
---

# {Name} Agent

{One paragraph explaining what this agent does and when to use it.}

## Role

{How this agent fits into the team. What it does that others don't.}

## When Invoked

{Specific trigger conditions — not vague.}
- Condition 1: {when exactly}
- Condition 2: {when exactly}

Examples:
- "{example user request that triggers this agent}"
- "{another example}"

## Process

### Step 1: {First action}
{What the agent does first — be specific.}

### Step 2: {Second action}
{Next step.}

### Step 3: {Output}
{What the agent produces.}

## Output Format

```markdown
## {Agent Name} Results

### {Section 1}
{structured output}

### {Section 2}
{structured output}
```

## Rules

1. {Most important constraint}
2. {Second constraint}
3. {Third constraint}
- Output: **{token budget} tokens max**
```

### Step 4: Validate

```bash
# Verify frontmatter is valid
head -10 ~/utils/leo-skills/agents/<name>.md

# Verify agent-guard will accept it
echo '{"tool_name":"Agent","tool_input":{"prompt":"test","subagent_type":"<name>"}}' | \
  zsh ~/utils/leo-skills/hooks/scripts/agent-guard.sh
echo "EXIT: $?"

# Count total agents
ls ~/utils/leo-skills/agents/*.md | wc -l
```

### Step 5: Report

```markdown
## Agent Created

- File: agents/{name}.md
- Tools: {tool list}
- Model: {model}
- Worktree required: {YES if Edit/Write in tools, NO otherwise}
- Total agents: {N}

Ready to use: Agent(subagent_type: "{name}", prompt: "...")
```

## /create skill

### Step 1: Analyze Requirements

Determine skill characteristics:

```
1. Agent pipeline:
   - Which agents does this skill orchestrate?
   - What order? (sequential, parallel, hybrid)
   - Which agents need worktree isolation?

2. Mode selection:
   - Does it need multiple modes? (like /review: quick/standard/deep)
   - What triggers auto-escalation?

3. Issue tracking:
   - All skills MUST include issue tracking section
   - gh issue create at start, comment at transitions, close at end
```

### Step 2: Check for Conflicts

```bash
# Check skill doesn't already exist
ls ~/utils/leo-skills/skills/<name>/SKILL.md 2>/dev/null

# Check for similar skills
ls ~/utils/leo-skills/skills/
```

### Step 3: Generate Skill Definition

Create directory and write `~/utils/leo-skills/skills/<name>/SKILL.md`:

```markdown
---
name: {name}
description: "{one-line — agent pipeline summary}"
disable-model-invocation: false
user-invocable: true
---

# /{name} — {Title}

{One paragraph explaining what this skill does.}

## Usage

```
/{name} <description>
/{name} --option1    # variant
/{name} --option2    # variant
```

## Issue Tracking

Before any work, create a GitHub issue:
```bash
gh issue create --title "{type}: {target}" --body "{description}" --label "{label}"
```
All agents comment progress to this issue. Close on completion.

## Team Composition & Flow

```
Phase 1: {name} (sequential|parallel)
  {agent} → {what it does}
       |
Phase 2: {name}
  {agent} → {what it does}
       |
Phase N: Verification (parallel)
  +-- {agent1}
  +-- {agent2}
```

## Phase 1: {Name}

```
Agent(
  prompt: "{detailed prompt}",
  name: "{phase-name}",
  subagent_type: "{agent-type}",
  {isolation: "worktree",  # if write agent}
  {run_in_background: true,  # if parallel}
)
```

{User approval gates where needed.}

## Phase N: Report

```markdown
## {Skill} Complete

### Summary: {result}
### Files: {changed files}
### Issue: #{number} (closed)
```

## Rules

1. {Key rule}
2. {Key rule}
- Issue tracking mandatory
- All agents comment progress to issue
```

### Step 4: Validate

```bash
# Verify file exists
cat ~/utils/leo-skills/skills/<name>/SKILL.md | head -6

# Count total skills
ls -1d ~/utils/leo-skills/skills/*/SKILL.md | wc -l
```

### Step 5: Report

```markdown
## Skill Created

- File: skills/{name}/SKILL.md
- Agents: {pipeline}
- Pattern: {sequential|parallel|hybrid}
- Total skills: {N}

Ready to use: /{name} <description>
```

## /create agent --like <existing>

```
1. Read ~/utils/leo-skills/agents/<existing>.md
2. Clone structure
3. Replace name, description, role
4. Adjust tools/model if needed
5. Differentiate: explain how new agent differs from source
```

## /create skill --like <existing>

```
1. Read ~/utils/leo-skills/skills/<existing>/SKILL.md
2. Clone structure
3. Replace name, pipeline, phases
4. Adjust agents and flow
5. Add issue tracking if missing in source
```

## Rules

1. **All content in English** — agent/skill definitions always English
2. **Validate after creation** — agent-guard test, file existence check
3. **No duplicate names** — check before creating
4. **Description must be specific** — "does stuff" is rejected
5. **Issue tracking mandatory in skills** — no exceptions
6. **Report total count** — user should know the inventory size
7. **Suggest --like when similar exists** — avoid reinventing
