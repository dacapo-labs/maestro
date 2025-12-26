# Using LifeMaestro Skills with Gemini CLI

Gemini CLI supports SKILL.md format via the `skillz` extension.

## Quick Setup

```bash
# Install skillz extension
gemini extension install skillz

# Point to LifeMaestro skills
gemini config set skills.path ~/.config/lifemaestro/.claude/skills

# Or for project-specific
gemini config set skills.path /path/to/project/.claude/skills
```

## Verify Setup

```bash
# List available skills
gemini skills list

# Test a skill
gemini "What zone am I in?"  # Should trigger zone-context skill
```

## How It Works

The skillz extension:
1. Reads SKILL.md files from configured path
2. Parses YAML frontmatter (name, description, allowed-tools)
3. Converts to Gemini-compatible tool definitions
4. Makes skills available in conversations

## Notes

- Skills work the same way as Claude Code
- `allowed-tools` restrictions are honored
- `references/` and `scripts/` directories are accessible
- Vendor skills (pai-*, anthropic-*) work if symlinks resolve

## Troubleshooting

**Skills not loading:**
```bash
# Check path is correct
gemini config get skills.path

# Verify skills exist
ls $(gemini config get skills.path)
```

**Skill not triggering:**
- Check description field contains relevant keywords
- Gemini selects skills based on description matching

## Resources

- [Gemini CLI Docs](https://github.com/google-gemini/gemini-cli)
- [agentskills.io Spec](https://agentskills.io)
