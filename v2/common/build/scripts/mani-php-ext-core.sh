#!/bin/sh

# Domain: CORE PHP EXTENSIONS
# Modes: --build (compile/pecl) | --runtime (runtime libs + ini toggles)
set -e
MODE="${1:---build}"
export DEBIAN_FRONTEND=noninteractive

if [ "$MODE" = "--build" ]; then
  PKG=""
  add(){ echo " $PKG " | grep -q " $1 " || PKG="$PKG $1"; }

  [ "${PHP_EXT_INTL:-false}" = "true" ]   && add "libicu-dev"
  [ "${PHP_EXT_SOAP:-false}" = "true" ]   && add "libxml2-dev"
  [ "${PHP_EXT_ZIP:-false}" = "true" ]    && add "libzip-dev"
  [ "${PHP_EXT_XSL:-false}" = "true" ]    && add "libxslt1-dev"
  [ "${PHP_EXT_GMP:-false}" = "true" ]    && add "libgmp-dev"
  # ftp
  [ "${PHP_EXT_FTP:-false}" = "true" ]    && add "libcurl4-gnutls-dev"

  [ -n "$PKG" ] && { apt-get update && apt-get install -y --no-install-recommends $PKG && apt-get clean && rm -rf /var/lib/apt/lists/*; }

  docker-php-ext-install -j"$(nproc)" opcache
  [ "${PHP_EXT_INTL:-false}" = "true" ]   && docker-php-ext-install -j"$(nproc)" intl || true
  [ "${PHP_EXT_SOAP:-false}" = "true" ]   && docker-php-ext-install -j"$(nproc)" soap || true
  [ "${PHP_EXT_ZIP:-false}" = "true" ]    && docker-php-ext-install -j"$(nproc)" zip  || true
  [ "${PHP_EXT_XSL:-false}" = "true" ]    && docker-php-ext-install -j"$(nproc)" xsl  || true
  [ "${PHP_EXT_GMP:-false}" = "true" ]    && docker-php-ext-install -j"$(nproc)" gmp  || true
  [ "${PHP_EXT_BCMATH:-false}" = "true" ] && docker-php-ext-install -j"$(nproc)" bcmath || true
  [ "${PHP_EXT_EXIF:-false}" = "true" ]   && docker-php-ext-install -j"$(nproc)" exif || true
  [ "${PHP_EXT_PCNTL:-false}" = "true" ]  && docker-php-ext-install -j"$(nproc)" pcntl || true
  [ "${PHP_EXT_FTP:-false}" = "true" ]    && docker-php-ext-install -j"$(nproc)" ftp || true


  # Xdebug: install only; ini controls activation at runtime
  [ "${PHP_EXT_XDEBUG:-true}" = "true" ] && pecl install xdebug || true

  # Swoole / OpenSwoole (optional)
  if [ "${PHP_EXT_SWOOLE:-false}" = "true" ]; then
    # try OpenSwoole first (preferred), then Swoole
    (pecl install -o -f openswoole && docker-php-ext-enable openswoole) || \
    (pecl install -o -f swoole      && docker-php-ext-enable swoole)
  fi
  
  exit 0
fi

# RUNTIME
PKG=""
add(){ echo " $PKG " | grep -q " $1 " || PKG="$PKG $1"; }

[ "${PHP_EXT_INTL:-false}" = "true" ] && add "libicu72"
[ "${PHP_EXT_SOAP:-false}" = "true" ] && add "libxml2"
[ "${PHP_EXT_ZIP:-false}" = "true" ]  && add "libzip4"
[ "${PHP_EXT_XSL:-false}" = "true" ]  && add "libxslt1.1"
[ "${PHP_EXT_GMP:-false}" = "true" ]  && add "libgmp10"

[ -n "$PKG" ] && { apt-get update && apt-get install -y --no-install-recommends $PKG && apt-get clean && rm -rf /var/lib/apt/lists/*; }

# If Xdebug disabled, drop ini to avoid loader warning
[ "${PHP_EXT_XDEBUG:-true}" = "true" ] || rm -f /usr/local/etc/php/conf.d/92-docker-php-ext-xdebug.ini || true

# install ftp and configuew with ssl  and curl
[ "${PHP_EXT_FTP:-false}" = "true" ] && {
  docker-php-ext-configure ftp --with-ftp-ssl
}

echo "----> Core PHP extensions installed successfully."
