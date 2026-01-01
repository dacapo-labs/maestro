# SKILL.md Format Specification

## Overview

The SKILL.md format is defined by [agentskills.io](https://agentskills.io) and supported by both Claude Code and Codex CLI.

## Basic Structure

```markdown
---
name: skill-name
description: Brief description that triggers the skill
allowed-tools:
  - Bash
  - Read
  - Write
---

# Skill Title

Instructions that load when the skill is triggered.

## Variables

- var_name: default_value

## Instructions

Step-by-step guidance for the agent.
```

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique skill identifier |
| `description` | string | Triggers skill loading when matched |

## Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `allowed-tools` | list | Restrict which tools the skill can use |
| `version` | string | Skill version (recommended) |
| `author` | string | Skill author |
| `license` | string | License identifier |

## Directory Structure

```
.claude/skills/  (or .codex/skills/)
└── my-skill/
    ├── SKILL.md           # Required
    ├── scripts/           # Optional: automation
    │   └── run.sh
    ├── references/        # Optional: additional docs
    │   └── guide.md
    └── assets/            # Optional: templates
        └── template.json
```

## Progressive Disclosure

Skills use progressive disclosure to save tokens:

1. **Description** (always loaded): Brief trigger text
2. **Body** (on trigger): Full instructions
3. **References** (on demand): Loaded when skill requests them

Example:
```markdown
---
description: Process PDF files and extract content
---

# PDF Processor

When you need more details about PDF APIs:
- Read references/pdf-api.md
```

## Tool Gating

Restrict skill capabilities:

```yaml
allowed-tools:
  - Read          # Can read files
  - Bash          # Can run commands
  # No Write = can't modify files
```

## Variables

Define configurable values:

```markdown
## Variables

- output_format: json
- max_pages: 10
- enable_ocr: false
```

The agent can reference these in instructions.

## CLI Differences

| Feature | Claude Code | Codex CLI |
|---------|-------------|-----------|
| Skills Dir | `.claude/skills/` | `.codex/skills/` |
| Discovery | Automatic | Automatic |
| Explicit Invoke | N/A | `/skills`, `$skillname` |
| Implicit Invoke | Description match | Description match |

## Migration Notes

When SKILL.md format changes:
1. Check `version` field requirements
2. Verify `allowed-tools` syntax
3. Test with both CLIs
4. Run `maestro skills validate`
