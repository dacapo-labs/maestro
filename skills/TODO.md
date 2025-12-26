# Skills TODO

## Completed

- [x] Decided: Use SKILL.md directly (industry standard)
- [x] Removed generic format / build system experiment
- [x] Renamed cookbook/ → references/ in all skills
- [x] Added allowed-tools to all skill frontmatter
- [x] Created .claude/rules/ for path-specific rules
- [x] Created .claude/settings.json with permissions
- [x] Trimmed CLAUDE.md (169 → 74 lines)
- [x] Simplified skills/SPEC.md (680 → 82 lines)
- [x] Added `bin/skill-validate` for SKILL.md validation
- [x] Documented Gemini CLI skillz setup (docs/gemini-setup.md)
- [x] Added MCP server configuration (.claude/mcp.json, docs/mcp-setup.md)
- [x] Created hooks for common workflows (.claude/hooks/, docs/hooks.md)

## Architecture Complete

```
.claude/
├── skills/          # SKILL.md format skills
├── rules/           # Path-specific rules
├── hooks/           # Pre/post tool hooks
├── settings.json    # Permissions
└── mcp.json         # External API integrations

bin/
├── skills           # List available skills
└── skill-validate   # Validate SKILL.md format

docs/
├── gemini-setup.md  # Gemini CLI integration
├── mcp-setup.md     # MCP configuration guide
└── hooks.md         # Hooks documentation
```
