#!/usr/bin/env python3
"""Terminaut Control Panel - Robot mission control for Claude Code."""

import json
import time
from pathlib import Path
from datetime import datetime, timezone

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.layout import Layout
from rich.live import Live
from rich.text import Text
from rich.progress import Progress, BarColumn, TextColumn
from rich.style import Style

STATE_FILE = Path.home() / ".terminaut" / "state.json"
ACTIVITY_LOG_FILE = Path.home() / ".terminaut" / "activity.jsonl"

# Colors
CYAN = "cyan"
GREEN = "green"
YELLOW = "yellow"
RED = "red"
MAGENTA = "magenta"
DIM = "dim"


def load_state() -> dict:
    """Load state from file."""
    try:
        if STATE_FILE.exists():
            return json.loads(STATE_FILE.read_text())
    except Exception:
        pass
    return {}


def load_activity_log(limit: int = 5) -> list:
    """Load recent activity from log file."""
    try:
        if ACTIVITY_LOG_FILE.exists():
            lines = ACTIVITY_LOG_FILE.read_text().strip().split("\n")
            activities = []
            for line in lines[-limit:]:
                if line:
                    activities.append(json.loads(line))
            return list(reversed(activities))
    except Exception:
        pass
    return []


def get_color_for_percent(pct: int) -> str:
    """Get color based on percentage threshold."""
    if pct >= 80:
        return RED
    elif pct >= 60:
        return YELLOW
    return GREEN


SPARKLINE_CHARS = " ▁▂▃▄▅▆▇█"


def make_progress_bar(pct: int, width: int = 20) -> Text:
    """Create a colored progress bar."""
    filled = int(pct * width / 100)
    if pct > 0 and filled == 0:
        filled = 1  # Show at least 1 block for non-zero values
    empty = width - filled
    color = get_color_for_percent(pct)

    bar = Text()
    bar.append("█" * filled, style=color)
    bar.append("░" * empty, style=DIM)
    bar.append(f" {pct}%", style=color)
    return bar


def make_sparkline(pct: int) -> Text:
    """Create a single sparkline character for a percentage."""
    # Map 0-100 to sparkline characters (0-8)
    idx = min(8, int(pct * 8 / 100))
    color = get_color_for_percent(pct)
    spark = Text()
    spark.append(SPARKLINE_CHARS[idx], style=color)
    return spark


def format_relative_time(iso_timestamp: str) -> str:
    """Format ISO timestamp as relative time (e.g., 'Resets in 2d 10h')."""
    try:
        reset_time = datetime.fromisoformat(iso_timestamp.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        delta = reset_time - now

        if delta.total_seconds() <= 0:
            return "Resetting..."

        days = delta.days
        hours = delta.seconds // 3600
        minutes = (delta.seconds % 3600) // 60

        if days > 0:
            return f"Resets in {days}d {hours}h"
        elif hours > 0:
            return f"Resets in {hours}h {minutes}m"
        else:
            return f"Resets in {minutes}m"
    except Exception:
        return ""


def make_mission_queue(state: dict) -> Panel:
    """Create the mission queue panel (from todos if available)."""
    # For now, placeholder - will connect to Claude Code's todo system
    missions = [
        ("●", "Current task", "cyan", "▶"),
        ("○", "Queued task", "dim", ""),
        ("✓", "Completed task", "green", ""),
    ]

    content = Text()
    for icon, task, style, status in missions:
        content.append(f"  {icon} ", style=style)
        content.append(f"{task}", style=style)
        if status:
            content.append(f" [{status}]", style="yellow")
        content.append("\n")

    return Panel(
        content,
        title="📋 MISSION QUEUE",
        border_style="bright_blue",
    )


def make_vitals(state: dict) -> Panel:
    """Create the vitals/gauges panel."""
    context_pct = state.get("context_pct", 0) or 0
    weekly_pct = state.get("weekly_pct", 0) or 0
    quota_resets_at = state.get("quota_resets_at", "")

    content = Text()

    # Context
    content.append("  Context ")
    content.append_text(make_sparkline(context_pct))
    content.append(f" {context_pct}%\n", style=get_color_for_percent(context_pct))

    # Quota usage
    content.append("  Quota   ")
    content.append_text(make_sparkline(weekly_pct))
    content.append(f" {weekly_pct}%\n", style=get_color_for_percent(weekly_pct))

    # Reset time
    if quota_resets_at:
        reset_str = format_relative_time(quota_resets_at)
        if reset_str:
            content.append(f"  {reset_str}", style="dim")

    return Panel(
        content,
        title="VITALS",
        border_style="bright_blue",
    )


def make_status(state: dict) -> Panel:
    """Create status panel with model and version."""
    model = state.get("model", "")
    cc_version = state.get("cc_version", "")

    content = Text()
    content.append(f"  {model}\n", style="magenta")
    if cc_version:
        content.append(f"  v{cc_version}", style="dim")

    return Panel(
        content,
        title="STATUS",
        border_style="bright_blue",
    )


def make_git_stats(state: dict) -> Panel:
    """Create git stats panel."""
    git_branch = state.get("git_branch", "")
    uncommitted = state.get("uncommitted", 0) or 0
    ahead_master = state.get("ahead_master", 0) or 0
    pr_list = state.get("pr_list", []) or []

    content = Text()

    # Branch name
    if git_branch:
        content.append(f"  {git_branch}\n", style="green")

    # Uncommitted
    style = "yellow" if uncommitted > 0 else "dim"
    content.append(f"  {uncommitted} uncommitted\n", style=style)

    # Ahead of master
    style = "yellow" if ahead_master > 0 else "dim"
    content.append(f"  +{ahead_master} vs master\n", style=style)

    # PRs section
    content.append("\n  PRs:\n", style="bright_blue")
    if pr_list:
        for pr in pr_list:
            num = pr.get("number", "")
            title = pr.get("title", "")
            # Truncate title if too long
            if len(title) > 25:
                title = title[:22] + "..."
            content.append(f"  #{num} ", style="cyan")
            content.append(f"{title}\n", style="dim")
    else:
        content.append("  No open PRs", style="dim")

    return Panel(
        content,
        title="GIT",
        border_style="bright_blue",
    )


def make_plan(state: dict) -> Panel:
    """Create the plan/todos panel."""
    todos = state.get("todos", [])

    content = Text()

    if not todos:
        content.append("  No active plan...", style="dim italic")
    else:
        for todo in todos:
            task = todo.get("content", "")
            status = todo.get("status", "pending")

            if status == "completed":
                icon = "[x]"
                style = "dim green"
            elif status == "in_progress":
                icon = "[>]"
                style = "dim cyan"
            else:
                icon = "[ ]"
                style = "dim"

            content.append(f"  {icon} ", style=style)
            content.append(f"{task}\n", style=style)

    return Panel(
        content,
        title="PLAN",
        border_style="bright_blue",
    )


def make_controls() -> Panel:
    """Create the controls panel."""
    content = Text()
    content.append("  [P]", style="bold cyan")
    content.append("ause  ", style="dim")
    content.append("[A]", style="bold green")
    content.append("pprove  ", style="dim")
    content.append("[R]", style="bold red")
    content.append("eject", style="dim")

    return Panel(
        content,
        title="CONTROLS",
        border_style="bright_blue",
    )


def make_header(state: dict) -> Text:
    """Create the header with project name."""
    cwd = state.get("cwd", "~")
    project_name = cwd.split("/")[-1] if "/" in cwd else cwd
    header = Text(project_name, style="bold bright_magenta", justify="center")
    return header


def build_layout(state: dict, activities: list) -> Layout:
    """Build the full control panel layout."""
    layout = Layout()

    layout.split_column(
        Layout(name="header", size=1),
        Layout(name="main"),
        Layout(name="controls", size=3),
    )

    layout["main"].split_column(
        Layout(name="status", size=4),
        Layout(name="vitals", size=5),
        Layout(name="git", size=12),
        Layout(name="plan"),
    )

    layout["header"].update(make_header(state))
    layout["status"].update(make_status(state))
    layout["vitals"].update(make_vitals(state))
    layout["git"].update(make_git_stats(state))
    layout["plan"].update(make_plan(state))
    layout["controls"].update(make_controls())

    return layout


def main():
    """Main loop - watch state and update display."""
    console = Console()

    with Live(console=console, refresh_per_second=10, screen=True) as live:
        while True:
            try:
                # Always refresh - state changes fast during tool execution
                state = load_state()
                layout = build_layout(state, [])
                live.update(layout)

                time.sleep(0.1)  # 10 updates per second

            except KeyboardInterrupt:
                break
            except Exception as e:
                console.print(f"[red]Error: {e}[/red]")
                time.sleep(1)


if __name__ == "__main__":
    main()
