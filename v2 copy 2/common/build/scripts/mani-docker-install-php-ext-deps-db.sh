#!/bin/sh
set -e
export DEBIAN_FRONTEND=noninteractive
: "${PHP_EXT_PDO_PGSQL:=false}"
: "${PHP_EXT_PDO_MYSQL:=false}"
PKGS=""
add(){ echo " $PKGS " | grep -q " $1 " || PKGS="$PKGS $1"; }

[ "$PHP_EXT_PDO_PGSQL" = "true" ] && add libpq-dev
# mysql pdo uses base headers in official image; no extra -dev needed

[ -z "$PKGS" ] && exit 0
apt-get update && apt-get install -y --no-install-recommends $PKGS
apt-get clean && rm -rf /var/lib/apt/lists/*
