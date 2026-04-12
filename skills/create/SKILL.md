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

### Phase 0: Research (explorer agent)

Before designing anything, understand the landscape:

```
Agent(name: "research-role", subagent_type: "explorer")
  → "Research the leo-skills agent ecosystem for creating a new '{name}' agent:
     1. List ALL existing agents: ls ~/utils/leo-skills/agents/*.md
     2. Read 3-4 agents with similar roles to understand patterns
     3. Identify gaps: what does '{name}' do that existing agents don't?
     4. Check for overlap: could an existing agent handle this?
     5. Read MASTER.md section 1.7 for agent classification rules
     Report: role gap analysis, recommended tools/model, differentiation"
```

If explorer finds an existing agent covers the need → suggest using it instead. Stop here.

### Phase 1: Role Design (architect agent)

```
Agent(name: "design-role", subagent_type: "architect")
  → "Design the role for a new '{name}' agent:
     Explorer findings: {research_output}
     
     Define:
     1. Exact responsibility boundary (what it does / what it does NOT)
     2. Relationship to other agents (who calls it, who it calls)
     3. Input: what information does it need to start?
     4. Output: what does it produce? (format, token budget)
     5. Tools needed:
        - Read-only analysis → Read, Grep, Glob | model: sonnet | context: fork
        - Shell access needed → add Bash
        - Code writing → add Edit, Write | model: opus
        - Web research → add WebFetch, WebSearch
     6. Model: opus (complex/creative) vs sonnet (analysis/review)
     7. Which skills would orchestrate this agent?
     8. Success criteria: how do you know the agent did a good job?"
```

Present design to user. **Wait for approval.**

### Phase 2: Prompt Engineering (prompt-engineer agent)

```
Agent(name: "craft-prompt", subagent_type: "prompt-engineer")
  → "Craft the system prompt for a new '{name}' agent:
     Role design: {architect_output}
     
     Requirements:
     1. Clear identity statement (first paragraph)
     2. Specific trigger conditions (not vague)
     3. Step-by-step process (concrete, not abstract)
     4. Output format template (structured markdown)
     5. Rules section (5-10 non-negotiable constraints)
     6. Token budget for output
     7. Example invocations
     
     Quality criteria:
     - Prompt must be unambiguous (no room for interpretation)
     - Must include what NOT to do (negative constraints)
     - Must reference project conventions (CLAUDE.md, MASTER.md)
     - Must be in English
     - Follow existing agent prompt patterns from the repo"
```

### Phase 3: Conflict Check

```bash
# Check agent doesn't already exist
ls ~/utils/leo-skills/agents/<name>.md 2>/dev/null

# Check for similar agents
ls ~/utils/leo-skills/agents/ | grep -i "<keyword>"

# If similar exists → suggest using existing or explain differentiation
```

### Phase 4: Generate Agent Definition

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

### Phase 5: Validate

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

### Phase 6: Review (critic + reviewer parallel)

Spawn 2 agents to review the generated definition:

```
Agent(name: "review-design", subagent_type: "critic", run_in_background: true)
  → "Review this new agent definition at ~/utils/leo-skills/agents/{name}.md:
     - Does the role overlap with existing agents? (check agents/ directory)
     - Are the responsibility boundaries clear? (what it does vs doesn't)
     - Are the tools appropriate? (too many? too few?)
     - Is the model choice justified? (opus vs sonnet)
     - Are the rules enforceable and specific?
     - Any blind spots or unstated assumptions?
     - Would YOU know exactly what to do if given this prompt?
     Verdict: APPROVE / REVISE (with specific changes)"

Agent(name: "review-prompt", subagent_type: "reviewer", run_in_background: true)
  → "Review the prompt quality of ~/utils/leo-skills/agents/{name}.md:
     - Is the identity statement clear? (first paragraph)
     - Are trigger conditions specific enough?
     - Is the process actionable? (concrete steps, not vague)
     - Does the output format match other agents' patterns?
     - Are negative constraints present? (what NOT to do)
     - Token budget defined?
     - Would the agent produce consistent results across invocations?
     Verdict: APPROVE / REVISE (with specific changes)"
```

**Both APPROVE → proceed to report.**
**Any REVISE → apply changes, re-validate, re-review (max 2 rounds).**

### Phase 7: Report

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

### Phase 0: Research (explorer agent)

```
Agent(name: "research-skill", subagent_type: "explorer")
  → "Research the leo-skills skill ecosystem for creating a new '/{name}' skill:
     1. List ALL existing skills: ls ~/utils/leo-skills/skills/*/SKILL.md
     2. Read 2-3 skills with similar workflows
     3. List ALL available agents: ls ~/utils/leo-skills/agents/*.md
     4. Identify which agents this skill should orchestrate
     5. Check overlap: could an existing skill handle this?
     Report: workflow gap, recommended agent pipeline, pattern reference"
```

### Phase 1: Pipeline Design (architect agent)

```
Agent(name: "design-pipeline", subagent_type: "architect")
  → "Design the agent pipeline for '/{name}' skill:
     Explorer findings: {research_output}
     
     Define:
     1. Agent pipeline (who runs, in what order)
     2. Sequential vs parallel vs hybrid pattern
     3. Which agents need worktree isolation (Edit/Write in tools)
     4. User approval gates (where to pause for user input)
     5. Mode selection (does it need quick/standard/deep variants?)
     6. Issue tracking integration (create, comment, close)
     7. Error handling (what if an agent fails?)
     8. Output format for the skill"
```

Present pipeline to user. **Wait for approval.**

### Phase 2: Prompt Engineering (prompt-engineer agent)

```
Agent(name: "craft-skill-prompt", subagent_type: "prompt-engineer")
  → "Write the SKILL.md for '/{name}':
     Pipeline design: {architect_output}
     
     Follow the exact SKILL.md structure from existing skills.
     Include: Usage, Issue Tracking, Team Composition, Phase details,
     Agent() call examples, Report format, Rules.
     All in English."
```

### Phase 3: Conflict Check

```bash
# Check skill doesn't already exist
ls ~/utils/leo-skills/skills/<name>/SKILL.md 2>/dev/null

# Check for similar skills
ls ~/utils/leo-skills/skills/
```

### Phase 4: Generate Skill Definition

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

### Phase 5: Validate

```bash
# Verify file exists
cat ~/utils/leo-skills/skills/<name>/SKILL.md | head -6

# Count total skills
ls -1d ~/utils/leo-skills/skills/*/SKILL.md | wc -l
```

### Phase 6: Review (critic + reviewer parallel)

```
Agent(name: "review-skill-design", subagent_type: "critic", run_in_background: true)
  → "Review this new skill at ~/utils/leo-skills/skills/{name}/SKILL.md:
     - Does the agent pipeline make sense? (right agents, right order)
     - Are there missing phases? (issue tracking, verification, cleanup)
     - Does it overlap with existing skills?
     - Are approval gates in the right places?
     - Could the pipeline be more parallel?
     - Are error/failure scenarios handled?
     Verdict: APPROVE / REVISE"

Agent(name: "review-skill-prompt", subagent_type: "reviewer", run_in_background: true)
  → "Review prompt quality of ~/utils/leo-skills/skills/{name}/SKILL.md:
     - Does it follow the SKILL.md structure from other skills?
     - Are Agent() call examples concrete?
     - Is the report format structured?
     - Are rules specific and enforceable?
     - Issue tracking present?
     Verdict: APPROVE / REVISE"
```

**Both APPROVE → proceed. Any REVISE → fix + re-review (max 2 rounds).**

### Phase 7: Report

```markdown
## Skill Created

- File: skills/{name}/SKILL.md
- Agents: {pipeline}
- Pattern: {sequential|parallel|hybrid}
- Review: APPROVED by critic + reviewer
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
