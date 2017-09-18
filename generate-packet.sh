#!/bin/bash
set -eu
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "${BASELINE_STORE:-}" ]; then
  echo "BASELINE_STORE environment variable missing."
  exit 1
fi

if [ -z "${1:-}" ]; then
  echo "Missing file parameter"
  exit 1
fi
file="$1"

if [ -f "$BASELINE_STORE/$file" ]; then
  # Delta method
  delta_file="$(mktemp)"
  echo "Generating delta of $file in $delta_file" >> /tmp/log
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
  echo "Warning: File not found, using xz method: $file" >> /tmp/log
  compressed_file="$(mktemp)"
  xz -z -5 -k "$file" -c > "$compressed_file"
  file_size=$(stat --printf="%s" "$compressed_file")
  echo "File size $file_size" >> /tmp/log

  # Print the package to stdout
  echo $file_size
  echo "$file"
  echo "xz"
  cat "$compressed_file"

  # Cleanup
  rm "$compressed_file"
fi
