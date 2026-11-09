#!/usr/bin/env bash
set -euo pipefail

project=/opt/helpwise/librechat
stamp=$(date +%Y%m%d-%H%M%S)

cp "$project/docker-compose.override.yml" "$project/docker-compose.override.yml.bak-$stamp"
install -m 0644 /tmp/docker-compose.override.yml "$project/docker-compose.override.yml"
install -m 0644 /tmp/Caddyfile "$project/Caddyfile"

cd "$project"
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d caddy
sleep 15
docker compose -f docker-compose.yml -f docker-compose.override.yml ps
docker logs helpwise-caddy --tail 100
