#!/bin/bash
set -e

# claude-desktop-code-bell installer
# Adds sound notifications to Claude Code on macOS
# https://github.com/Zubrock/claude-desktop-code-bell

SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.backup"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
BELL='🔔'
CHECK='✅'
WARN='⚠️'

# Available macOS sounds
SOUNDS=(
  "Glass"
  "Ping"
  "Basso"
  "Blow"
  "Bottle"
  "Frog"
  "Funk"
  "Hero"
  "Morse"
  "Pop"
  "Purr"
  "Sosumi"
  "Submarine"
  "Tink"
)

echo ""
echo -e "${BELL} ${GREEN}claude-desktop-code-bell${NC} — ${YELLOW}Ding Dong!${NC}"
echo -e "   Sound notifications for Claude Code on macOS"
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}Error: This tool is macOS only (uses afplay)${NC}"
  exit 1
fi

# Check afplay
if ! command -v afplay &> /dev/null; then
  echo -e "${RED}Error: afplay not found${NC}"
  exit 1
fi

# Check Claude Code directory
if [[ ! -d "$HOME/.claude" ]]; then
  echo -e "${RED}Error: ~/.claude directory not found. Is Claude Code installed?${NC}"
  exit 1
fi

# Sound picker function
pick_sound() {
  local prompt="$1"
  local default="$2"

  echo ""
  echo -e "${BLUE}${prompt}${NC} (default: ${default})"
  echo ""

  for i in "${!SOUNDS[@]}"; do
    echo "  $((i+1))) ${SOUNDS[$i]}"
  done

  echo ""
  read -p "Pick a number (1-${#SOUNDS[@]}) or press Enter for ${default}: " choice

  if [[ -z "$choice" ]]; then
    echo "$default"
    return
  fi

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#SOUNDS[@]} )); then
    local selected="${SOUNDS[$((choice-1))]}"
    # Preview the sound
    afplay "/System/Library/Sounds/${selected}.aiff" &
    echo "$selected"
  else
    echo "$default"
  fi
}

# Pick sounds
echo -e "${YELLOW}Choose your notification sounds:${NC}"

PERMISSION_SOUND=$(pick_sound "Sound for permission prompts (when Claude needs your approval):" "Glass")
echo -e "  ${CHECK} Permission sound: ${GREEN}${PERMISSION_SOUND}${NC}"

STOP_SOUND=$(pick_sound "Sound when Claude finishes working:" "Ping")
echo -e "  ${CHECK} Stop sound: ${GREEN}${STOP_SOUND}${NC}"

echo ""

# Backup existing settings
if [[ -f "$SETTINGS_FILE" ]]; then
  cp "$SETTINGS_FILE" "$BACKUP_FILE"
  echo -e "${CHECK} Backed up settings to ${BACKUP_FILE}"
fi

# Build hooks JSON
PERMISSION_CMD="afplay /System/Library/Sounds/${PERMISSION_SOUND}.aiff &"
STOP_CMD="afplay /System/Library/Sounds/${STOP_SOUND}.aiff"

# Use node/python/jq to patch JSON, or create from scratch
if command -v jq &> /dev/null; then
  # Use jq for safe JSON manipulation
  if [[ -f "$SETTINGS_FILE" ]]; then
    TEMP_FILE=$(mktemp)

    # Add PermissionRequest hook
    jq --arg cmd "$PERMISSION_CMD" '
      .hooks.PermissionRequest = [
        {
          "hooks": [
            {
              "type": "command",
              "command": $cmd,
              "timeout": 5
            }
          ]
        }
      ]
    ' "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"

    # Add Stop hook (prepend to existing or create)
    TEMP_FILE=$(mktemp)
    jq --arg cmd "$STOP_CMD" '
      .hooks.Stop = (
        [
          {
            "hooks": [
              {
                "type": "command",
                "command": $cmd,
                "timeout": 5
              }
            ]
          }
        ] + (
          if .hooks.Stop then
            [.hooks.Stop[] | select(.hooks[0].command | test("afplay.*\\.aiff") | not)]
          else
            []
          end
        )
      )
    ' "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"

    # Add permissions
    TEMP_FILE=$(mktemp)
    jq --arg pcmd "$PERMISSION_CMD" --arg scmd "$STOP_CMD" '
      .permissions.allow = (
        (.permissions.allow // []) +
        (if ((.permissions.allow // []) | map(select(. == "Bash(\($pcmd))")) | length) == 0 then ["Bash(\($pcmd))"] else [] end) +
        (if ((.permissions.allow // []) | map(select(. == "Bash(\($scmd))")) | length) == 0 then ["Bash(\($scmd))"] else [] end)
      )
    ' "$SETTINGS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$SETTINGS_FILE"

  fi
else
  # No jq — manual approach
  echo -e "${YELLOW}${WARN} jq not found. Installing with brew...${NC}"
  if command -v brew &> /dev/null; then
    brew install jq --quiet
    echo -e "${CHECK} jq installed, re-running..."
    exec "$0" "$@"
  else
    echo -e "${RED}Error: jq is required. Install it: brew install jq${NC}"
    exit 1
  fi
fi

echo ""
echo -e "${GREEN}${CHECK} Installation complete! Ding Dong! 🔔${NC}"
echo ""
echo -e "  ${BELL} Permission prompt → ${GREEN}${PERMISSION_SOUND}${NC}"
echo -e "  ${BELL} Claude finished   → ${GREEN}${STOP_SOUND}${NC}"
echo ""
echo -e "${YELLOW}Restart Claude Code to activate.${NC}"
echo ""
echo -e "To uninstall: ${BLUE}curl -fsSL https://raw.githubusercontent.com/Zubrock/claude-desktop-code-bell/main/uninstall.sh | bash${NC}"
echo ""
