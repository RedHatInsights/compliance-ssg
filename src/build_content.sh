#!/bin/bash

set -e

REPOSITORY="$1"
REVISION="$2"
RHEL_VERSIONS="$3"
PLAYBOOKS_DIRECTORY="${4:-playbooks}"
DATASTREAMS_DIRECTORY="${5:-datastreams}"

main() {

  local TMP_WORKDIR=''
  TMP_WORKDIR="$(mktemp -d --tmpdir=.)"

  if [ -e "$PLAYBOOKS_DIRECTORY" ]; then
    rm -rfv "$PLAYBOOKS_DIRECTORY"
  fi
  mkdir -p "$PLAYBOOKS_DIRECTORY"

  if [ -e "$DATASTREAMS_DIRECTORY" ]; then
    rm -rfv "$DATASTREAMS_DIRECTORY"
  fi
  mkdir -p "$DATASTREAMS_DIRECTORY"

  # Build content directly from ComplianceAsCode/content repository
  build_upstream_content "$REPOSITORY" "$REVISION" "$RHEL_VERSIONS" "$TMP_WORKDIR"

  rm -rf "$TMP_WORKDIR"
}

reboot_handler_yaml() {

  echo "  handlers:
    - name: insights_reboot_handler
      set_fact:
        insights_needs_reboot: true"
}

inject_reboot_handler_to_playbooks() {

  # Check if any playbooks exist first
  if [ -z "$(find "$PLAYBOOKS_DIRECTORY" -name "*.yml" -type f -print -quit)" ]; then
    echo "No playbooks found, skipping reboot handler injection"
    return
  fi

  while read -r PLAYBOOK; do
    reboot_handler_yaml >> "$PLAYBOOK"
  done < <(find "$PLAYBOOKS_DIRECTORY" -name "*.yml" -exec grep -l 'reboot = true' {} \;)

  SHOULD_REBOOT=$(find "$PLAYBOOKS_DIRECTORY" -name "*.yml" -exec cat {} \; | grep -c 'reboot = true' || true)
  HAVE_REBOOT=$(find "$PLAYBOOKS_DIRECTORY" -name "*.yml" -exec cat {} \; | grep -c 'insights_needs_reboot: true' || true)

  if [[ "$SHOULD_REBOOT" -ne "$HAVE_REBOOT" ]]; then
    echo "Reboot handler injection discrepancy!"
    echo "SHOULD_REBOOT: $SHOULD_REBOOT"
    echo "HAVE_REBOOT: $HAVE_REBOOT"
    exit 1
  fi
}

link_to_mixedcase_profile_playbooks() {

  for f in "$PLAYBOOKS_DIRECTORY"/rhel*/*[[:upper:]]*; do
    # HACK: skip, if the path does not exist
    if [ -e "$f" ]; then
      ln -s "${f##*/}" "${f,,}"
    fi
  done
}

download_ssg_content() {

  local REPOSITORY="$1"
  local REVISION="$2"
  local DESTINATION_DIR="$3"

    local URL="https://github.com/${REPOSITORY}/tarball/${REVISION}"
    curl -sL "$URL" --output - | tar xz --strip-components=1 -C "$DESTINATION_DIR"
}

build_upstream_content() {
  local REPOSITORY="$1"
  local REVISION="$2"
  local RHEL_VERSIONS="$3"
  local TMP_WORKDIR="$4"

  echo "Building content from upstream repository: $REPOSITORY at $REVISION"

  # get scap-security-guide content from ComplianceAsCode/content
  download_ssg_content "$REPOSITORY" "$REVISION" "$TMP_WORKDIR"

  cd "$TMP_WORKDIR" || return 1

  # Parse RHEL versions from input parameter or use default
  local RHEL_VERSIONS_LIST="${RHEL_VERSIONS:-rhel8 rhel9 rhel10}"
  echo "Processing RHEL versions: $RHEL_VERSIONS_LIST"

  # Build and extract content for each RHEL version
  # Note: must extract after each build because build_product cleans the build dir
  for version in $RHEL_VERSIONS_LIST; do
    echo "Building $version"
    ./build_product "$version"

    # Return to original directory to access output directories
    cd - > /dev/null || return 1

    # Create version directory for playbooks
    local version_dir="$PLAYBOOKS_DIRECTORY/${version}"
    mkdir -p "$version_dir"

    # Extract playbooks - they are flat files like rhel8-playbook-*.yml
    find "$TMP_WORKDIR/build/ansible/" -maxdepth 1 -name "${version}-playbook-*.yml" -exec cp -v {} "$version_dir/" \;

    # Also copy the profile index file if it exists
    if [ -f "$TMP_WORKDIR/build/ansible/all-profile-playbooks-${version}" ]; then
      cp -v "$TMP_WORKDIR/build/ansible/all-profile-playbooks-${version}" "$version_dir/"
    fi

    # Extract datastream
    if [ -f "$TMP_WORKDIR/build/ssg-${version}-ds.xml" ]; then
      local pkg_dir="$DATASTREAMS_DIRECTORY/${version}/scap-security-guide-${REVISION#v}"
      mkdir -p "$pkg_dir"
      cp "$TMP_WORKDIR/build/ssg-${version}-ds.xml" "$pkg_dir/"
    fi

    # Return to temp workdir for next build
    cd "$TMP_WORKDIR" || return 1
  done

  # Return to original directory after all builds
  cd - > /dev/null || return 1

  inject_reboot_handler_to_playbooks
  link_to_mixedcase_profile_playbooks
}

main
