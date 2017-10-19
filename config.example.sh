# Storage directory of this tool. Baseline is stored here (only used for xdelta
# method)
STORE="$HOME/.webkit-remote"

# Host to connect to using ssh.
BUILD_HOST=my-dynamic-dns.example.com

# Name of the build machine. Used to know if we are running code there or not
# when cc-wrapper.sh is executed.
# Note: only the first part is matched, so "foo" matches both "foo" and 
# "foo.bar".
BUILD_MACHINE_HOSTNAME=example

# Path where these scripts will be installed or updated in the build machine.
REMOTE_SCRIPTS_DIR=/home/ntrrgc/Apps/webkit-remote-build

# Arguments passed to build-webkit
BUILD_ARGS=(--gtk --debug --cmakeconfig="-DENABLE_GTKDOC=OFF")

# Path to build directory in the build machine
REMOTE_BUILD_DIR=/webkit/WebKitBuild/Debug

# Path to build directory in the local machine
LOCAL_BUILD_DIR=/webkit/WebKitBuild/Debug

# Alternatively, instead of setting LOCAL_BUILD_DIR and REMOTE_BUILD_DIR
# manually you can use this script which will use `build-type` to populate
# them. It will also add --debug to BUILD_ARGS if in a debug build.
#
# . "$(dirname "${BASH_SOURCE[0]}")/webkit-find-dirs.sh"

# xz compress flags. You can set the compression level here. Higher values
# compress better but more slowly. For best performance, you should use the
# lowest value that still uses less of the bandwidth your Internet connection
# can handle.
XZ_COMPRESS_FLAGS=(-5)

# Command used with ssh to get a shell. You can change it e.g. to run commands
# inside a chroot.
REMOTE_BASH=(bash --login)  

# Extra arguments passed to rsync. You can use these to execute rsync inside a
# chroot.
RSYNC_EXTRA_ARGS=()

# Only for debugging. It does prevent launching packet-receiver.sh when 
# webkit-remote-build.sh is invoked. Useful if you want to run it in a separate
# console tab.
DO_NOT_LAUNCH_PACKET_RECEIVER_IN_REMOTE_BUILD=false
