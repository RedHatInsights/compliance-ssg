#!/usr/bin/env bash

set -e

NGINX_PORT=${NGINX_PORT:-8080}

CFGFILE=$(mktemp)

sed "s/##PORT##/${NGINX_PORT}/" "/compliance_ssg/nginx_conf_template" | tee "$CFGFILE"
exec nginx -c "$CFGFILE"
