# ==============================================================================
# MANI Base PHP Environment (base/Dockerfile)
#
# Description:
#   This Dockerfile builds the foundational "toolbox" image. It starts from a
#   minimal official PHP CLI image and then uses our custom installer scripts
#   to add a comprehensive set of development tools, including a full suite of
#   PHP extensions, Node.js via NVM, and Composer.
#
#   This image is NOT intended to be run directly. Instead, it serves as a
#   heavily cached base layer for your final, runnable images (e.g., Apache,
#   Nginx, FrankenPHP).
#
# Build Example:
#   docker build . -f base/Dockerfile \
#     --build-arg PHP_VERSION=8.4 \
#     --build-arg NODE_VERSION=lts \
#     -t my-php-base:8.4
# ==============================================================================

# Use an ARG to define the PHP version. This makes the Dockerfile a reusable template.
ARG PHP_VERSION=8.4
# Start from the official PHP CLI image. It's lean and perfect for a base.
FROM php:${PHP_VERSION}-cli-bookworm

LABEL maintainer="mani"

# --- Build-Time Arguments ---
# Define configurable versions for our tools. These can be overridden during the build.
### JS Runtime config
ARG INSTALL_NODE_JS=true
ARG INSTALL_DENO=false
ARG INSTALL_BUN=false
ARG INSTALL_YARN=false
ARG INSTALL_PNPM=false
ARG NODE_VERSION=lts

ARG INSTALL_DB_PG_CLIENT=true
ARG INSTALL_DB_MYSQL_CLIENT=true
ARG INSTALL_DB_MONGODB=false
ARG INSTALL_DB_REDIS=false
ARG INSTALL_DB_MEMCACHED=false

ARG DB_MYSQL_CLIENT_VERSION=8
ARG DB_PG_CLIENT_VERSION=16


ARG DB_PG_EXTENSIONS="pdo_pgsql "
ARG DB_MYSQL_EXTENSIONS="pdo_mysql mysqli"
ARG DB_MONGO_DB_EXTENSIONS="mongodb"
ARG DB_REDIS_EXTENSIONS="redis"
ARG DB_MEMCACHED_EXTENSIONS="memcached"


ARG INSTALL_PHP_EXTENSIONS=true
ARG PHP_EXTENSIONS="opcache pcntl pdo_mysql pdo_pgsql redis zip"

ARG INSTALL_REDIS=true
ARG INSTALL_MEMCACHED=true
ARG INSTALL_MONGODB=true
ARG INSTALL_IMAGICK=true
ARG INSTALL_VIPS=true
ARG INSTALL_XDEBUG=true
ARG INSTALL_COMPOSER=true


ARG INSTALL_IMAGIC = true
ARG INSTALL_VIPS = true
ARG INSTALL_GD = true
ARG INSTALL_GD_EXT_CONFIG="--with-freetype --with-jpeg --with-webp --with-xpm --with-tiff --with-png --with-bmp --with-gd"

ARG HANDLE_EXTRA_DEPENDENCIES=
#ARG HANDLE_EXTRA_DEPENDENCIES="...."


# A known-good commit hash for Imagick to ensure reproducible builds.
ARG IMAGICK_COMMIT="7088edc353f53c4bc644573a79cdcd67a726ae16"

# --- Environment Variables ---
# Set environment variables that will be available in this image and any
# images built FROM it.
ENV NVM_DIR /usr/local/nvm
ENV DEBIAN_FRONTEND noninteractive

# --- Build Process ---

# 1. Copy our entire script library into the image's executable path.
# This invalidates the cache if ANY script changes, which is what we want.
COPY common/scripts/ /usr/local/bin/
# Ensure all scripts are executable.
RUN chmod +x /usr/local/bin/*

# 2. Run each installer script in a separate layer for optimal caching.
# Each RUN command creates a distinct layer. If a script doesn't change,
# Docker will reuse the cached layer from the previous build, making subsequent
# builds much faster.

# Layer: Core system tools (changes least often)
RUN mani-docker-install-system-deps.sh

# Layer: Dependencies for PHP extensions
RUN mani-docker-install-php-ext-deps.sh ${PG_CLIENT_VERSION}...  can't the scripts see the args automatically... or should we use env isntead of args?

# Layer: The PHP extensions themselves
RUN mani-docker-install-php-extensions.sh ${IMAGICK_COMMIT}

# Layer: Node.js environment (changes more often than PHP extensions)
RUN mani-docker-install-node.sh ${NODE_VERSION}

# Layer: Composer (changes least often, but needs to be after PHP is fully configured)
COPY --from=composer:latest /usr/local/bin/composer /usr/local/bin/composer

# --- Finalization ---

# Set a default working directory.
WORKDIR /var/www/html

# This is just a signal that the build is complete. This image is meant to be
# used as a base via "FROM my-php-base:8.4", not run directly.
CMD ["php", "-v"]

