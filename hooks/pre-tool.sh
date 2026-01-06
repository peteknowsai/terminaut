#!/bin/bash
# Terminaut PreToolUse hook - Updates state when tool starts

STATE_FILE="$HOME/.terminaut/state.json"
ACTIVITY_LOG="$HOME/.terminaut/activity.jsonl"

# Read tool info from stdin
input=$(cat)

# Extract tool name
tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')

# Update current_tool in state file
if [ -f "$STATE_FILE" ]; then
    tmp=$(mktemp)
    jq --arg tool "$tool_name" '.current_tool = $tool' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
fi

# Log to activity file
timestamp=$(date +"%H:%M:%S")
echo "{\"time\":\"$timestamp\",\"tool\":\"$tool_name\",\"status\":\"running\"}" >> "$ACTIVITY_LOG"
