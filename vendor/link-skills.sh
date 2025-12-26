#!/usr/bin/env bash
# vendor/link-skills.sh - Auto-symlink vendor skills into .claude/skills/
# Run after vendor sync to make PAI and Anthropic skills available to Claude

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Handle empty globs gracefully
shopt -s nullglob
MAESTRO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$MAESTRO_ROOT/.claude/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${RED}[WARN]${NC} $*"; }

# ============================================
# LINK PAI SKILLS
# ============================================
link_pai_skills() {
    local pai_skills_dir="$MAESTRO_ROOT/vendor/pai/.claude/Skills"

    if [[ ! -d "$pai_skills_dir" ]]; then
        info "PAI not synced, skipping PAI skills"
        return 0
    fi

    info "Linking PAI skills..."

    # Remove old PAI symlinks (ones pointing to vendor/pai)
    for link in "$SKILLS_DIR"/pai-*; do
        if [[ -L "$link" ]]; then
            rm "$link"
        fi
    done

    # Create new symlinks for each PAI skill
    local count=0
    for skill_dir in "$pai_skills_dir"/*/; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name=$(basename "$skill_dir")
            local link_name="pai-$(echo "$skill_name" | tr '[:upper:]' '[:lower:]')"
            local target="../../vendor/pai/.claude/Skills/$skill_name"

            ln -sf "$target" "$SKILLS_DIR/$link_name"
            ((count++))
        fi
    done

    ok "Linked $count PAI skills (prefixed with 'pai-')"
}

# ============================================
# LINK ANTHROPIC SKILLS
# ============================================
link_anthropic_skills() {
    local anthropic_skills_dir="$MAESTRO_ROOT/vendor/anthropic-skills/skills"

    if [[ ! -d "$anthropic_skills_dir" ]]; then
        info "Anthropic skills not synced, skipping"
        return 0
    fi

    info "Linking Anthropic skills..."

    # Remove old Anthropic symlinks
    for link in "$SKILLS_DIR"/anthropic-*; do
        if [[ -L "$link" ]]; then
            rm "$link"
        fi
    done

    # Create new symlinks for each Anthropic skill
    local count=0
    for skill_dir in "$anthropic_skills_dir"/*/; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name=$(basename "$skill_dir")
            local link_name="anthropic-$skill_name"
            local target="../../vendor/anthropic-skills/skills/$skill_name"

            ln -sf "$target" "$SKILLS_DIR/$link_name"
            ((count++))
        fi
    done

    ok "Linked $count Anthropic skills (prefixed with 'anthropic-')"
}

# ============================================
# LIST LINKED SKILLS
# ============================================
list_linked() {
    echo ""
    echo "Vendor skills available in .claude/skills/:"
    echo ""

    echo "PAI skills:"
    for link in "$SKILLS_DIR"/pai-*; do
        if [[ -L "$link" ]]; then
            echo "  - $(basename "$link")"
        fi
    done

    echo ""
    echo "Anthropic skills:"
    for link in "$SKILLS_DIR"/anthropic-*; do
        if [[ -L "$link" ]]; then
            echo "  - $(basename "$link")"
        fi
    done
}

# ============================================
# MAIN
# ============================================
main() {
    local cmd="${1:-link}"

    case "$cmd" in
        link|sync)
            link_pai_skills
            link_anthropic_skills
            list_linked
            ;;
        list)
            list_linked
            ;;
        clean)
            info "Removing all vendor skill symlinks..."
            rm -f "$SKILLS_DIR"/pai-* "$SKILLS_DIR"/anthropic-*
            ok "Cleaned vendor skill symlinks"
            ;;
        *)
            echo "Usage: $0 [link|list|clean]"
            exit 1
            ;;
    esac
}

main "$@"
