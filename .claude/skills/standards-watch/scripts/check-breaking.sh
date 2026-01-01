#!/usr/bin/env bash
# check-breaking.sh - Check for breaking changes in AI tooling
set -euo pipefail

BATON_URL="${BATON_URL:-http://localhost:4000}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}Checking for Breaking Changes...${NC}"
echo ""

# Get all releases
releases=$(curl -sf "$BATON_URL/standards/releases" 2>/dev/null)

if [[ -z "$releases" ]]; then
    echo -e "${RED}✗${NC} Failed to fetch releases"
    exit 1
fi

# Check each for breaking changes
breaking_found=false

echo "$releases" | jq -r '.releases | to_entries[] | select(.value.is_breaking == true) | .key' | while read -r repo; do
    breaking_found=true
    info=$(echo "$releases" | jq -r ".releases[\"$repo\"]")
    version=$(echo "$info" | jq -r '.version')

    echo -e "${RED}⚠️  $repo v$version${NC}"
    echo ""

    # Show breaking changes
    echo "$info" | jq -r '.breaking_changes[]? | "    • \(.)"'

    echo ""
done

if [[ "$breaking_found" == "false" ]]; then
    echo -e "${GREEN}✓${NC} No breaking changes detected in recent releases"
fi

echo ""
echo -e "${BOLD}Recommended Actions:${NC}"
echo "  1. Review release notes before updating"
echo "  2. Check SKILL.md files for deprecated fields"
echo "  3. Test skills after CLI updates"
echo "  4. Run: maestro skills validate"
