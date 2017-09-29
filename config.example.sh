STORE="$HOME/.webkit-remote"
BUILD_HOST=homura.ntrrgc.me
BUILD_MACHINE_HOSTNAME=homura  # note: only the first part is matched; the domain part, if any, is ignored
BUILD_ARGS=(--gtk --debug --cmakeconfig="-DENABLE_GTKDOC=OFF")
REMOTE_BUILD_DIR=WebKitBuild/webm/Debug
LOCAL_BUILD_DIR=WebKitBuild/webm/Debug
REMOTE_SCRIPTS_DIR=/home/ntrrgc/Apps/webkit-remote-build
REMOTE_BASH=(bash --login)  # Command used with ssh to get a shell. You can change it e.g. to use a chroot.

# For debugging
DO_NOT_LAUNCH_PACKET_RECEIVER_IN_REMOTE_BUILD=false
