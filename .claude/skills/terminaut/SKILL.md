---
name: terminaut
description: Working with the Terminaut codebase - a Ghostty fork that transforms a MacBook Pro into a dedicated Claude Code appliance with game controller navigation and voice-first input. Use for building, debugging, and developing Terminaut features.
---

# Terminaut Development Skill

Terminaut is a Ghostty terminal emulator fork optimized for Claude Code with game controller navigation.

## Quick Reference

### Build Commands

```bash
# Standard build (ALWAYS use this after code changes)
./scripts/bump-version.sh && zig build

# Run the app
zig build run

# Run tests
zig build test
zig build test -Dtest-filter=<filter>

# Format code
zig fmt .              # Zig files
prettier --write .     # Everything else

# Clean
make clean
```

**Important:** Always run `./scripts/bump-version.sh && zig build` after making code changes to bump the build number and catch compile errors early.

## Architecture Overview

### Tech Stack
- **Core terminal (libghostty)**: Zig + Metal GPU rendering in `src/`
- **macOS app shell**: Swift/SwiftUI in `macos/Sources/`
- **Terminaut UI**: SwiftUI in `macos/Sources/Terminaut/`

### Two Main Screens

1. **LauncherView** - Fullscreen grid of all projects, controller-navigable
2. **SessionView** - Active Claude Code session with terminal (2/3) + control panel (1/3)

### Key Directories

```
src/                        # Shared Zig core (libghostty)
macos/Sources/
├── App/macOS/              # Main app entry (AppDelegate.swift)
├── Ghostty/                # Original Ghostty Swift UI
├── Features/               # Ghostty features (Terminal, Settings, etc.)
└── Terminaut/              # ALL Terminaut-specific code
    ├── TerminautCoordinator.swift    # Central hub, controller handling
    ├── TerminautRootView.swift       # Root view switching launcher/session
    ├── LauncherView.swift            # Fullscreen project grid
    ├── SessionView.swift             # Terminal + dashboard layout
    ├── ProjectStore.swift            # Project list persistence
    ├── SessionStore.swift            # Claude session file reader
    ├── SessionState.swift            # State file watcher
    ├── GameControllerManager.swift   # 8BitDo controller support
    ├── TabBarView.swift              # Session tabs
    └── Panels/                       # Dashboard panels
        ├── StatusPanel.swift
        ├── VitalsPanel.swift
        ├── GitPanel.swift
        ├── TodosPanel.swift
        └── PanelStyles.swift
```

## Key Components

### TerminautCoordinator (`macos/Sources/Terminaut/TerminautCoordinator.swift`)
Central hub managing:
- Launcher vs session state transitions
- Project launch (creates terminal + dashboard wrapper)
- Game controller input routing
- Session tab management
- Keyboard shortcuts (Cmd+L for launcher, etc.)

### GameControllerManager (`macos/Sources/Terminaut/GameControllerManager.swift`)
8BitDo controller integration:
- Button mapping: A/B/X/Y, bumpers, paddles, sticks
- D-pad navigation for launcher grid
- Vim mode toggle (L3 = insert, R3 = normal)
- Select mode for text selection
- Right trigger for scrolling

### Dashboard Panels (`macos/Sources/Terminaut/Panels/`)
Always-visible panels replacing Claude Code's hidden UI:
- **StatusPanel** - Current project/model display
- **VitalsPanel** - Context % usage + quota tracking
- **GitPanel** - Branch, uncommitted changes, PR links
- **TodosPanel** - Task list from Claude with status
- *Planned: ToolsPanel, AgentsPanel*

### State File Format
Claude Code's statusline writes to `~/.terminaut/states/state-{window_id}.json`:
```json
{
  "cwd": "~/project",
  "git_branch": "main",
  "model": "Claude Opus 4.5",
  "context_pct": 39,
  "weekly_pct": 6,
  "uncommitted": 2,
  "todos": [...]
}
```

## Data Flow

```
App Launch
    ↓
TerminautRootView (switches launcher/session)
    ↓
LauncherView ←→ ProjectStore (~/.terminaut/projects.json)
    ↓
User selects project
    ↓
TerminautCoordinator.launchProject()
    ↓
SessionView (2/3 terminal + 1/3 dashboard)
    ↓
Claude Code statusline → ~/.terminaut/states/state-*.json
    ↓
Dashboard panels read JSON, display context/tools/todos
```

## Development Workflow

### Adding a New Panel

1. Create `macos/Sources/Terminaut/Panels/NewPanel.swift`
2. Use PanelStyles for consistent styling
3. Add panel to DashboardPanel in SessionView
4. Read state from SessionState if needed

### Modifying Controller Behavior

1. Edit `GameControllerManager.swift` for button mappings
2. Edit `TerminautCoordinator.swift` for action handling
3. Use `GameButton` and `Direction` enums for type safety

### Adding a New View

1. Create view in `macos/Sources/Terminaut/`
2. Wire up in `TerminautRootView.swift` or appropriate parent
3. Handle controller focus in `TerminautCoordinator`

## Common Issues

### Build fails with Xcode errors
- Requires Xcode 26 and macOS 26 SDK
- Can build on macOS 15 with proper SDK

### Controller not detected
- Check GCController framework connection
- Verify controller is in supported mode (not MFi)

### Dashboard not updating
- Verify Claude Code statusline hook is installed
- Check `~/.terminaut/states/` for state files
- Verify window_id matches

## Bundle Identity

- **Bundle ID**: `com.peteknowsai.terminaut`
- **Display Name**: Terminaut
- **Output**: `zig-out/Terminaut.app`

## External Files

- `~/.terminaut/projects.json` - Persisted project list
- `~/.terminaut/states/` - Per-window state files from Claude Code
- `~/.claude/statusline.sh` - Claude Code statusline hook
- `.terminaut-build` - Build number counter

## Design Principles

1. **Controller-first**: All UI must be navigable with game controller
2. **Always-visible info**: Surface hidden Claude Code UI elements
3. **Fullscreen-only**: Optimized for MacBook Pro 16"
4. **Voice-first input**: One-button dictation for text input
5. **Coexistence**: Should work alongside regular Ghostty installation
