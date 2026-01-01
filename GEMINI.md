# LifeMaestro (Gemini CLI Context)

This context imports from CLAUDE.md for consistency across AI CLIs.

@./CLAUDE.md

## Gemini-Specific Notes

- Skills are not yet natively supported in Gemini CLI (see issue #12890)
- Use `/memory show` to inspect loaded context
- Extensions can provide additional capabilities

## Cross-Platform Compatibility

This repo is configured to work with:
- **Claude Code**: Reads CLAUDE.md, .claude/skills/
- **Codex CLI**: Reads AGENTS.md, .codex/skills/ (symlinked)
- **Gemini CLI**: Reads GEMINI.md (imports CLAUDE.md)
