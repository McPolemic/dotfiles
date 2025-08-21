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
        x = (x + X_DELTA) % X_MAX
        y = (y + Y_DELTA) % Y_MAX

if __name__ == "__main__":
    main()
