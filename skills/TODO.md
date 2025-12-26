# Skills System TODO

## Decision: Use SKILL.md Directly

After research, we found:
- **Codex CLI** adopted SKILL.md format (same as Claude)
- **Gemini CLI** supports SKILL.md via `skillz` extension
- **agentskills.io** defines a shared specification

**Conclusion:** SKILL.md is the industry standard. No build step needed.

## Simplified Architecture

```
.claude/skills/          # SKILL.md format - works for ALL vendors
├── skill-name/
│   ├── SKILL.md         # Standard format
│   ├── references/      # Progressive disclosure
│   ├── scripts/         # Executable code
│   └── assets/          # Templates, images
```

- Claude Code: Uses directly ✅
- Codex CLI: Uses directly ✅
- Gemini CLI: Uses via skillz adapter ✅
- Any AI: Can read the markdown directly ✅

## Cleanup Tasks

- [ ] Remove `skills/src/` (generic format experiment)
- [ ] Remove `skills/dist/` (build outputs)
- [ ] Simplify `skills/build.sh` → just validation
- [ ] Keep `skills/SPEC.md` as reference (principles still apply)

## Pending Tasks

### 1. Update skill-builder meta-skill
- Update to teach SKILL.md format directly
- Reference agentskills.io specification
- Remove references to generic format / build system

### 2. Migrate existing skills
Skills already in `.claude/skills/` are already in correct format:
- [x] zone-context (already SKILL.md)
- [x] ticket-lookup (already SKILL.md)
- [x] session-manager (already SKILL.md)
- [x] repo-setup (already SKILL.md)
- [x] skill-builder (already SKILL.md)

No migration needed! They're already standard.

### 3. Optional improvements
- [ ] Add validation script for SKILL.md format
- [ ] Add link to agentskills.io in CLAUDE.md
- [ ] Document Gemini CLI skillz setup
