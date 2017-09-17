#!/bin/bash
set -eu

if [ -z "${BASELINE_STORE:-}" ]; then
  echo "BASELINE_STORE environment variable missing."
  exit 1
fi

if [ -z "${DEST_STORE:-}" ]; then
  echo "DEST_STORE environment variable missing."
  exit 1
fi

while read file_size; do
  if [ "$file_size" == "end" ]; then
    exit 0
  fi

  read file
  read method

  mkdir -p "$(dirname "$file")"

  case "$method" in
  "cat")
    dd of="$DEST_STORE/$file" count="$file_size" iflag=count_bytes
    ;;
  "delta")
    xdelta -d -s "$BASELINE_STORE/$file" \
      <(dd count="$file_size" iflag=count_bytes) \
      "$DEST_STORE/$file"
    ;;
  *)
    echo "Invalid method: $method"
    exit 1
  esac
done
