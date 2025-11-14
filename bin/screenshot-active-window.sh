#!/bin/zsh

window_id=$(active-window-id)
if [[ -z "$window_id" ]]; then
  echo "Could not determine active window id" >&2
  exit 1
fi

timestamp=$(date '+%Y-%m-%dT%H-%M-%S')
OUT="$HOME/Desktop/${timestamp}-window-${window_id}.png"

# Explicitly set the output file so we control the name and avoid slashes
macosrec --screenshot "$window_id" --output "$OUT"