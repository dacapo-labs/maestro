#!/usr/bin/env bash
# session-close.sh - Close a session: summarize, archive, and cleanup
set -euo pipefail

MAESTRO_ROOT="${MAESTRO_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/lifemaestro}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat >&2 <<EOF
Usage: session-close.sh [options] [session-path]

Close a Claude Code session by:
1. Generating a summary
2. Optionally pushing synopsis to archive
3. Committing final state
4. Optionally cleaning up working files

Options:
  -p, --push           Push synopsis to session-archive repo
  -c, --cleanup        Remove session working files after archiving
  --no-summary         Skip summary generation
  --no-commit          Skip git commit of final state
  -y, --yes            Skip confirmation prompts
  -h, --help           Show this help

Arguments:
  session-path         Path to session directory (default: current directory)

Examples:
  session-close.sh                    # Close current session
  session-close.sh -p                 # Close and push synopsis
  session-close.sh -p -c -y           # Close, push, cleanup, no prompts
EOF
    exit 1
}

# Parse arguments
PUSH=false
CLEANUP=false
NO_SUMMARY=false
NO_COMMIT=false
YES=false
SESSION_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--push) PUSH=true; shift ;;
        -c|--cleanup) CLEANUP=true; shift ;;
        --no-summary) NO_SUMMARY=true; shift ;;
        --no-commit) NO_COMMIT=true; shift ;;
        -y|--yes) YES=true; shift ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *) SESSION_PATH="$1"; shift ;;
    esac
done

# Default to current directory
SESSION_PATH="${SESSION_PATH:-.}"
SESSION_PATH="$(cd "$SESSION_PATH" && pwd)"

SESSION_NAME="$(basename "$SESSION_PATH")"

echo "=== Closing Session: $SESSION_NAME ==="
echo "Path: $SESSION_PATH"
echo ""

# Confirmation
if [[ "$YES" != "true" ]]; then
    echo "This will:"
    [[ "$NO_SUMMARY" != "true" ]] && echo "  - Generate session summary"
    [[ "$PUSH" == "true" ]] && echo "  - Push synopsis to archive"
    [[ "$NO_COMMIT" != "true" ]] && echo "  - Commit final session state"
    [[ "$CLEANUP" == "true" ]] && echo "  - Remove session working files"
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Step 1: Generate summary
if [[ "$NO_SUMMARY" != "true" ]]; then
    echo ""
    echo "--- Generating Summary ---"

    SUMMARY_FILE="$SESSION_PATH/SYNOPSIS.md"

    SUMMARIZE_ARGS=("-o" "$SUMMARY_FILE" "-f" "markdown")
    [[ "$PUSH" == "true" ]] && SUMMARIZE_ARGS+=("-p")

    "$SCRIPT_DIR/session-summarize.sh" "${SUMMARIZE_ARGS[@]}" "$SESSION_PATH"

    echo "Summary saved to: $SUMMARY_FILE"
fi

# Step 2: Final git commit
if [[ "$NO_COMMIT" != "true" ]] && [[ -d "$SESSION_PATH/.git" ]]; then
    echo ""
    echo "--- Committing Final State ---"

    (
        cd "$SESSION_PATH"

        # Add all changes
        git add -A

        # Check if there's anything to commit
        if git diff --cached --quiet; then
            echo "No changes to commit"
        else
            git commit -m "Session closed: $(date -Idate)

Summary generated and archived.
" || true
        fi

        # Push if we have a remote
        if git remote get-url origin &>/dev/null; then
            git push origin HEAD || echo "Warning: Push failed" >&2
        fi
    )
fi

# Step 3: Cleanup (optional)
if [[ "$CLEANUP" == "true" ]]; then
    echo ""
    echo "--- Cleanup ---"

    # Safety check: only clean up if in ai-sessions directory
    if [[ "$SESSION_PATH" != *"/ai-sessions/"* ]]; then
        echo "Error: Cleanup only supported for sessions in ~/ai-sessions/" >&2
        echo "Skipping cleanup for safety." >&2
    else
        # Keep SYNOPSIS.md and CLAUDE.md, remove other working files
        echo "Removing working files (keeping SYNOPSIS.md and CLAUDE.md)..."

        find "$SESSION_PATH" -type f \
            ! -name "SYNOPSIS.md" \
            ! -name "CLAUDE.md" \
            ! -name ".git*" \
            ! -path "*/.git/*" \
            -delete 2>/dev/null || true

        # Remove empty directories
        find "$SESSION_PATH" -type d -empty -delete 2>/dev/null || true

        echo "Cleanup complete"
    fi
fi

echo ""
echo "=== Session Closed ==="
echo "Session: $SESSION_NAME"
[[ -f "$SESSION_PATH/SYNOPSIS.md" ]] && echo "Synopsis: $SESSION_PATH/SYNOPSIS.md"
[[ "$PUSH" == "true" ]] && echo "Archive: Pushed to session-archive repo"
