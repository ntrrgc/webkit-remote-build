#!/bin/bash
set -eu

DIR="$(dirname $(realpath "$0"))"
. "$DIR/config.sh"
BASELINE_STORE="$STORE/baseline/$REMOTE_BUILD_DIR"

if [ -z "${1:-}" ]; then
  echo "Missing file parameter" >/dev/stderr
  exit 1
fi
file="$1"

if [ -f "$BASELINE_STORE/$file" ]; then
  # Delta method
  delta_file="$(mktemp)"
  echo "Generating delta of $file in $delta_file" >>/tmp/generate-packet.log
  xdelta -e -f -s "$BASELINE_STORE/$file" "$file" "$delta_file"
  file_size=$(stat --printf="%s" "$delta_file")

  # Print the package to stdout
  echo $file_size
  echo "$file"
  echo "delta"
  cat "$delta_file"

  # Cleanup
  rm "$delta_file"
else
  # xz method (entire file)
  echo "Warning: File not found, using xz method: $file" >>/tmp/generate-packet.log
  compressed_file="$(mktemp)"
  xz -z -5 -k "$file" -c > "$compressed_file"
  file_size=$(stat --printf="%s" "$compressed_file")

  # Print the package to stdout
  echo $file_size
  echo "$file"
  echo "xz"
  cat "$compressed_file"

  # Cleanup
  rm "$compressed_file"
fi

echo "Packetized $file with method $method: $file_size bytes" >>/tmp/generate-packet.log
