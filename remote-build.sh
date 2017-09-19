#!/bin/bash
set -eu

DIR="$(dirname $(realpath "$0"))"
. "$DIR/config.sh"

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
cd "/webkit-remote-baseline/${REMOTE_BUILD_DIR@Q}" && md5sum ${CHUBBY_FILES[@]@Q}
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
  if git status --branch --porcelain=v2 | egrep -q '^# branch.head \(detached\)$'; then
    in_branch=false
  else
    in_branch=true
    branch_name="$(git status --branch --porcelain=v2 | egrep '^# branch.head '| cut -d" " -f3)"
    if ! git status --branch --porcelain=v2 | egrep -q '^# branch.ab \+0 -0$'; then
      echo "Branch not synchronized with remote. You need to push or pull commits." >/dev/stderr
      git status --branch
      exit 1
    fi
  fi
  git diff --cached > /tmp/local-changes.patch

  rsync /tmp/local-changes.patch "$BUILD_HOST":/tmp/

  # Start receiver
  if ! $DO_NOT_LAUNCH_PACKET_RECEIVER_IN_REMOTE_BUILD; then
    "$DIR/packet-receiver.sh" &
  fi

  ssh -T "$BUILD_HOST" <<END
set -eu
cd /webkit

# Fetch new commits if necessary
if ! git show ${commit_hash@Q} >/dev/null 2>/dev/null; then
  git fetch --all
fi

# Delete old changes
git clean -fd
git checkout -- . >/dev/null

# Put the source tree in the same state as the client
git checkout "$($in_branch && echo $branch_name || echo $commit_hash)"
patch -p1 < /tmp/local-changes.patch

env \
  CC=${REMOTE_SCRIPTS_DIR@Q}/wrappers/cc \
  CXX=${REMOTE_SCRIPTS_DIR@Q}/wrappers/c++ \
  LD=${REMOTE_SCRIPTS_DIR@Q}/wrappers/ld \
  ./Tools/Scripts/build-webkit ${BUILD_ARGS[@]@Q} \
  | tee /tmp/build-webkit.log \
  | ${REMOTE_SCRIPTS_DIR@Q}/print-ninja-progress.py
ret_webkit_build="\${PIPESTATUS[0]}"

echo end | ncat -U /tmp/delta-socket

if [ \$ret_webkit_build -ne 0 ]; then
  exit \$ret_webkit_build
fi
END

  wait # wait for all packages to be extracted

  time_start_transfer=$SECONDS
  echo "Transferring whole files..."
  mkdir -p "/webkit/$LOCAL_BUILD_DIR/"
  rsync --delete --info=progress2 -aXz \
    "$BUILD_HOST:/webkit/$REMOTE_BUILD_DIR/" "/webkit/$LOCAL_BUILD_DIR/"

else
  echo "Unknown command"
  exit 1
fi

