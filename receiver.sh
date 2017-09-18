#!/bin/bash
set -eu

DIR="$(dirname $(realpath "$0"))"
. "$DIR/config.sh"

ssh -T "$BUILD_HOST" <<END 
rm -f /tmp/delta-socket
${REMOTE_SCRIPTS_DIR@Q}/listen-socket.py /tmp/delta-socket | mbuffer -m 200M -q
END

