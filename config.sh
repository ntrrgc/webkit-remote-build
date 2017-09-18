STORE="$HOME/.webkit-remote"
BUILD_HOST=homura.ntrrgc.me
BUILD_ARGS=(--gtk --debug --cmakeconfig="-DENABLE_GTK_DOC=OFF")
REMOTE_BUILD_DIR=WebKitBuild/webm/Debug
LOCAL_BUILD_DIR=WebKitBuild/webm/Debug
REMOTE_SCRIPTS_DIR=/home/ntrrgc/Apps/webkit-remote-build

# For debugging
DO_NOT_LAUNCH_PACKET_RECEIVER_IN_REMOTE_BUILD=false
