#!/bin/bash

set -exv

IMAGE_NAME="quay.io/cloudservices/compliance-ssg"
IMAGE_TAG=$(git rev-parse --short=7 HEAD)

if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
    echo "QUAY_USER and QUAY_TOKEN must be set"
    exit 1
fi

REPOSITORY="ComplianceAsCode/content"
REVISION="v0.1.53"
RHEL_VERSIONS="rhel6 rhel7 rhel8"

APP_ROOT="$PWD"
DOCKER_CONF="$APP_ROOT/.docker"
DOCKERFILE=${DOCKERFILE:="Dockerfile"}

if [ ! -r "${APP_ROOT}/${DOCKERFILE}" ]; then
    echo "ERROR: No ${DOCKERFILE} found or not readable"
    exit 1
fi

mkdir -p "$DOCKER_CONF"

if test -f /etc/redhat-release && grep -q -i "release 7" /etc/redhat-release; then
    docker --config="$DOCKER_CONF" login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
    docker --config="$DOCKER_CONF" login -u="$RH_REGISTRY_USER" -p="$RH_REGISTRY_TOKEN" registry.redhat.io
    docker --config="$DOCKER_CONF" build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "${APP_ROOT}/${DOCKERFILE}" \
       --build-arg REPOSITORY="$REPOSITORY" --build-arg REVISION="$REVISION" \
       --build-arg RHEL_VERSIONS="$RHEL_VERSIONS" "$APP_ROOT"
    docker --config="$DOCKER_CONF" push "${IMAGE_NAME}:${IMAGE_TAG}"

    # To enable backwards compatibility with ci, qa, and smoke, always push latest and qa tags
    for TAG in "latest" "qa"; do
        docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:$TAG"
        docker --config="$DOCKER_CONF" push "${IMAGE_NAME}:$TAG"
    done
else
    AUTH_CONF_DIR="$(pwd)/.podman"
    mkdir -p "${AUTH_CONF_DIR}"
    export REGISTRY_AUTH_FILE="${AUTH_CONF_DIR}/auth.json"
    podman login -u="${QUAY_USER}" -p="${QUAY_TOKEN}" quay.io
    podman login -u="${RH_REGISTRY_USER}" -p="${RH_REGISTRY_TOKEN}" registry.redhat.io
    podman build -f "${APP_ROOT}/${DOCKERFILE}" -t "${IMAGE}:${IMAGE_TAG}" $APP_ROOT
    podman push "${IMAGE}:${IMAGE_TAG}"

    # To enable backwards compatibility with ci, qa, and smoke, always push latest and qa tags
    for TAG in "latest" "qa"; do
        podman tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:$TAG"
        podman --config="$DOCKER_CONF" push "${IMAGE_NAME}:$TAG"
    done
fi
