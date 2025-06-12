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

SLEEP_TIME_IN_SECONDS = 10
X_DELTA = 13
Y_DELTA = 27
X_MAX = 800
Y_MAX = 400

def parse_timespan(time_str):
    """Parse time strings like '1h30m', '45s', '2h15m30s' into seconds."""
    if not time_str:
        return 0

    # Find all number+unit pairs
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

def format_number(seconds):
    """Format seconds as a readable number."""
    return str(int(seconds))

def main():
    parser = argparse.ArgumentParser(
        description="Move mouse in a loop; optional timeout like coreutils timeout."
    )
    parser.add_argument(
        "timeout",
        nargs="?",
        help="exit after this duration (e.g. 30s, 20m, 1h); defaults to infinite",
        default=None,
    )
    args = parser.parse_args()

    if args.timeout:
        try:
            timeout_secs = parse_timespan(args.timeout)
            print(f"Setting timeout for {args.timeout} ({format_number(timeout_secs)} seconds)")
        except Exception:
            print(f"Invalid timeout value: {args.timeout!r}", file=sys.stderr)
            sys.exit(1)
        end_time = time.time() + timeout_secs
    else:
        end_time = None

    x, y = 10, 10

    while True:
        if end_time is not None and time.time() >= end_time:
            print(f"Timeout of {args.timeout} reached; exiting.")
            break

        pyautogui.moveTo(x, y)
        timestamp = time.strftime("%I:%M:%S %p", time.localtime())
        print(f"Moved at {timestamp} ({x}, {y})")

        time.sleep(SLEEP_TIME_IN_SECONDS)
        x = (x + X_DELTA) % X_MAX
        y = (y + Y_DELTA) % Y_MAX

if __name__ == "__main__":
    main()
