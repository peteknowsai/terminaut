#!/bin/bash
# Terminaut Status Pane - Watches state file and renders status

STATE_FILE="$HOME/.terminaut/state.json"

# Colors
SKY_BLUE='\033[38;5;117m'
SOFT_GREEN='\033[38;5;150m'
LIGHT_PURPLE='\033[38;5;147m'
MINT_GREEN='\033[38;5;158m'
PEACH='\033[38;5;215m'
CORAL_RED='\033[38;5;203m'
LIGHT_GRAY='\033[38;5;249m'
GRAY='\033[38;5;245m'
GOLD='\033[38;5;220m'
BOLD='\033[1m'
RST='\033[0m'

render() {
    clear

    if [ ! -f "$STATE_FILE" ]; then
        echo -e "${GRAY}Waiting for state...${RST}"
        return
    fi

    # Read state
    cwd=$(jq -r '.cwd // "~"' "$STATE_FILE")
    git_branch=$(jq -r '.git_branch // ""' "$STATE_FILE")
    model=$(jq -r '.model // ""' "$STATE_FILE")
    context_pct=$(jq -r '.context_pct // 0' "$STATE_FILE")
    weekly_pct=$(jq -r '.weekly_pct // 0' "$STATE_FILE")
    cc_version=$(jq -r '.cc_version // ""' "$STATE_FILE")
    uncommitted=$(jq -r '.uncommitted // 0' "$STATE_FILE")
    ahead_master=$(jq -r '.ahead_master // 0' "$STATE_FILE")
    open_prs=$(jq -r '.open_prs // 0' "$STATE_FILE")
    current_tool=$(jq -r '.current_tool // null' "$STATE_FILE")
    team_name=$(jq -r '.team_name // ""' "$STATE_FILE")
    team_color=$(jq -r '.team_color // "213"' "$STATE_FILE")

    # Header
    echo -e "${BOLD}🚀 TERMINAUT${RST}"
    echo ""

    # Team name
    if [ -n "$team_name" ] && [ "$team_name" != "null" ]; then
        echo -e "\033[38;5;${team_color}m${BOLD}$team_name${RST}"
        echo ""
    fi

    # Directory
    echo -e "${SKY_BLUE}📁 $cwd${RST}"

    # Git branch
    if [ -n "$git_branch" ] && [ "$git_branch" != "null" ]; then
        echo -e "${SOFT_GREEN}🌿 $git_branch${RST}"
    fi

    echo ""

    # Model (only if not Opus)
    if [ -n "$model" ] && [ "$model" != "null" ]; then
        if [[ ! "$model" =~ [Oo]pus ]]; then
            echo -e "${LIGHT_PURPLE}🤖 $model${RST}"
        fi
    fi

    # Context %
    if [ "$context_pct" -ge 80 ] 2>/dev/null; then
        echo -e "${CORAL_RED}🧠 Context: ${context_pct}%${RST}"
    elif [ "$context_pct" -ge 60 ] 2>/dev/null; then
        echo -e "${PEACH}🧠 Context: ${context_pct}%${RST}"
    else
        echo -e "${MINT_GREEN}🧠 Context: ${context_pct}%${RST}"
    fi

    # Weekly usage
    if [ "$weekly_pct" -ge 80 ] 2>/dev/null; then
        echo -e "${CORAL_RED}📊 Weekly: ${weekly_pct}%${RST}"
    elif [ "$weekly_pct" -ge 50 ] 2>/dev/null; then
        echo -e "${PEACH}📊 Weekly: ${weekly_pct}%${RST}"
    else
        echo -e "${MINT_GREEN}📊 Weekly: ${weekly_pct}%${RST}"
    fi

    # Version
    if [ -n "$cc_version" ] && [ "$cc_version" != "null" ]; then
        echo -e "${LIGHT_GRAY}📟 v$cc_version${RST}"
    fi

    echo ""
    echo -e "${GRAY}─────────────────${RST}"
    echo ""

    # Git stats
    if [ "$uncommitted" -gt 0 ] 2>/dev/null; then
        echo -e "${PEACH}📝 $uncommitted uncommitted${RST}"
    else
        echo -e "${GRAY}📝 0 uncommitted${RST}"
    fi

    if [ "$ahead_master" -gt 0 ] 2>/dev/null; then
        echo -e "${PEACH}↑$ahead_master vs master${RST}"
    else
        echo -e "${GRAY}↑0 vs master${RST}"
    fi

    if [ "$open_prs" -gt 0 ] 2>/dev/null; then
        echo -e "${PEACH}🔀 $open_prs open PRs${RST}"
    else
        echo -e "${GRAY}🔀 0 open PRs${RST}"
    fi

    # Current tool
    if [ -n "$current_tool" ] && [ "$current_tool" != "null" ]; then
        echo ""
        echo -e "${GOLD}${BOLD}⚡ $current_tool...${RST}"
    fi
}

# Initial render
render

# Watch for changes and re-render
if command -v fswatch >/dev/null 2>&1; then
    fswatch -o "$STATE_FILE" | while read; do
        render
    done
else
    # Fallback: poll every second
    while true; do
        sleep 1
        render
    done
fi
