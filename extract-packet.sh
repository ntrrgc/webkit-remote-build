#!/bin/bash
set -eu

. ./config.sh
BASELINE_STORE="$STORE/baseline/$LOCAL_BUILD_DIR"
DEST_STORE="/webkit/$LOCAL_BUILD_DIR"

# Open file passed as parameter for reading in file descriptor 3
packet_file="$1"
exec 3< "$packet_file"

read file_size <&3
if [ "$file_size" == "end" ]; then
  echo "This tool must not receive end packages!" >/dev/stderr
  exit 1
elif [[ ! "$file_size" =~ [0-9]+ ]]; then
  echo "Received invalid size: $file_size" >/dev/stderr
  exit 1
fi

read file <&3
read method <&3

echo "Receiving $file with method $method ($file_size bytes)" >>/tmp/extract-packet.log
mkdir -p "$(dirname "$DEST_STORE/$file")"

case "$method" in
"xz")
  head -c "$file_size" <&3 | xz -d -c > "$DEST_STORE/$file"
  ;;
"delta")
  xdelta -d -f -s "$BASELINE_STORE/$file" \
    <(head -c "$file_size" <&3) \
    "$DEST_STORE/$file"
  ;;
*)
  echo "Invalid method: $method"
  exit 1
esac

# Close file and delete it
exec 3>&-
rm "$packet_file"
