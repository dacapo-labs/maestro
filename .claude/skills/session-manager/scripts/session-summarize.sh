#!/usr/bin/env bash
# session-summarize.sh - Generate a summary/synopsis of a session
# Uses PAI extract_wisdom style to create actionable summaries
set -euo pipefail

MAESTRO_ROOT="${MAESTRO_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/lifemaestro}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load prompts
PROMPTS_DIR="$MAESTRO_ROOT/.claude/skills/session-manager/prompts"

usage() {
    cat >&2 <<EOF
Usage: session-summarize.sh [options] [session-path]

Generate a summary of a Claude Code session.

Options:
  -o, --output FILE    Write summary to file (default: stdout)
  -f, --format FMT     Output format: text, markdown, json (default: markdown)
  -p, --push           Push synopsis to session-archive repo
  --model MODEL        Model to use for summarization (default: claude-3-5-haiku-latest)
  -h, --help           Show this help

Arguments:
  session-path         Path to session directory (default: current directory)

Examples:
  session-summarize.sh                           # Summarize current session
  session-summarize.sh ~/ai-sessions/work/...   # Summarize specific session
  session-summarize.sh -p                        # Summarize and push to archive
EOF
    exit 1
}

# Parse arguments
OUTPUT=""
FORMAT="markdown"
PUSH=false
MODEL="${BATON_SUMMARIZE_MODEL:-claude-3-5-haiku-latest}"
SESSION_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -f|--format) FORMAT="$2"; shift 2 ;;
        -p|--push) PUSH=true; shift ;;
        --model) MODEL="$2"; shift 2 ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *) SESSION_PATH="$1"; shift ;;
    esac
done

# Default to current directory
SESSION_PATH="${SESSION_PATH:-.}"
SESSION_PATH="$(cd "$SESSION_PATH" && pwd)"

# Find CLAUDE.md in session
CLAUDE_MD=""
if [[ -f "$SESSION_PATH/CLAUDE.md" ]]; then
    CLAUDE_MD="$SESSION_PATH/CLAUDE.md"
elif [[ -f "$SESSION_PATH/.claude/CLAUDE.md" ]]; then
    CLAUDE_MD="$SESSION_PATH/.claude/CLAUDE.md"
else
    echo "Error: No CLAUDE.md found in session path" >&2
    exit 1
fi

# Extract session metadata
SESSION_NAME="$(basename "$SESSION_PATH")"
SESSION_ZONE=""
if [[ -n "${MAESTRO_ZONE:-}" ]]; then
    SESSION_ZONE="$MAESTRO_ZONE"
elif [[ "$SESSION_PATH" =~ /ai-sessions/([^/]+)/ ]]; then
    SESSION_ZONE="${BASH_REMATCH[1]}"
fi

# Load prompt template
PROMPT_FILE="$PROMPTS_DIR/summarize.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
    # Use inline fallback prompt
    PROMPT_TEMPLATE='You are summarizing a Claude Code session. Extract the key insights using the following structure:

## Summary
One paragraph overview of what was accomplished.

## Key Decisions
- Bullet points of important decisions made

## Code Changes
- Files created or modified
- Key patterns or approaches used

## Learnings
- What worked well
- What could be improved

## Next Steps
- Any unfinished work
- Recommended follow-up tasks

---
Session content to summarize:
'
else
    PROMPT_TEMPLATE="$(cat "$PROMPT_FILE")"
fi

# Read session content
SESSION_CONTENT="$(cat "$CLAUDE_MD")"

# Build the full prompt
FULL_PROMPT="$PROMPT_TEMPLATE

$SESSION_CONTENT"

# Call AI for summarization (try Baton first, then claude CLI, then llm)
summarize_with_ai() {
    local prompt="$1"

    # Try Baton API if available
    if curl -s "http://localhost:4000/health" &>/dev/null; then
        curl -s "http://localhost:4000/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -H "X-Maestro-Zone: ${SESSION_ZONE:-}" \
            -d "$(jq -n --arg model "$MODEL" --arg prompt "$prompt" '{
                model: $model,
                messages: [{role: "user", content: $prompt}],
                temperature: 0.3
            }')" | jq -r '.choices[0].message.content'
        return
    fi

    # Try claude CLI
    if command -v claude &>/dev/null; then
        echo "$prompt" | claude --model "$MODEL" --print 2>/dev/null
        return
    fi

    # Try llm tool
    if command -v llm &>/dev/null; then
        echo "$prompt" | llm -m "$MODEL" 2>/dev/null
        return
    fi

    echo "Error: No AI provider available (tried Baton, claude, llm)" >&2
    exit 1
}

# Generate summary
SUMMARY="$(summarize_with_ai "$FULL_PROMPT")"

# Format output
format_output() {
    local summary="$1"
    local format="$2"

    case "$format" in
        text)
            echo "$summary" | sed 's/^#\+/=/g'
            ;;
        markdown)
            cat <<EOF
# Session Synopsis: $SESSION_NAME

**Zone:** ${SESSION_ZONE:-unknown}
**Date:** $(date -Idate)
**Path:** $SESSION_PATH

---

$summary
EOF
            ;;
        json)
            jq -n \
                --arg name "$SESSION_NAME" \
                --arg zone "${SESSION_ZONE:-}" \
                --arg date "$(date -Idate)" \
                --arg path "$SESSION_PATH" \
                --arg summary "$summary" \
                '{
                    session: $name,
                    zone: $zone,
                    date: $date,
                    path: $path,
                    summary: $summary
                }'
            ;;
        *)
            echo "$summary"
            ;;
    esac
}

FORMATTED="$(format_output "$SUMMARY" "$FORMAT")"

# Output
if [[ -n "$OUTPUT" ]]; then
    echo "$FORMATTED" > "$OUTPUT"
    echo "Summary written to: $OUTPUT" >&2
else
    echo "$FORMATTED"
fi

# Push to archive if requested
if [[ "$PUSH" == "true" ]]; then
    ARCHIVE_REPO="${SESSION_ARCHIVE_REPO:-$HOME/repos/session-archive}"

    if [[ ! -d "$ARCHIVE_REPO/.git" ]]; then
        echo "Warning: Session archive repo not found at $ARCHIVE_REPO" >&2
        echo "Run: gh repo clone sethdf/session-archive $ARCHIVE_REPO" >&2
        exit 1
    fi

    # Create archive file
    ARCHIVE_DIR="$ARCHIVE_REPO/${SESSION_ZONE:-misc}/$(date +%Y)"
    mkdir -p "$ARCHIVE_DIR"

    ARCHIVE_FILE="$ARCHIVE_DIR/${SESSION_NAME}.md"
    echo "$FORMATTED" > "$ARCHIVE_FILE"

    # Commit and push
    (
        cd "$ARCHIVE_REPO"
        git add "$ARCHIVE_FILE"
        git commit -m "Add synopsis: $SESSION_NAME" || true
        git push origin main || echo "Warning: Push failed" >&2
    )

    echo "Synopsis pushed to archive: $ARCHIVE_FILE" >&2
fi
