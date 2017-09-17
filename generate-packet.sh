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

if [ -f "BASELINE_STORE/$1" ]; then
  # Delta method
  delta_file="$(mktemp)"
  xdelta -e -s "$BASELINE_STORE/$file" "$file" "$delta_file"
  file_size=$(stat --printf="%s" "$delta_file")

  # Print the package to stdout
  echo $file_size
  echo "$file"
  echo "delta"
  cat "$delta_file"

  # Cleanup
  rm "$delta_file"
else
  # cat method (entire file)
  echo "Warning: File not found, using cat method: $file" >/dev/stderr
  file_size=$(stat --printf="%s" "$file")

  # Print the package to stdout
  echo $file_size
  echo "$file"
  echo "cat"
  cat "$file"
fi
