#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <input>

Convert a green screen video to transparent WebM and MOV files.

Options:
  -c, --color <hex>        Green screen color (default: auto-detect)
  -s, --similarity <float> Color match tolerance, 0.0-1.0 (default: 0.12)
  -b, --blend <float>      Edge blend amount, 0.0-1.0 (default: 0.05)
  -o, --output <dir>       Output directory (default: same as input)
  -h, --help               Show this help message

Examples:
  $(basename "$0") video.mp4
  $(basename "$0") -c 97c64c -s 0.15 video.mp4
  $(basename "$0") -o ~/Desktop/output video.mp4
EOF
  exit 0
}

detect_green() {
  local input="$1"
  ffmpeg -i "$input" -vframes 1 -vf "crop=200:200:50:50,format=rgb24" \
    -f rawvideo -pix_fmt rgb24 pipe: 2>/dev/null | \
    python3 -c "
import sys
data = sys.stdin.buffer.read()
pixels = [(data[i], data[i+1], data[i+2]) for i in range(0, len(data), 3)]
r = sum(p[0] for p in pixels) // len(pixels)
g = sum(p[1] for p in pixels) // len(pixels)
b = sum(p[2] for p in pixels) // len(pixels)
print(f'{r:02x}{g:02x}{b:02x}')
"
}

color=""
similarity="0.12"
blend="0.05"
output_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--color) color="$2"; shift 2 ;;
    -s|--similarity) similarity="$2"; shift 2 ;;
    -b|--blend) blend="$2"; shift 2 ;;
    -o|--output) output_dir="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) break ;;
  esac
done

if [[ $# -lt 1 ]]; then
  echo "Error: no input file specified" >&2
  echo "Run '$(basename "$0") --help' for usage" >&2
  exit 1
fi

input="$1"
if [[ ! -f "$input" ]]; then
  echo "Error: file not found: $input" >&2
  exit 1
fi

basename="${input%.*}"
if [[ -n "$output_dir" ]]; then
  mkdir -p "$output_dir"
  basename="$output_dir/$(basename "$basename")"
fi

if [[ -z "$color" ]]; then
  echo "Detecting green screen color..."
  color=$(detect_green "$input")
  echo "Detected: #$color"
fi

filter="colorkey=0x${color}:${similarity}:${blend}"

echo "Encoding WebM (VP9 with alpha)..."
ffmpeg -y -i "$input" -vf "$filter" \
  -c:v libvpx-vp9 -pix_fmt yuva420p -crf 30 -b:v 0 \
  "${basename}.webm" 2>/dev/null

echo "Encoding MOV (HEVC with alpha)..."
ffmpeg -y -i "$input" -vf "$filter" \
  -c:v hevc_videotoolbox -alpha_quality 0.75 -tag:v hvc1 \
  "${basename}.mov" 2>/dev/null

echo ""
echo "Done:"
echo "  ${basename}.webm ($(du -h "${basename}.webm" | cut -f1 | xargs))"
echo "  ${basename}.mov  ($(du -h "${basename}.mov" | cut -f1 | xargs))"
