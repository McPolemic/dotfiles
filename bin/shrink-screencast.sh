#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") <input-file> [additional-inputs...]
Converts each input video to 2fps and writes "<name>-shrunk.<ext>" alongside it.
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
esac

for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    echo "Input file not found: $input" >&2
    exit 1
  fi

  dir=$(dirname "$input")
  base=$(basename "$input")

  if [[ "$base" == *.* ]]; then
    extension="${base##*.}"
    stem="${base%.*}"
    output="${dir}/${stem}-shrunk.${extension}"
  else
    output="${dir}/${base}-shrunk"
  fi

  ffmpeg -i "$input" -r 2 "$output"
done
