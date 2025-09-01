#!/bin/sh
# ==============================================================================
# mani-docker-install-php-ext-deps.sh (v2 - Intelligent & Conditional)
#
# Description:
#   Intelligently installs development libraries (-dev packages) required to
#   compile ONLY the PHP extensions specified by the Docker build arguments.
#
# Environment Variables:
#   Reads all PHP_EXT_* and DB_CLIENT_* variables to determine which
#   dependencies to install.
# ==============================================================================

set -e

# --- Configuration ---
export DEBIAN_FRONTEND=noninteractive
# An array to hold the list of packages we need to install
PACKAGES_TO_INSTALL=""

# --- Helper Function ---
# Appends a package to the list if it's not already there.
add_pkg() {
    if ! echo "$PACKAGES_TO_INSTALL" | grep -q "$1"; then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $1"
    fi
}

# --- Dependency Mapping ---
# Read the build arguments from the environment and add required packages.
echo "----> Analyzing required PHP extension dependencies..."

if [ "$PHP_EXT_PDO_PGSQL" = "true" ]; then
    add_pkg "libpq-dev"
fi

if [ "$PHP_EXT_PDO_MYSQL" = "true" ]; then
    # No specific dev package needed, handled by the base image
    echo "      (MySQL PDO deps should have been included in the base image)"
fi

if [ "$PHP_EXT_GD" = "true" ]; then
    add_pkg "libpng-dev"
    add_pkg "libjpeg-dev"
    add_pkg "libfreetype6-dev"
    add_pkg "libwebp-dev"
    add_pkg "libjpeg62-turbo-dev"
    add_pkg "libxpm-dev"
fi

if [ "$PHP_EXT_IMAGICK" = "true" ]; then
    add_pkg "libmagickwand-dev"
fi

if [ "$PHP_EXT_VIPS" = "true" ]; then
    add_pkg "libvips-dev"
fi

if [ "$PHP_EXT_REDIS" = "true" ] || [ "$PHP_EXT_MEMCACHED" = "true" ]; then
    # These often depend on zlib for compression
    add_pkg "zlib1g-dev"
fi

if [ "$PHP_EXT_MEMCACHED" = "true" ]; then
    add_pkg "libmemcached-dev"
    # add_pkg "zlib1g-dev" # Also needed by memcached but already added previously
fi

if [ "$PHP_EXT_MONGODB" = "true" ]; then
    add_pkg "libssl-dev"
fi

# Add any other common dependencies needed by multiple extensions
add_pkg "libicu-dev"
add_pkg "libonig-dev"
add_pkg "libzip-dev"
add_pkg "libxml2-dev"
add_pkg "libreadline-dev"
add_pkg "libcurl4-openssl-dev"
add_pkg "fswatch"

# --- Main Execution ---
if [ -z "$PACKAGES_TO_INSTALL" ]; then
    echo "----> No PHP extension dependencies required. Skipping."
    exit 0
fi

echo "----> 1. Updating package lists..."
apt-get update

echo "----> 2. Installing the following PHP extension dependencies:"
echo "$PACKAGES_TO_INSTALL"
apt-get install -y --no-install-recommends $PACKAGES_TO_INSTALL

echo "----> 3. Cleaning up apt cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "----> PHP extension dependencies installed successfully."
