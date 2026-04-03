# Leo Master Skills

Claude Code master agent/skill/hook reference system.
All leo-* projects should reference this repo.

## Structure

```
leo-skills/
├── CLAUDE.md           # This file
├── MASTER.md           # Master reference (Anthropic patterns + community best practices)
├── hooks/              # Universal hook configuration
│   ├── hooks.json      # Global hook definitions
│   └── scripts/        # Hook execution scripts
├── agents/             # Universal agent definitions
├── skills/             # Universal skill definitions
├── scripts/            # Utility scripts
└── docs/               # Detailed documentation
```

## Commands

```bash
./scripts/install.sh    # Register hooks/agents in global settings
./scripts/sync.sh       # Re-sync on updates
```

## Rules

- Keep CLAUDE.md concise (this file as reference)
- Use `leo secret` when secrets are detected (never hard-code)
- Hooks must be tested before registration
- Update MASTER.md when adding agents/skills
