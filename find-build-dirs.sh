# This file is sourced after config.sh.
# Its purpose is to generate $REMOTE_BUILD_DIR and $LOCAL_BUILD_DIR

if [ "${DEBUG:-}" == "1" ]; then
  BUILD_ARGS+=(--debug)
  build_type=Debug
else
  build_type=Release
fi

function find_branch_dir() {
  pushd /webkit >/dev/null
  if git status --branch --porcelain=v2 | egrep -q '^# branch.head \(detached\)$'; then
    local in_branch=false
  else
    local in_branch=true
    local branch_name="$(git status --branch --porcelain=v2 | egrep '^# branch.head '| cut -d" " -f3)"
  fi

  if ! $in_branch || [ "$branch_name" == "master" ]; then
    echo "WebKitBuild"
  else
    echo "WebKitBuild/$branch_name"
  fi
  popd >/dev/null
}

branch_dir=$(find_branch_dir)

REMOTE_BUILD_DIR="$branch_dir/$build_type"
LOCAL_BUILD_DIR="$branch_dir/$build_type"
