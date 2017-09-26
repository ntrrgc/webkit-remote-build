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

  # It's necessary to be on the same branch in local and remote.
  # If and only if we're on detached HEAD on local, we must be on detached HEAD on remote.

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

  function on_interruption() {
    ssh "$BUILD_HOST" bash <<END
# In the unlikely event that the script run inside ssh has not created the tear
# down file yet, wait for it.
while [ ! -f "/tmp/stop-webkit-build.sh" ]; do
  sleep 0.5s
done
bash /tmp/stop-webkit-build.sh

# In the unlikely event that the socket is not still listening, wait for it.
while [ ! -S /tmp/delta-socket ]; do
  sleep 0.5s
done
echo end | ncat -U /tmp/delta-socket
END
  }
  trap on_interruption SIGINT SIGTERM

  ssh -T "$BUILD_HOST" bash <<END
set -eu
echo "kill -TERM -\$\$ && rm /tmp/stop-webkit-build.sh" > /tmp/stop-webkit-build.sh
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
if $in_branch; then
  # Fast-forward the local branch to get in sync with the remote
  git merge 
fi
patch -p1 < /tmp/local-changes.patch

env \
  CC=${REMOTE_SCRIPTS_DIR@Q}/wrappers/cc \
  CXX=${REMOTE_SCRIPTS_DIR@Q}/wrappers/c++ \
  LD=${REMOTE_SCRIPTS_DIR@Q}/wrappers/c++ \
  ./Tools/Scripts/build-webkit ${BUILD_ARGS[@]@Q} \
  | tee /tmp/build-webkit.log \
  | ${REMOTE_SCRIPTS_DIR@Q}/print-ninja-progress.py
ret_webkit_build="\${PIPESTATUS[0]}"

echo "Finished building webkit."
echo end | ncat -U /tmp/delta-socket
echo "Sent end package."

rm /tmp/stop-webkit-build.sh

if [ \$ret_webkit_build -ne 0 ]; then
  exit \$ret_webkit_build
fi
END

  trap - SIGINT SIGTERM

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

