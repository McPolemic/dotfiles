#!/bin/sh

# Pulled from http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html#usage

input="$1"
output="$2"
palette="/tmp/palette.png"

filters="fps=15,scale=640:-1:flags=lanczos"

ffmpeg -v warning -i "$input" -vf "$filters,palettegen" -y "$palette"
ffmpeg -v warning -i "$input" -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y "$output"
