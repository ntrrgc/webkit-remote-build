#!/bin/bash
set -eu
DIR="$(dirname $(realpath "$0"))"
. "$DIR/config.sh"

wrapped_executable="$(basename "$0")"

# Just execute the wrapped executable normally if this is not the build machine
if [ "${INVOKED_BY_WEBKIT_REMOTE_BUILD:-}" != "1" ]; then
  echo "Wrapper invoked in local machine: $wrapped_executable $@" >>/tmp/cc-wrapper.log
  exec "$wrapped_executable" "$@"
fi

unset INVOKED_BY_WEBKIT_REMOTE_BUILD
echo "Wrapper invoked in build machine: $wrapped_executable $@" >>/tmp/cc-wrapper.log

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