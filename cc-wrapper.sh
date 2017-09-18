#!/bin/bash
set -eu
DIR="$(dirname $(realpath "$0"))"
wrapped_executable="$(basename "$0")"

echo "Wrapper invoked: $wrapped_executable $@" >>/tmp/cc-wrapper.log

found_o=0

for arg in "$@"; do
  if [ "$found_o" -eq 1 ]; then
    output_file="$arg"
    break
  elif [ "$arg" == "-o" ]; then
    found_o=1
  fi
done

"$wrapped_executable" "$@" && true
exit_status=$?

if [ $exit_status -eq 0 ] && [[ "${output_file:-}" =~ \.o$ ]]; then
  socket=/tmp/delta-socket
  while [ ! -S "$socket" ]; do
    echo "$socket does not exist yet... Waiting" >/dev/stderr
    sleep 1s
  done

  # Compress and send .o file package
  tmp="$(mktemp)"
  echo "Packetizing $output_file..." >>/tmp/cc-wrapper.log
  "$DIR/generate-packet.sh" "$output_file" > "$tmp"
  ncat -U "$socket" < "$tmp"
  rm "$tmp"

  # Compress and send .dwo file package, if it exists
  if [ -f "${output_file%.*}.dwo" ]; then
    tmp="$(mktemp)"
    echo "Packetizing ${output_file%.*}.dwo..." >>/tmp/cc-wrapper.log
    "$DIR/generate-packet.sh" "${output_file%.*}.dwo" > "$tmp"
    ncat -U "$socket" < "$tmp"
    rm "$tmp"
  fi
fi

exit $exit_status