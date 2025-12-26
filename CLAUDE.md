# LifeMaestro Development Guide

This file contains principles and guidelines for AI agents working on LifeMaestro.
Incorporates official Anthropic skill specifications from github.com/anthropics/skills.

## Core Principles (Official Anthropic)

### 1. Concise is Key
> "The context window is a public good."

**Claude is already smart.** Only add context Claude doesn't already have.
- Challenge: "Does Claude really need this explanation?"
- Challenge: "Does this paragraph justify its token cost?"
- **Prefer concise examples over verbose explanations.**

### 2. Degrees of Freedom
Match specificity to task fragility:
- **High freedom**: Multiple approaches valid → text instructions
- **Medium freedom**: Preferred pattern exists → pseudocode/scripts with params
- **Low freedom**: Operations fragile → specific scripts, few params

### 3. Progressive Disclosure
Three-level loading system:
| Level | When Loaded | Target Size |
|-------|-------------|-------------|
| Metadata (name+description) | Always | ~100 words |
| SKILL.md body | On trigger | <500 lines |
| Bundled resources | As needed | Unlimited |

## Skill Directory Structure (Official)

```
.claude/skills/<skill-name>/
├── SKILL.md              # Required - routing and instructions
├── scripts/              # Executable code (Python/Bash/etc.)
│   └── <script>.sh
├── references/           # Documentation loaded as needed
│   └── <topic>.md
└── assets/               # Files used in output (templates, images)
    └── <asset>.png
```

### SKILL.md Structure (Official Anthropic Format)
```markdown
---
name: skill-name              # Lowercase, hyphens, max 64 chars
description: |
  What this skill does in detail.
  Use when <trigger conditions>.
  Triggers: keyword1, keyword2, keyword3.
---

# Skill Name

## Instructions
Step-by-step guidance for Claude:
1. First step
2. Read references/<topic>.md for details
3. Execute scripts/<script>.sh

## Examples

### Example 1
**Input**: "Do X with Y"
**Action**: Execute script with parameters

## Version History
- v1.0.0 (date): Initial release
```

### Key Official Guidelines
- **Description is CRUCIAL** - It's how Claude discovers skills. Put ALL triggers here.
- **Body loads AFTER triggering** - "When to use" in body is useless
- **No auxiliary files** - Don't create README.md, CHANGELOG.md, etc.
- **Scripts execute without reading** - Token efficient

### Progressive Disclosure
Don't dump everything into context. Instead:
1. SKILL.md provides **routing logic** (<500 lines)
2. References are read **only when needed**
3. Scripts execute **with zero token cost**

### Variables Section
Use variables to enable/disable features:
```markdown
## Variables
- enable_sdp: true
- enable_jira: false
- default_model: sonnet
```

## Development Workflow

### 1. Plan First
Never start by blasting out prompts. Think through:
- What's the purpose/problem/solution?
- What's the file structure?
- What's the simplest working version?

### 2. Start Simple
- Aim for **proof of concept** first
- Get the simplest version working
- Then iterate and improve

### 3. Test In The Loop
- Write the prompt
- Observe the result
- Encode learnings in the skill

### 4. Use Information-Dense Keywords
Specific keywords carry embedded meaning:
- "Astral UV single file script" → implies Python, uv runner, inline deps
- "12-Factor CLI" → implies stdout/stderr, exit codes, composability
- "subprocess" → implies shell execution patterns

### 5. Fresh Context Windows
- Don't be afraid to start fresh
- Focused agents with clean context perform better
- Fork work to parallel agents when appropriate

## Debugging Principles

**Blame yourself first:**
1. Check your prompts and instructions
2. Check your skill routing logic
3. Check your tool scripts
4. Only then consider model limitations

## LifeMaestro-Specific Patterns

### Zones (not Contexts)
LifeMaestro uses **zones** for flexible namespaces:
- `zones.<name>.git` - Git identity
- `zones.<name>.aws` - AWS profile
- `zones.<name>.features` - Enabled features

### Shared Tools Pattern
CLI commands and Claude Code skills share the same underlying scripts:
```
CLI: ticket sdp 12345
        │
        └──▶ scripts/sdp-fetch.sh ◀──┐
                                      │
Agent: "fetch that SDP ticket"       │
        │                            │
        └──▶ SKILL.md ──▶ references ─┘
```

### Token Efficiency
- SKILL.md for routing (<500 lines)
- References for detailed docs (loaded on demand)
- Scripts for execution (0 tokens - can run without reading)

## When Creating New Skills

1. **Define the trigger** - What description will make Claude use this skill?
2. **Define the scripts** - What executable code is needed?
3. **Define the references** - What documentation should be loaded on demand?
4. **Write SKILL.md** - Clear description, concise instructions, route to references
5. **Test iteratively** - Start simple, observe, improve

Use `skill new <name>` to scaffold the official structure.

## References

- `DESIGN.md` - Full architecture documentation
- `vendor/pai/` - PAI patterns and skills for inspiration
- `.claude/skills/` - Existing LifeMaestro skills
