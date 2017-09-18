#!/bin/bash
set -eu

DIR="$(dirname $(realpath "$0"))"
. "$DIR/config.sh"

local_cores="$(getconf _NPROCESSORS_ONLN)"
ssh -T "$BUILD_HOST" \
  | "$DIR/packet-splitter.sh" \
  | xargs -P$local_cores -d"\n" -n1 "$DIR/extract-packet.sh" \
  <<END
set -eu
rm -f /tmp/delta-socket
${REMOTE_SCRIPTS_DIR@Q}/listen-socket.py /tmp/delta-socket | mbuffer -m 200M -q
END
