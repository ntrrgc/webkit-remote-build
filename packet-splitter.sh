#!/bin/bash
# Read a stream of packets from stdin, save them to temporary files and print
# their names in stdout.
# 
# Usually this script will be piped to xargs ./extract-packet.sh
#
set -eu

echo "Started packet-splitter..." >>/tmp/packet-splitter.log

while read file_size; do
  if [[ ! "$file_size" =~ [0-9]+ ]]; then
    echo "Received invalid size: $file_size" >/dev/stderr
    exit 1
  fi

  read file
  read -r file_timestamp
  read method

  packet_file="$(mktemp)"
  echo "$file_size" >> "$packet_file"
  echo "$file" >> "$packet_file"
  echo "$file_timestamp" >> "$packet_file"
  echo "$method" >> "$packet_file"
  head -c "$file_size" >> "$packet_file"

  echo "$packet_file"
  echo "Wrote packet containing $file" >>/tmp/packet-splitter.log
done

echo "Input stream finished." >>/tmp/packet-splitter.log
