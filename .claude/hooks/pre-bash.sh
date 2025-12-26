#!/usr/bin/env bash
# Pre-Bash hook - validate commands before execution
# Input: JSON with tool_input.command
# Output: JSON with decision (approve/block/ask) and optional reason

# Read input
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Skip if no command
[[ -z "$command" ]] && echo '{"decision": "approve"}' && exit 0

# Block dangerous patterns
if echo "$command" | grep -qE '(rm -rf /|:(){:|>\s*/dev/sd|mkfs\.|dd if=)'; then
    echo '{"decision": "block", "reason": "Potentially destructive command blocked"}'
    exit 0
fi

# Warn about force flags
if echo "$command" | grep -qE '(--force|--hard|-f\s)'; then
    echo '{"decision": "ask", "reason": "Command uses force flag - please confirm"}'
    exit 0
fi

# Approve all other commands
echo '{"decision": "approve"}'
