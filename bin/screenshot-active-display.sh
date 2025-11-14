#!/bin/zsh

display_id=$(active-display-id)
if [[ -z "$display_id" ]]; then
  echo "Could not determine active display id" >&2
  exit 1
fi

# ISO-ish: 2025-11-14T10-23-55
timestamp=$(date '+%Y-%m-%dT%H-%M-%S')
OUT="$HOME/Desktop/${timestamp}-display-${display_id}.png"

# -x = no sound, -D = specific display, then output file
screencapture -x -D"$display_id" "$OUT"