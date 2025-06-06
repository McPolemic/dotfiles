#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.8"
# dependencies = [
#   "pyautogui",
# ]
# ///

import pyautogui
import time
import random

SLEEP_TIME_IN_SECONDS = 10
X_DELTA = 13
Y_DELTA = 27
X_MAX = 800
Y_MAX = 400

x, y = [10, 10]

while True:
    pyautogui.moveTo(x, y)
    timestamp = time.strftime("%I:%M:%S %p", time.localtime())
    print(f"Moved at {timestamp} ({x}, {y})")
    time.sleep(SLEEP_TIME_IN_SECONDS)
    x += X_DELTA
    y += Y_DELTA
    x = x % X_MAX
    y = y % Y_MAX
