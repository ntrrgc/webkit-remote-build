
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
STORE="$HOME/.webkit-remote"
BUILD_HOST=homura.ntrrgc.me
BUILD_ARGS=(--gtk --debug)
REMOTE_BUILD_DIR=WebKitBuild/Debug
LOCAL_BUILD_DIR=WebKitBuild/Debug

ssh -T "$BUILD_HOST" <<END 
rm -f /tmp/delta-socket
exec ~/Dropbox/obj-compress/listen-socket.py /tmp/delta-socket
END

