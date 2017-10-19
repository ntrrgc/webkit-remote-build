#!/bin/bash
set -eu

DIR="$(dirname $(realpath "$0"))"
. "$DIR/config.sh"

local_cores="$(getconf _NPROCESSORS_ONLN)"
ssh -T "$BUILD_HOST" <<END \
  | "$DIR/packet-splitter.sh" \
  | xargs -r -P$local_cores -d"\n" -n1 "$DIR/extract-packet.sh"
set -eu
rm -f /tmp/delta-socket
${REMOTE_SCRIPTS_DIR@Q}/serial-listener.py /tmp/delta-socket | mbuffer -m 200M -q
END
