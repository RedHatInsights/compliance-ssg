#!/bin/bash

set -e

REPOSITORY="$1"
REVISION="$2"
RHEL_VERSIONS="$3"
PLAYBOOKS_DIRECTORY="${4:-playbooks}"

validate_input() {

  if [ -z "$REPOSITORY" ] || [ -z "$REVISION" ] || [ -z "$RHEL_VERSIONS" ]; then
    echo "$0 REPOSITORY REVISION RHEL_VERSIONS [ PLAYBOOKS_DIRECTORY ]"
    exit 1
  fi
}

main() {

  local TMPDIR="$(mktemp -d --tmpdir=.)"

  download_cac_content "$REPOSITORY" "$REVISION" "$TMPDIR"

  if [ -e $PLAYBOOKS_DIRECTORY ]; then
    rm -rfv "$PLAYBOOKS_DIRECTORY"
  fi

  ( cd "$TMPDIR" && ./build_product $RHEL_VERSIONS )

  for version in $RHEL_VERSIONS; do
    mkdir -p "$PLAYBOOKS_DIRECTORY/$version"
    cp -r "$TMPDIR/build/$version/playbooks/." "$PLAYBOOKS_DIRECTORY/$version/"
  done

  rm -rf "$TMPDIR"
}

download_cac_content() {

  local REPOSITORY="$1"
  local REVISION="$2"
  local DESTINATION_DIR="$3"

    local URL="https://github.com/${REPOSITORY}/tarball/${REVISION}"
    curl -sL "$URL" --output - | tar xz --strip-components=1 -C "$DESTINATION_DIR"
}

validate_input
main
