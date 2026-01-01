# Migration Guide: Handling Breaking Changes

## Overview

When AI CLI tools release breaking changes, follow this guide to update your skills and configuration.

## Pre-Update Checklist

Before updating any AI CLI:

```bash
# 1. Check for breaking changes
scripts/check-breaking.sh

# 2. Backup current skills
cp -r .claude/skills .claude/skills.bak

# 3. Note current versions
claude --version
codex --version
gemini --version
```

## Common Breaking Changes

### SKILL.md Format Changes

**Symptom**: Skills no longer trigger or load incorrectly

**Check**:
```bash
maestro skills validate
```

**Common fixes**:
- Add missing `version` field
- Update `allowed-tools` syntax
- Rename deprecated fields

### Context File Changes

**Symptom**: CLAUDE.md/AGENTS.md not being read

**Check**:
```bash
# Claude
claude config show

# Codex
codex config show

# Gemini
gemini /memory show
```

**Common fixes**:
- Check filename case sensitivity
- Verify hierarchical discovery
- Update import syntax

### API Changes

**Symptom**: Baton proxy errors, auth failures

**Check**:
```bash
curl -s localhost:4000/doctor | jq .
```

**Common fixes**:
- Update API version headers
- Refresh OAuth tokens
- Check model name changes

## Step-by-Step Migration

### 1. Update CLI Tool

```bash
# Claude Code
npm update -g @anthropic-ai/claude-code

# Codex
npm update -g @openai/codex

# Gemini CLI
npm update -g @google/gemini-cli
```

### 2. Validate Skills

```bash
# Check all skills parse correctly
for skill in .claude/skills/*/SKILL.md; do
    echo "Checking: $skill"
    # Basic YAML frontmatter check
    head -20 "$skill" | grep -E "^(name|description|allowed-tools):" || echo "  ⚠ Missing fields"
done
```

### 3. Test Critical Workflows

```bash
# Test skill triggers
claude "Use the ticket-lookup skill to check ticket 123"

# Test context loading
claude config show | grep -i context
```

### 4. Update Baton

If CLI changes affect API behavior:

```bash
cd ~/baton
git pull
pip install -e .
systemctl restart baton  # or however you run it
```

### 5. Verify Integration

```bash
# Check baton sees new CLI features
curl -s localhost:4000/standards | jq '.compatibility'

# Check doctor passes
curl -s localhost:4000/doctor | jq '.status'
```

## Rollback Procedure

If update causes issues:

```bash
# 1. Restore skills backup
rm -rf .claude/skills
mv .claude/skills.bak .claude/skills

# 2. Downgrade CLI (npm example)
npm install -g @anthropic-ai/claude-code@<previous-version>

# 3. Clear baton cache
rm ~/.baton/standards_cache.json
curl -X POST localhost:4000/standards/check
```

## Version Compatibility Matrix

Track which skill format versions work with which CLI versions:

| CLI Version | SKILL.md Version | Notes |
|-------------|------------------|-------|
| claude 1.x | v1.0 | Original format |
| claude 2.x | v1.1+ | Requires version field |
| codex 0.9+ | v1.0 | agentskills.io spec |

## Getting Help

1. Check release notes: `curl -s localhost:4000/standards/releases/<repo>`
2. Review breaking changes: `scripts/check-breaking.sh`
3. File issues: GitHub issues for each CLI
