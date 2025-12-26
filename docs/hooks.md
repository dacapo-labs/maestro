# Claude Code Hooks

Hooks execute custom scripts at key points in Claude Code workflows.

## Configured Hooks

### PreToolUse: Bash
**File:** `.claude/hooks/pre-bash.sh`

Validates commands before execution:
- Blocks destructive patterns (`rm -rf /`, `mkfs`, etc.)
- Asks confirmation for `--force` flags
- Approves safe commands

### PostToolUse: Write
**File:** `.claude/hooks/post-write.sh`

Auto-processes written files:
- Makes `.sh` files executable
- Validates `.json` syntax

## Hook Events

| Event | When | Use Case |
|-------|------|----------|
| `PreToolUse` | Before tool runs | Validate, block, modify |
| `PostToolUse` | After tool completes | Log, format, notify |
| `UserPromptSubmit` | User sends message | Add context, validate |
| `SessionStart` | Session begins | Load state, setup |
| `SessionEnd` | Session ends | Save state, cleanup |

## Hook Input/Output

Hooks receive JSON on stdin:
```json
{
  "tool_name": "Bash",
  "tool_input": {"command": "npm install"},
  "tool_output": "..."
}
```

PreToolUse hooks return decision:
```json
{"decision": "approve"}
{"decision": "block", "reason": "Blocked by policy"}
{"decision": "ask", "reason": "Please confirm"}
```

## Creating Custom Hooks

1. Create script in `.claude/hooks/`
2. Make executable: `chmod +x .claude/hooks/my-hook.sh`
3. Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ToolName",
        "hooks": [{"type": "command", "command": ".claude/hooks/my-hook.sh"}]
      }
    ]
  }
}
```

## Matchers

- `"Bash"` - Match specific tool
- `"Bash(git:*)"` - Match tool with pattern
- `"*"` - Match all tools

## Tips

- Keep hooks fast (< 100ms)
- Use `jq` for JSON parsing
- Exit 0 for success
- Write errors to stderr
