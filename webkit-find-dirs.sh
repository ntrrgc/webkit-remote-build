#!/bin/bash
# This file is sourced from config.sh.
# Its purpose is to generate $REMOTE_BUILD_DIR and $LOCAL_BUILD_DIR according
# to the current branch and build type.
# It depends on build-type being available in PATH: https://github.com/ntrrgc/dotfiles/blob/42f72a2/bin/build-type

build_type="$(build-type)"
if [ "$build_type" == "debug" ]; then
  BUILD_ARGS+=(--debug)
  build_type=Debug
else
  build_type=Release
fi

function find_branch_dir() {
  pushd /webkit >/dev/null
  if [[ "$(git config core.webKitBranchBuild || true)" != "true" ]] \
    || git status --branch --porcelain=v2 | egrep -q '^# branch.head \(detached\)$'; then
    # Branch builds are not enabled or we are not in a branch
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
