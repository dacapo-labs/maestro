# Skill Design Guide

## The Planning Phase

**Always begin with the end in mind.** Before writing any code:

1. **Define the Purpose**
   - What problem does this skill solve?
   - Who will use it? (human via CLI, agent, or both)
   - What's the expected output?

2. **Define the Trigger**
   - When should this skill activate?
   - What keywords or patterns indicate this skill?
   - Write clear USE WHEN conditions

3. **Define the Structure**
   - What files will be created?
   - What tools are needed?
   - What documentation goes in the cookbook?

## Skill Architecture

### Directory Structure
```
.claude/skills/<skill-name>/
├── SKILL.md              # Pivot file - routing logic (~500 tokens)
├── cookbook/             # Progressive disclosure docs
│   ├── main-use-case.md
│   └── advanced-use-case.md
└── tools/                # Executable scripts (0 tokens)
    └── <tool>.sh
```

### SKILL.md Template
```markdown
---
name: skill-name
description: One sentence. USE WHEN <specific trigger>.
---

# Skill Name

## Variables
- enable_feature_x: true

## Purpose
What this skill does (2-3 sentences).

## Instructions
If <condition> AND <variable> is true:
1. Read cookbook/<relevant>.md
2. Execute tools/<script>.sh

## Examples
- "User says X" → Do Y
```

### Token Efficiency

| Component | Token Cost | Purpose |
|-----------|------------|---------|
| SKILL.md | ~500 | Routing, always loaded |
| Cookbook | On-demand | Detailed instructions |
| Tools | 0 | Execution scripts |

**Key insight**: Only load cookbook docs when needed. Tools cost zero tokens.

## The Shared Tools Pattern

CLI and agent should share the same underlying scripts:

```
CLI: skill run fetch-data 123
        │
        └──▶ tools/fetch-data.sh ◀──┐
                                     │
Agent: "fetch data for 123"         │
        │                           │
        └──▶ SKILL.md ──▶ cookbook ─┘
```

Benefits:
- Single source of truth
- Test via CLI, use via agent
- Consistent behavior

## Variables Section

Use variables for feature toggles:

```markdown
## Variables
- enable_advanced_mode: false
- default_format: json
- max_results: 10
```

Reference in instructions:
```markdown
If user requests advanced features AND enable_advanced_mode is true:
- Read cookbook/advanced.md
```

## Progressive Disclosure

Don't dump everything into SKILL.md. Instead:

1. **SKILL.md** - Just routing logic
2. **Cookbook** - Detailed instructions per use case
3. **Tools** - Actual implementation

This keeps token usage low while providing depth when needed.

## Naming Conventions

- Skill directories: `kebab-case` (e.g., `ticket-lookup`)
- Tool scripts: `kebab-case.sh` (e.g., `fetch-ticket.sh`)
- Cookbook files: `kebab-case.md` (e.g., `jira-lookup.md`)
- Variables: `snake_case` (e.g., `enable_jira`)

## Testing Checklist

Before considering a skill complete:

- [ ] SKILL.md has clear USE WHEN trigger
- [ ] Tools are executable and work standalone
- [ ] Cookbook provides enough detail
- [ ] CLI invocation works: `skill run <name> <args>`
- [ ] Agent understands when to use it
- [ ] Error handling is graceful
