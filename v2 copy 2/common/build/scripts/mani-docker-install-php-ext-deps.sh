#!/bin/sh
# ============================================================================
# mani-docker-install-php-ext-deps.sh (v2.1)
# - Conditional, expanded deps for PECL/ext builds
# ============================================================================
set -e
export DEBIAN_FRONTEND=noninteractive
PACKAGES_TO_INSTALL=""
add_pkg() { echo " $PACKAGES_TO_INSTALL " | grep -q " $1 " || PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $1"; }

# Inputs
: "${PHP_EXT_PDO_PGSQL:=false}"
: "${PHP_EXT_PDO_MYSQL:=false}"
: "${PHP_EXT_MONGODB:=false}"
: "${PHP_EXT_REDIS:=false}"
: "${PHP_EXT_MEMCACHED:=false}"
: "${PHP_EXT_GD:=false}"
: "${PHP_EXT_IMAGICK:=false}"
: "${PHP_EXT_VIPS:=false}"
: "${PHP_EXT_INTL:=false}"
: "${PHP_EXT_SOAP:=false}"
: "${PHP_EXT_ZIP:=false}"
: "${PHP_EXT_XSL:=false}"
: "${PHP_EXT_GMP:=false}"

[ "$PHP_EXT_PDO_PGSQL" = "true" ] && add_pkg libpq-dev
[ "$PHP_EXT_GD" = "true" ] && add_pkg "libpng-dev libjpeg-dev libjpeg62-turbo-dev libfreetype6-dev libwebp-dev libxpm-dev"
[ "$PHP_EXT_IMAGICK" = "true" ] && add_pkg "libmagickwand-dev imagemagick ghostscript libmagickcore-6.q16-6-extra"
[ "$PHP_EXT_VIPS" = "true" ] && add_pkg "libvips-dev libvips-tools"
[ "$PHP_EXT_REDIS" = "true" ] && add_pkg zlib1g-dev
if [ "$PHP_EXT_MEMCACHED" = "true" ]; then
  add_pkg "libmemcached-dev zlib1g-dev libzstd-dev libevent-dev"
fi
[ "$PHP_EXT_MONGODB" = "true" ] && add_pkg libssl-dev
[ "$PHP_EXT_INTL" = "true" ] && add_pkg libicu-dev
[ "$PHP_EXT_SOAP" = "true" ] && add_pkg libxml2-dev
[ "$PHP_EXT_ZIP" = "true" ] && add_pkg libzip-dev
[ "$PHP_EXT_XSL" = "true" ] && add_pkg libxslt1-dev
[ "$PHP_EXT_GMP" = "true" ] && add_pkg libgmp-dev

# Common build tools (if not already)
add_pkg "pkg-config autoconf libonig-dev libreadline-dev libsqlite3-dev libcurl4-openssl-dev fswatch"

if [ -z "$PACKAGES_TO_INSTALL" ]; then
  echo "----> No PHP extension dependencies required. Skipping."
  exit 0
fi

echo "----> 1. Updating package lists..." && apt-get update

echo "----> 2. Installing PHP build dependencies:" && echo "$PACKAGES_TO_INSTALL"
# shellcheck disable=SC2086
apt-get install -y --no-install-recommends $PACKAGES_TO_INSTALL

echo "----> 3. Cleaning up apt cache..."
apt-get clean && rm -rf /var/lib/apt/lists/*

echo "----> PHP extension dependencies installed successfully."