# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terminaut is a gamified control panel dashboard for Claude Code, designed to run in Kitty terminal. It displays real-time status information including context usage, weekly quota, git stats, and todo progress in a side panel alongside Claude Code.

## Architecture

### Data Flow

1. **statusline.sh** - Claude Code's statusline hook that:
   - Receives JSON from Claude Code with session/context data
   - Fetches weekly usage from a Cloudflare worker (`claude-usage-proxy.petefromsf.workers.dev`)
   - Writes state to `~/.terminaut/state.json`
   - Auto-launches the control panel in Kitty if not running

2. **control_panel.py** - Rich-based Python TUI that:
   - Watches `state.json` at 10Hz refresh rate
   - Renders panels: Status, Vitals (context/quota), Git stats, Plan (todos)
   - Uses Rich library for layout and styling

3. **hooks/** - Claude Code tool hooks:
   - `pre-tool.sh`: Sets `current_tool` in state when a tool starts
   - `post-tool.sh`: Clears `current_tool`, captures TodoWrite todos to state

### State File Schema (`~/.terminaut/state.json`)

```json
{
  "cwd": "~/project",
  "git_branch": "main",
  "model": "Opus 4.5",
  "context_pct": 39,
  "weekly_pct": 6,
  "quota_resets_at": "ISO-8601 timestamp",
  "current_tool": "Read",
  "uncommitted": 2,
  "ahead_master": 0,
  "open_prs": 2,
  "pr_list": [...],
  "cc_version": "2.0.76",
  "team_name": "",
  "team_color": "213",
  "todos": [...]
}
```

## Development

### Running the Control Panel

```bash
# Activate venv and run
source venv/bin/activate
python control_panel.py

# Or use the launcher (opens Kitty with split layout)
./launch.sh
```

### Dependencies

Python dependencies (in venv):
- `rich` - TUI rendering
- `watchdog` - File watching (optional, used in status-pane.sh fallback)

### Testing Changes

The panel auto-refreshes from state.json. To test:
1. Run `python control_panel.py` in one terminal
2. Manually edit `state.json` to see changes render

### Integrating with Claude Code

1. Set statusline hook in Claude Code settings to run `statusline.sh`
2. Configure pre/post tool hooks to run the scripts in `hooks/`
3. The panel auto-launches in Kitty when statusline runs

## Key Files

- `control_panel.py` - Main TUI application (Rich layouts, panels)
- `statusline.sh` - Claude Code statusline integration (writes state)
- `hooks/pre-tool.sh` - PreToolUse hook (tracks current tool)
- `hooks/post-tool.sh` - PostToolUse hook (captures todos)
- `state.json` - Runtime state (gitignored)
- `launch.sh` - Kitty launcher with 24pt font
