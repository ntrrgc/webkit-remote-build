#!/bin/bash
set -eu

DIR="$(dirname $(realpath "$0"))"
. "$DIR/config.sh"
. "$DIR/find-build-dirs.sh"

BASELINE_STORE="$STORE/baseline/$LOCAL_BUILD_DIR"

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
read -r file_timestamp <&3
read method <&3

echo "Receiving $file with method $method ($file_size bytes)" >>/tmp/extract-packet.log
mkdir -p "$(dirname "$LOCAL_BUILD_DIR/$file")"

case "$method" in
"xz")
  head -c "$file_size" <&3 | xz -d -c > "$LOCAL_BUILD_DIR/$file"
  ;;
"delta")
  xdelta -d -f -s "$BASELINE_STORE/$file" \
    <(head -c "$file_size" <&3) \
    "$LOCAL_BUILD_DIR/$file"
  ;;
*)
  echo "Invalid method: $method"
  exit 1
esac

touch --no-create --time=modify --date="$file_timestamp" "$LOCAL_BUILD_DIR/$file"

# Close file and delete it
exec 3>&-
rm "$packet_file"
