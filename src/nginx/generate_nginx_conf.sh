#!/bin/bash

set -e

NGINX_CONF_TEMPLATE="$1"
REVISION="$2"

if [ -z "$REVISION" ] || [ -z "$NGINX_CONF_TEMPLATE" ] || [ ! -r "$NGINX_CONF_TEMPLATE" ]; then
  echo "usage: $0 NGINX_CONF_TEMPLATE REVISION"
  exit 1
fi

cat "$NGINX_CONF_TEMPLATE" | sed -s "s/##REVISION##/${REVISION}/"
