#!/bin/bash
# Read a stream of packets from stdin, save them to temporary files and print
# their names in stdout.
# 
# Usually this script will be piped to xargs ./extract-packet.sh
#
set -eu

while read file_size; do
  if [ "$file_size" == "end" ]; then
    exit 0
  elif [[ ! "$file_size" =~ [0-9]+ ]]; then
    echo "Received invalid size: $file_size" >/dev/stderr
    exit 1
  fi

  read file
  read method

  packet_file="$(mktemp)"
  echo "$file_size" >> "$packet_file"
  echo "$file" >> "$packet_file"
  echo "$method" >> "$packet_file"
  head -c "$file_size" >> "$packet_file"

  echo "$packet_file"
done
