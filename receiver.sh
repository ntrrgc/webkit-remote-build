#!/bin/bash
set -eu
. ./config.sh

ssh -T "$BUILD_HOST" <<END 
rm -f /tmp/delta-socket
~/Dropbox/obj-compress/listen-socket.py /tmp/delta-socket | mbuffer -m 200M -q
END

