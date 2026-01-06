#!/bin/bash
# Terminaut Launcher - Opens Kitty with Claude Code + Control Panel

TERMINAUT_DIR="$HOME/.terminaut"

# Launch Kitty with the control panel on the right (25%)
kitty --session - <<EOF
# Main window for Claude Code (will be ~75%)
launch --title "Claude Code" --cwd ~

# Control panel on right
launch --title "Terminaut" --location vsplit $TERMINAUT_DIR/venv/bin/python $TERMINAUT_DIR/control_panel.py

# Resize to make left window larger (75/25 split)
resize_window narrower 3
EOF
