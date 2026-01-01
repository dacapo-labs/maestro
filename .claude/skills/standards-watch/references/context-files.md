# Context Files: CLAUDE.md vs AGENTS.md vs GEMINI.md

## Overview

Each AI CLI uses its own context file format, though they share similar concepts.

## Comparison

| Feature | CLAUDE.md | AGENTS.md | GEMINI.md |
|---------|-----------|-----------|-----------|
| **CLI** | Claude Code | Codex CLI | Gemini CLI |
| **Spec** | Claude Code native | agents.md / agentskills.io | Gemini CLI native |
| **Hierarchical** | Yes | Yes | Yes |
| **Override File** | N/A | AGENTS.override.md | N/A |
| **Modular Import** | Yes | Yes | @file.md syntax |
| **Discovery** | .claude/ + ancestors | .codex/ + ancestors | ~/.gemini/ + ancestors |

## Claude Code (CLAUDE.md)

**Location precedence:**
1. `$CWD/CLAUDE.md`
2. Parent directories up to `.git` root
3. `~/.claude/CLAUDE.md` (global)

**Features:**
- Auto-reads `.claude/settings.json` for permissions
- Progressive skill loading from `.claude/skills/`
- Supports markdown imports

## Codex CLI (AGENTS.md)

**Location precedence:**
1. `~/.codex/AGENTS.override.md` (if exists)
2. `~/.codex/AGENTS.md`
3. Repo root to CWD, one file per directory

**Features:**
- Override mechanism for temporary changes
- Configurable via `config.toml`
- 32KB default size limit

**Custom filenames:**
```toml
# ~/.codex/config.toml
project_doc_fallback_filenames = ["TEAM_GUIDE.md", ".agents.md"]
```

## Gemini CLI (GEMINI.md)

**Location precedence:**
1. `~/.gemini/GEMINI.md` (global)
2. Project root (identified by `.git`)
3. Subdirectories (respects .gitignore)

**Features:**
- `/memory` commands for inspection
- `@file.md` import syntax
- Configurable filename in settings.json

**Custom filenames:**
```json
{
  "context": {
    "fileName": ["AGENTS.md", "CONTEXT.md", "GEMINI.md"]
  }
}
```

## Cross-Platform Compatibility

To make a repo work with multiple CLIs:

```bash
# Option 1: Symlinks
ln -s CLAUDE.md AGENTS.md
ln -s CLAUDE.md GEMINI.md

# Option 2: Configure each CLI to read the same file
# Codex: config.toml fallback
# Gemini: settings.json fileName
```

## Best Practices

1. **Keep it DRY**: Use one source of truth
2. **Test with each CLI**: Syntax may differ
3. **Use hierarchical structure**: Global → Project → Component
4. **Monitor for changes**: Use standards-watch skill
