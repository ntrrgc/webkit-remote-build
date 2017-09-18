#!/bin/bash
set -eu
. ./config.sh

ssh -T "$BUILD_HOST" <<END 
rm -f /tmp/delta-socket
exec ~/Dropbox/obj-compress/listen-socket.py /tmp/delta-socket
END

