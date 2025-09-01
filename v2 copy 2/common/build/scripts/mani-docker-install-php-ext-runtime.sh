#!/bin/sh
# ==============================================================================
# Installs ONLY runtime shared libraries needed by enabled PHP extensions.
# Debian Bookworm package names.
# ==============================================================================
set -e
export DEBIAN_FRONTEND=noninteractive

# Defaults
: "${PHP_EXT_GD:=false}"
: "${PHP_EXT_IMAGICK:=false}"
: "${PHP_EXT_VIPS:=false}"
: "${PHP_EXT_MEMCACHED:=false}"
: "${PHP_EXT_MONGODB:=false}"
: "${PHP_EXT_REDIS:=false}"

PKGS=""

add() { echo " $PKGS " | grep -q " $1 " || PKGS="$PKGS $1"; }

# gd (libpng16.so.16 missing, plus jpeg/freetype/webp/xpm)
[ "$PHP_EXT_GD" = "true" ] && add "libpng16-16 libjpeg62-turbo libfreetype6 libwebp7 libxpm4"

# imagick (MagickWand/Core)
[ "$PHP_EXT_IMAGICK" = "true" ] && add "libmagickwand-6.q16-6 libmagickcore-6.q16-6-extra imagemagick"

# vips (libvips.so.42)
[ "$PHP_EXT_VIPS" = "true" ] && add "libvips42 libvips-tools"

# memcached runtime deps
[ "$PHP_EXT_MEMCACHED" = "true" ] && add "libmemcached11 libzstd1 libevent-2.1-7"

# mongodb often relies on libssl3 (present on bookworm base, keep resilient)
[ "$PHP_EXT_MONGODB" = "true" ] && add "libssl3"

# (redis has no extra runtime deps)

[ -z "$PKGS" ] && exit 0

apt-get update
# shellcheck disable=SC2086
apt-get install -y --no-install-recommends $PKGS
apt-get clean && rm -rf /var/lib/apt/lists/*
