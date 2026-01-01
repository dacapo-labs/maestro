#!/usr/bin/env bash
# check-standards.sh - Check AI tooling standards for updates
set -euo pipefail

BATON_URL="${BATON_URL:-http://localhost:4000}"
SINCE_HOURS="${1:-168}"  # Default: 1 week

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}           AI Standards Monitor                          ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if baton is available
if ! curl -sf "$BATON_URL/healthz" >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} Baton not available at $BATON_URL"
    exit 1
fi

echo -e "${DIM}Checking updates from last $SINCE_HOURS hours...${NC}"
echo ""

# Get updates
updates=$(curl -sf "$BATON_URL/standards/updates?since_hours=$SINCE_HOURS" 2>/dev/null)

if [[ -z "$updates" ]]; then
    echo -e "${RED}✗${NC} Failed to fetch updates"
    exit 1
fi

count=$(echo "$updates" | jq -r '.count // 0')
has_breaking=$(echo "$updates" | jq -r '.has_breaking // false')

if [[ "$count" -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} No updates in the last $SINCE_HOURS hours"
    echo ""

    # Show current versions
    echo -e "${BOLD}Current Versions:${NC}"
    summary=$(curl -sf "$BATON_URL/standards" 2>/dev/null)
    echo "$summary" | jq -r '.summary.latest_versions | to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  (unable to fetch)"
    exit 0
fi

# Show updates
echo -e "${BOLD}Updates Found: $count${NC}"
if [[ "$has_breaking" == "true" ]]; then
    echo -e "${RED}⚠️  BREAKING CHANGES DETECTED${NC}"
fi
echo ""

echo "$updates" | jq -r '.updates[] |
    if .is_breaking then
        "  \u001b[31m⚠\u001b[0m \(.name // .repo) v\(.version) - BREAKING"
    else
        "  \u001b[32m✓\u001b[0m \(.name // .repo) v\(.version)"
    end'

echo ""

# Show compatibility info
echo -e "${BOLD}Compatibility Matrix:${NC}"
compat=$(curl -sf "$BATON_URL/standards/compatibility" 2>/dev/null)
echo "$compat" | jq -r '
    .skills_format | to_entries[] |
    if .value.supported then
        "  \(.key): SKILL.md ✓ (\(.value.dir // "N/A"))"
    else
        "  \(.key): SKILL.md ✗ \(.value.notes // "")"
    end'

echo ""
echo -e "${DIM}Run 'standards check-breaking' for detailed breaking change analysis${NC}"
