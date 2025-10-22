#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.8"
# dependencies = [
#   "pyautogui",
# ]
# ///

import argparse
import pyautogui
import time
import random
import sys
import re
import subprocess
from datetime import datetime, timedelta

SLEEP_TIME_IN_SECONDS = 10
X_DELTA = 13
Y_DELTA = 27
X_MAX = 800
Y_MAX = 400

def parse_timespan(time_str):
    """Parse time strings like '1h30m', '45s', '2h15m30s' into seconds."""
    if not time_str:
        return 0

    # Look for all <number><unit> pairs (e.g. 1h, 24m)
    pattern = r'(\d+)([hms])'
    matches = re.findall(pattern, time_str.lower())

    if not matches:
        raise ValueError(f"Invalid time format: {time_str}")

    total_seconds = 0
    for value, unit in matches:
        value = int(value)
        if unit == 'h':
            total_seconds += value * 3600
        elif unit == 'm':
            total_seconds += value * 60
        elif unit == 's':
            total_seconds += value

    return total_seconds

def parse_time_target(time_str):
    """Parse @time format like '@12PM', '@3:30PM', '@15:30' into seconds until that time."""
    if not time_str.startswith('@'):
        raise ValueError(f"Time target must start with @: {time_str}")

    time_part = time_str[1:]  # Remove @
    now = datetime.now()

    # Try different time formats
    formats = [
        '%I%p',      # 12PM
        '%I:%M%p',   # 3:30PM
        '%H:%M',     # 15:30
        '%H',        # 15
    ]

    target_time = None
    for fmt in formats:
        try:
            parsed_time = datetime.strptime(time_part.upper(), fmt)
            # Combine today's date with the parsed time
            target_time = now.replace(
                hour=parsed_time.hour,
                minute=parsed_time.minute,
                second=0,
                microsecond=0
            )
            break
        except ValueError:
            continue

    if target_time is None:
        raise ValueError(f"Invalid time format: {time_str}")

    # If the target time is in the past, assume it's for tomorrow
    if target_time <= now:
        target_time = target_time.replace(day=target_time.day + 1)

    return int((target_time - now).total_seconds())

def format_number(seconds):
    """Format seconds as a readable number."""
    return str(int(seconds))

def format_duration(seconds):
    """Format seconds into a human-readable duration like '1h7m'."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    remaining_seconds = int(seconds % 60)

    parts = []
    if hours > 0:
        parts.append(f"{hours}h")
    if minutes > 0:
        parts.append(f"{minutes}m")
    if remaining_seconds > 0 and hours == 0: # Only show seconds if less than an hour
        parts.append(f"{remaining_seconds}s")

    return ''.join(parts) if parts else '0s'

def get_apps_with_badges():
    """Check for applications with badge notifications in the dock."""
    applescript = '''
    tell application "System Events"
        tell application process "Dock"
            set badgedApps to {}
            try
                set dockItems to every UI element of list 1
                repeat with dockItem in dockItems
                    try
                        set badgeValue to value of attribute "AXStatusLabel" of dockItem
                        if badgeValue is not missing value and badgeValue is not "" then
                            set appName to name of dockItem
                            set end of badgedApps to appName & ": " & badgeValue
                        end if
                    end try
                end repeat
            end try
            set AppleScript's text item delimiters to "|"
            set badgedAppsText to badgedApps as text
            set AppleScript's text item delimiters to ""
            return badgedAppsText
        end tell
    end tell
    '''

    try:
        result = subprocess.run(
            ['osascript', '-e', applescript],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0 and result.stdout.strip():
            apps = result.stdout.strip().split('|')
            return [app for app in apps if app]
        return []
    except Exception:
        return []

def is_handoff_badge(badge_text):
    """Check if badge is a handoff notification (com.apple.device identifiers)."""
    if not badge_text:
        return False
    badge_value = badge_text.split(': ', 1)[-1] if ': ' in badge_text else badge_text
    return badge_value.startswith('com.apple')

def should_filter_badge(badge_text):
    """Check if badge should be filtered (handoff or Messages)."""
    if not badge_text:
        return True

    if is_handoff_badge(badge_text):
        return True

    app_name = badge_text.split(': ', 1)[0] if ': ' in badge_text else ''

    if app_name == 'Messages':
        return True

    if app_name == 'Spark':
        return True

    return False

def notify_badges(apps_with_badges):
    """Send notification about badge updates using pushover."""
    if not apps_with_badges:
        return

    filtered_badges = [badge for badge in apps_with_badges if not should_filter_badge(badge)]

    if not filtered_badges:
        return

    message = "Badge notifications: " + ", ".join(filtered_badges)

    try:
        subprocess.run(
            ['/Users/adam/src/go/bin/pushover', '-title', 'Dock Badge Alert', '-message', message],
            timeout=10
        )
    except Exception as e:
        print(f"Failed to send pushover notification: {e}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(
        description="Move mouse in a loop; optional timeout like coreutils timeout."
    )
    parser.add_argument(
        "timeout",
        nargs="?",
        help="exit after this duration (e.g. 30s, 20m, 1h) or at specific time (e.g. @12PM, @3:30PM); defaults to infinite",
        default=None,
    )
    args = parser.parse_args()

    if args.timeout:
        try:
            if args.timeout.startswith('@'):
                timeout_secs = parse_time_target(args.timeout)
                duration_str = format_duration(timeout_secs)
                time_part = args.timeout[1:]
                end_time_str = time_part.upper()
                print(f"Setting timeout for {duration_str} ({format_number(timeout_secs)} seconds) @{end_time_str}")
            else:
                timeout_secs = parse_timespan(args.timeout)
                end_time_obj = datetime.now().replace(microsecond=0) + timedelta(seconds=timeout_secs)
                end_time_str = end_time_obj.strftime('%I:%M %p').lstrip('0')
                print(f"Setting timeout for {args.timeout} ({format_number(timeout_secs)} seconds) @{end_time_str}")
        except Exception:
            print(f"Invalid timeout value: {args.timeout!r}", file=sys.stderr)
            sys.exit(1)
        end_time = time.time() + timeout_secs
    else:
        end_time = None

    x, y = 10, 10
    last_set_position = None
    last_known_badges = set()

    while True:
        if end_time is not None and time.time() >= end_time:
            print(f"Timeout of {args.timeout} reached; exiting.")
            break

        # Check if cursor has moved from the last position we set
        if last_set_position is not None:
            current_position = pyautogui.position()
            if current_position != last_set_position:
                print(f"Cursor moved from last set position {last_set_position} to {current_position}; exiting.")
                break

        pyautogui.moveTo(x, y)
        last_set_position = (x, y)
        timestamp = time.strftime("%I:%M:%S %p", time.localtime())
        print(f"Moved at {timestamp} ({x}, {y})")

        time.sleep(SLEEP_TIME_IN_SECONDS)

        apps_with_badges = get_apps_with_badges()
        current_badges = set(apps_with_badges)

        new_badges = current_badges - last_known_badges
        if new_badges:
            notify_badges(list(new_badges))
            timestamp = time.strftime("%I:%M:%S %p", time.localtime())
            print(f"New badges detected at {timestamp}: {', '.join(new_badges)}")

        last_known_badges = current_badges

        x = (x + X_DELTA) % X_MAX
        y = (y + Y_DELTA) % Y_MAX

if __name__ == "__main__":
    main()
