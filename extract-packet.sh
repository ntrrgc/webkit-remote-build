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

read file_size
if [ "$file_size" == "end" ]; then
  echo "This tool must not receive end packages!"
  exit 1
elif [[ ! "$file_size" =~ [0-9]+ ]]; then
  echo "Received invalid size: $file_size" >/dev/stderr
  exit 1
fi
echo "Received packet with size $file_size" >/dev/stderr

read file
read method

echo "Receiving $file with method $method" >/dev/stderr
echo "Creating folder $(dirname "$DEST_STORE/$file")" >/dev/stderr
mkdir -p "$(dirname "$DEST_STORE/$file")"

case "$method" in
"xz")
  head -c "$file_size" | xz -d -c > "$DEST_STORE/$file"
  echo "Received $DEST_STORE/$file"
  ;;
"delta")
  xdelta -d -f -s "$BASELINE_STORE/$file" \
    <(head -c "$file_size") \
    "$DEST_STORE/$file"
  ;;
*)
  echo "Invalid method: $method"
  exit 1
esac
