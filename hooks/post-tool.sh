#!/bin/bash
# Terminaut PostToolUse hook - Updates state when tool completes

STATE_FILE="$HOME/.terminaut/state.json"
ACTIVITY_LOG="$HOME/.terminaut/activity.jsonl"
DEBUG_LOG="$HOME/.terminaut/debug.log"

# Read tool info from stdin
input=$(cat)

# Debug: log raw input
echo "$(date): $input" >> "$DEBUG_LOG"

# Extract tool name
tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')

# Clear current_tool in state file
if [ -f "$STATE_FILE" ]; then
    tmp=$(mktemp)
    jq '.current_tool = null' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
fi

# If this is TodoWrite, capture the todos
if [ "$tool_name" = "TodoWrite" ]; then
    todos=$(echo "$input" | jq -c '.tool_input.todos // []')
    if [ -f "$STATE_FILE" ] && [ -n "$todos" ]; then
        tmp=$(mktemp)
        jq --argjson todos "$todos" '.todos = $todos' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi
fi

# Update activity log - mark as done
timestamp=$(date +"%H:%M:%S")
echo "{\"time\":\"$timestamp\",\"tool\":\"$tool_name\",\"status\":\"done\"}" >> "$ACTIVITY_LOG"

# Keep activity log from growing too large (last 100 entries)
if [ -f "$ACTIVITY_LOG" ]; then
    tail -100 "$ACTIVITY_LOG" > "$ACTIVITY_LOG.tmp" && mv "$ACTIVITY_LOG.tmp" "$ACTIVITY_LOG"
fi
