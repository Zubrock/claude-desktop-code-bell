#!/bin/bash
set -e

# claude-desktop-code-bell uninstaller
# https://github.com/Zubrock/claude-desktop-code-bell

SETTINGS_FILE="$HOME/.claude/settings.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
CHECK='✅'

echo ""
echo -e "${YELLOW}Uninstalling claude-desktop-code-bell...${NC}"
echo ""

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo -e "${RED}Settings file not found: ${SETTINGS_FILE}${NC}"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo -e "${RED}jq is required for uninstall. Install: brew install jq${NC}"
  exit 1
fi

TEMP_FILE=$(mktemp)

# Remove PermissionRequest hook
jq 'del(.hooks.PermissionRequest)' "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"

# Remove afplay entries from Stop hook
TEMP_FILE=$(mktemp)
jq '
  if .hooks.Stop then
    .hooks.Stop = [.hooks.Stop[] | select(.hooks[0].command | test("afplay.*\\.aiff") | not)]
    | if (.hooks.Stop | length) == 0 then del(.hooks.Stop) else . end
  else
    .
  end
' "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"

# Remove afplay permissions
TEMP_FILE=$(mktemp)
jq '
  if .permissions.allow then
    .permissions.allow = [.permissions.allow[] | select(test("afplay.*\\.aiff") | not)]
  else
    .
  end
' "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"

# Restore backup if user wants
if [[ -f "$HOME/.claude/settings.json.backup" ]]; then
  read -p "Restore original settings backup? (y/N): " restore
  if [[ "$restore" =~ ^[yY]$ ]]; then
    cp "$HOME/.claude/settings.json.backup" "$SETTINGS_FILE"
    echo -e "${CHECK} Restored from backup"
  fi
fi

echo ""
echo -e "${GREEN}${CHECK} claude-desktop-code-bell removed${NC}"
echo -e "${YELLOW}Restart Claude Code to apply changes.${NC}"
echo ""
