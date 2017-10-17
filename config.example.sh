STORE="$HOME/.webkit-remote"
BUILD_HOST=homura.ntrrgc.me
BUILD_MACHINE_HOSTNAME=homura  # note: only the first part is matched; the domain part, if any, is ignored
# --debug is added here if DEBUG=1 is specified as an environment variable
BUILD_ARGS=(--gtk --cmakeconfig="-DENABLE_GTKDOC=OFF")
REMOTE_SCRIPTS_DIR=/home/ntrrgc/Apps/webkit-remote-build
REMOTE_BASH=(bash --login)  # Command used with ssh to get a shell. You can change it e.g. to use a chroot.
XZ_COMPRESS_FLAGS=(-5)
RSYNC_EXTRA_ARGS=()

# For debugging
DO_NOT_LAUNCH_PACKET_RECEIVER_IN_REMOTE_BUILD=false
