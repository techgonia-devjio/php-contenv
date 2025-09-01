#!/bin/sh
set -e
export DEBIAN_FRONTEND=noninteractive
: "${PHP_EXT_GD:=false}"
: "${PHP_EXT_IMAGICK:=false}"
: "${PHP_EXT_VIPS:=false}"
PKGS=""
add(){ echo " $PKGS " | grep -q " $1 " || PKGS="$PKGS $1"; }

[ "$PHP_EXT_GD" = "true" ] && add "libpng-dev libjpeg62-turbo-dev libfreetype6-dev libwebp-dev libxpm-dev"
[ "$PHP_EXT_IMAGICK" = "true" ] && add "libmagickwand-dev libmagickcore-6.q16-6-extra imagemagick"
[ "$PHP_EXT_VIPS" = "true" ] && add "libvips-dev libvips-tools"

[ -z "$PKGS" ] && exit 0
apt-get update && apt-get install -y --no-install-recommends $PKGS
apt-get clean && rm -rf /var/lib/apt/lists/*
