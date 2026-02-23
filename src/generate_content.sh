#!/usr/bin/env bash

set -e

export CICD_BOOTSTRAP_REPO_BRANCH='main'
export CICD_BOOTSTRAP_REPO_ORG='RedHatInsights'
CICD_TOOLS_URL="https://raw.githubusercontent.com/${CICD_BOOTSTRAP_REPO_ORG}/cicd-tools/${CICD_BOOTSTRAP_REPO_BRANCH}/src/bootstrap.sh"
# shellcheck source=/dev/null
source <(curl -sSL "$CICD_TOOLS_URL") image_builder

WORKDIR=${WORKDIR:-$(pwd)}
TARGET_DIRECTORY="${4:-${WORKDIR}/content}"
TEMP_CONTAINER=''
TEMP_IMAGE=''

export CICD_IMAGE_BUILDER_CONTAINERFILE_PATH="${WORKDIR}/src/content.Dockerfile"
export CICD_IMAGE_BUILDER_IMAGE_NAME="ssg-generator"

main() {

    local PLAYBOOKS_DIR="${TARGET_DIRECTORY}/playbooks"
    local DATASTREAMS_DIR="${TARGET_DIRECTORY}/datastreams"

    echo "Building temporary image..."

    if ! cicd::image_builder::build; then
        echo "Error building temporary image!"
        return 1
    fi

    TEMP_IMAGE=$(cicd::image_builder::get_full_image_name)
    echo "Image ${TEMP_IMAGE} built successfully"

    if ! TEMP_CONTAINER=$(cicd::container::cmd create "$TEMP_IMAGE"); then
        echo "Error creating temporary container!"
        return 1
    fi

    echo "Temporary container ID: $TEMP_CONTAINER"

    _extract_playbooks || return 1
    _extract_datastreams || return 1
}

_extract_playbooks(){

    # Ensure target directory exists
    mkdir -p "$TARGET_DIRECTORY"
    echo "Created target directory: $TARGET_DIRECTORY"

    if [ -d "$PLAYBOOKS_DIR" ]; then
        echo "playbooks destination directory '$PLAYBOOKS_DIR' exists, deleting..."
        rm -rf "$PLAYBOOKS_DIR"
    fi

    echo "Extracting playbooks..."

    if cicd::container::cmd cp "${TEMP_CONTAINER}:/workdir/playbooks" "$TARGET_DIRECTORY/"; then
        echo "Playbooks extracted successfully to '$PLAYBOOKS_DIR'"
    else
        echo "something went wrong extracting playbooks from the temporary container"
        return 1
    fi
}

_extract_datastreams() {

    # Ensure target directory exists
    mkdir -p "$TARGET_DIRECTORY"
    echo "Target directory confirmed: $TARGET_DIRECTORY"

    echo "Extracting datastreams..."
    if cicd::container::cmd cp "${TEMP_CONTAINER}:/workdir/datastreams" "$TARGET_DIRECTORY/"; then
        echo "Datastreams extracted successfully to '$DATASTREAMS_DIR'"
    else
        echo "something went wrong extracting datastreams from the temporary container"
        return 1
    fi
}

init() {
    trap teardown EXIT SIGINT SIGTERM
}

teardown() {

    if [ -n "$TEMP_CONTAINER" ]; then
      cicd::container::cmd rm "$TEMP_CONTAINER" || echo "Could not delete temporary container: $TEMP_CONTAINER"
    fi
    if [ -n "$TEMP_IMAGE" ]; then
      cicd::container::cmd rmi "$TEMP_IMAGE" || echo "Could not delete temporary image: $TEMP_IMAGE"
    fi
}

init && main || exit 1
