#!/bin/bash
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
STORE="$HOME/.webkit-remote"
BUILD_HOST=homura.ntrrgc.me
BUILD_ARGS=(--gtk --debug)
REMOTE_BUILD_DIR=WebKitBuild/Debug
LOCAL_BUILD_DIR=WebKitBuild/Debug

if [ "$1" == "sync" ]; then
  # Generate a base snapshot of the chubby files in the build host and download
  # it to the local machine. It will be very slow on slow networks (over ~2 GB
  # download).
  ssh -T "$BUILD_HOST" <<END
set -eu
mkdir -p "$STORE/baseline/$REMOTE_BUILD_DIR"
rsync --delete --info=progress2 -a \
  "/webkit/$REMOTE_BUILD_DIR/" \
  "$STORE/baseline/$REMOTE_BUILD_DIR/"
END
  mkdir -p "$STORE/baseline/$LOCAL_BUILD_DIR/"
  rsync --delete --info=progress2 -a \
    "$BUILD_HOST:$STORE/baseline/$REMOTE_BUILD_DIR/" \
    "$STORE/baseline/$LOCAL_BUILD_DIR/"

elif [ "$1" == "check" ]; then
  # Test that the baseline chubby files match. Otherwise the delta files will
  # not be applied correctly.
  (cd "/webkit-remote-baseline/$LOCAL_BUILD_DIR" && md5sum "${CHUBBY_FILES[@]}" > /tmp/baseline-local.txt)
  ssh -T "$BUILD_HOST" <<END > /tmp/baseline-remote.txt
cd "/webkit-remote-baseline/$REMOTE_BUILD_DIR" && md5sum ${CHUBBY_FILES[@]}
END
  diff -u /tmp/baseline-{local,remote}.txt
  if [ $? -eq 0 ]; then
    echo "Baseline is correctly synchronized between the local machine and the build machine."
    exit 0
  else
    exit 1
  fi

elif [ "$1" == "build" ]; then
  cd /webkit
  commit_hash="$(git show --format="%h" --no-patch)"
  git diff --cached > /tmp/local-changes.patch

  rsync /tmp/local-changes.patch "$BUILD_HOST":/tmp/

  # Start receiver
  ssh -T "$BUILD_HOST" <<END | env BASELINE_STORE="$STORE/baseline" DEST_STORE="/webkit/$LOCAL_BUILD_DIR" "$DIR/packet-receiver.sh" &
rm -f /tmp/delta-socket
~/Dropbox/obj-compress/listen-socket.py /tmp/delta-socket
END

  ssh -T "$BUILD_HOST" <<END
set -eu
cd /webkit

# Fetch new commits if necessary
if ! git show "$commit_hash" >/dev/null 2>/dev/null; then
  git fetch --all
fi

# Delete old changes
git clean -fd
git checkout -- . >/dev/null

# Put the source tree in the same state as the client
git checkout "$commit_hash"
patch -p1 < /tmp/local-changes.patch
CXX=~/Dropbox/obj-compress/pseudo-cc.sh \
  BASELINE_STORE="$STORE/baseline" \
  ./Tools/Scripts/build-webkit ${BUILD_ARGS[@]}

echo end | ncat -U /tmp/delta-socket
END

  wait # wait for all deltas to be applied

  time_start_transfer=$SECONDS
  echo "Transferring whole files..."
  mkdir -p "/webkit/$LOCAL_BUILD_DIR/"
  rsync --delete --info=progress2 -aXz \
    "$BUILD_HOST:/webkit/$REMOTE_BUILD_DIR/" "/webkit/$LOCAL_BUILD_DIR/"

else
  echo "Unknown command"
  exit 1
fi

