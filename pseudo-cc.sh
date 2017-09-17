#!/bin/bash
set -eu
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "${BASELINE_STORE:-}" ]; then
  echo "BASELINE_STORE environment variable missing."
  exit 1
fi

found_o=0

for arg in "$@"; do
  if [ "$found_o" -eq 1 ]; then
    output_file="$arg"
    break
  elif [ "$arg" == "-o" ]; then
    found_o=1
  fi
done

# Crash if the -o argument could not be found
echo "File: $output_file" >/dev/null

g++ "$@"
exit_status=$?

if [ $exit_status -eq 0 ]; then
  socket=/tmp/delta-socket
  while [ ! -S "$socket" ]; do
    echo "$socket does not exist yet... Waiting"
    sleep 1s
  done

  tmp=$(mktemp)

  # Compress and send .o file package
  "$DIR/generate-packet.sh" "$output_file" > "$tmp"
  ncat -U "$socket" < "$tmp"

  # Compress and send .dwo file package, if it exists
  if [ -f "${output_file%.*}.dwo" ]; then
    "$DIR/generate-packet.sh" "${output_file%.*}.dwo" > "$tmp"
    ncat -U "$socket" < "$tmp"
  fi

  # Cleanup
  rm "$tmp"
fi

exit $exit_status