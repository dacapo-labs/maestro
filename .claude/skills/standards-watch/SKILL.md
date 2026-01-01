---
name: standards-watch
description: Monitor AI tooling standards and breaking changes. Use when user asks about CLI updates, skill format changes, compatibility between Claude/Codex/Gemini, or wants to check for breaking changes.
allowed-tools:
  - Bash
  - Read
  - WebFetch
---

# Standards Watch

Monitor AI CLI tooling standards and changes across Claude Code, Codex CLI, Gemini CLI, and related specs.

## Variables

- baton_url: ${BATON_URL:-http://localhost:4000}
- check_releases: true
- check_specs: true
- notify_breaking: true

## When to Use

Use this skill when:
1. User asks about AI CLI updates (claude, codex, gemini)
2. User wants to check for breaking changes before updating
3. User asks about skill format compatibility
4. User wants to know differences between CLAUDE.md, AGENTS.md, GEMINI.md
5. User asks "what's new" in AI tooling

## Instructions

### Check for Updates

To check all monitored standards for updates:

```bash
scripts/check-standards.sh
```

Or via baton API:
```bash
curl -s "$BATON_URL/standards/updates?since_hours=168" | jq .
```

### Check Specific CLI

To check a specific CLI's latest release:

```bash
curl -s "$BATON_URL/standards/releases/anthropics/claude-code" | jq .
curl -s "$BATON_URL/standards/releases/openai/codex" | jq .
curl -s "$BATON_URL/standards/releases/google-gemini/gemini-cli" | jq .
```

### Check Compatibility

To see the compatibility matrix for skills and context files:

```bash
curl -s "$BATON_URL/standards/compatibility" | jq .
```

This returns:
- Which CLIs support SKILL.md format
- Context file names for each CLI
- Feature support (hierarchical context, modular imports)

### Breaking Changes

To check specifically for breaking changes:

```bash
scripts/check-breaking.sh
```

If breaking changes are found, read references/migration-guide.md for guidance.

### Force Refresh

To force an immediate check (bypasses cache):

```bash
curl -s -X POST "$BATON_URL/standards/check" | jq .
```

## Output Interpretation

### Release Info
```json
{
  "repo": "anthropics/claude-code",
  "version": "1.3.0",
  "is_breaking": true,
  "breaking_changes": ["SKILL.md now requires version field"],
  "new_features": ["Added /skills reload command"]
}
```

### Update Summary
```json
{
  "updates": [...],
  "count": 3,
  "has_breaking": true
}
```

If `has_breaking` is true, alert the user and suggest reviewing the changes before updating.

## Cross-Platform Skills

Claude Code and Codex both support the agentskills.io SKILL.md format:

| Feature | Claude Code | Codex | Gemini CLI |
|---------|-------------|-------|------------|
| SKILL.md | Yes | Yes | Not yet |
| Skills Dir | .claude/skills | .codex/skills | N/A |
| Progressive Disclosure | Yes | Yes | Planned |

To share skills between Claude and Codex:
```bash
ln -s .claude/skills .codex/skills
```

## References

- references/skill-format.md - SKILL.md format specification
- references/context-files.md - CLAUDE.md vs AGENTS.md vs GEMINI.md
- references/migration-guide.md - Handling breaking changes
