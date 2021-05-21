#!/usr/bin/env bash

set -e

source /compliance_ssg/clowder-config-common

if isClowderEnabled; then

  echo "Reading Clowder config..."

  NGINX_PORT=$(ClowderConfigWebPort)

  if [ -z "$NGINX_PORT" ]; then
    echo "WebPort not configured in Clowder!"
    exit 1
  else
    echo "Updating port number to $NGINX_PORT according to configuration provided by Clowder"
    PATCHED_NGINX_CONF_FILE=$(mktemp)
    sed "/^\s\+listen/ s|[0-9]\+|${NGINX_PORT}|" "$NGINX_CONF_PATH" > "$PATCHED_NGINX_CONF_FILE"
    cat "$PATCHED_NGINX_CONF_FILE"
    nginx -c "$PATCHED_NGINX_CONF_FILE" -g "daemon off;"
  fi
else
  nginx -g "daemon off;"
fi
