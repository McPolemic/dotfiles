#!/bin/sh

input="$1"
output="$2"

filters="fps=15,scale=640:-1"

ffmpeg -v warning -i "$input" -vf "$filters" -loop 0 -y "$output"
