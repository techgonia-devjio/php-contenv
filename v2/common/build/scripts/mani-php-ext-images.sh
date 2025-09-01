#!/bin/sh
# ==============================================================================
# Domain: IMAGE/GRAPHICS EXTENSIONS (GD, Imagick, Vips)
# Modes:
#   --build   : install -dev, compile gd, pecl install imagick/vips
#   --runtime : install runtime libs (no -dev)
# Controlled by env: PHP_EXT_GD, PHP_EXT_IMAGICK, PHP_EXT_VIPS
# ==============================================================================
set -e
MODE="${1:---build}"
export DEBIAN_FRONTEND=noninteractive

if [ "$MODE" = "--build" ]; then
  PKG=""
  add(){ echo " $PKG " | grep -q " $1 " || PKG="$PKG $1"; }

  if [ "${PHP_EXT_GD:-false}" = "true" ]; then
    add "libpng-dev libjpeg62-turbo-dev libfreetype6-dev libwebp-dev libxpm-dev"
  fi
  [ "${PHP_EXT_IMAGICK:-false}" = "true" ] && add "libmagickwand-dev libmagickcore-6.q16-6-extra imagemagick"
  [ "${PHP_EXT_VIPS:-false}" = "true" ]    && add "libvips-dev libvips-tools"

  [ -n "$PKG" ] && { apt-get update && apt-get install -y --no-install-recommends $PKG && apt-get clean && rm -rf /var/lib/apt/lists/*; }

  [ "${PHP_EXT_GD:-false}" = "true" ] && { docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp && docker-php-ext-install -j"$(nproc)" gd; } || true
  [ "${PHP_EXT_IMAGICK:-false}" = "true" ] && { pecl install imagick && docker-php-ext-enable imagick; } || true
  [ "${PHP_EXT_VIPS:-false}" = "true" ]    && { pecl install vips && docker-php-ext-enable vips; } || true

  exit 0
fi

# RUNTIME libs
PKG=""
add(){ echo " $PKG " | grep -q " $1 " || PKG="$PKG $1"; }

[ "${PHP_EXT_GD:-false}" = "true" ]       && add "libpng16-16 libjpeg62-turbo libfreetype6 libwebp7 libxpm4"
[ "${PHP_EXT_IMAGICK:-false}" = "true" ]  && add "libmagickwand-6.q16-6 libmagickcore-6.q16-6-extra imagemagick"
[ "${PHP_EXT_VIPS:-false}" = "true" ]     && add "libvips42 libvips-tools"

[ -n "$PKG" ] && { apt-get update && apt-get install -y --no-install-recommends $PKG && apt-get clean && rm -rf /var/lib/apt/lists/*; }
