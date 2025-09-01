# File: php/8.4/apache/Dockerfile
# ============================================================================
# PHP 8.4 + Apache — Dev/Prod, Multi-arch s6, Composer cache, Healthcheck
# ============================================================================
ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-apache-bookworm AS base

LABEL maintainer="mani"
ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    PATH="/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Core system tools
COPY common/build/scripts/mani-docker-install-system-deps.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-system-deps.sh && \
    mani-docker-install-system-deps.sh

# Apache mods
RUN a2enmod rewrite headers env dir mime proxy proxy_fcgi setenvif

# ---------- Build tools & optional components ----------
FROM base AS build_tools

# Build-time args (defaults)
# DB Clients
ARG INSTALL_DB_PGSQL_CLIENT=true
ARG DB_PGSQL_CLIENT_VERSION=18
ARG INSTALL_DB_MYSQL_CLIENT=true

# PHP Extensions
ARG PHP_EXT_PDO_PGSQL=true
ARG PHP_EXT_PDO_MYSQL=true
ARG PHP_EXT_MONGODB=true
ARG PHP_EXT_REDIS=true
ARG PHP_EXT_MEMCACHED=true
ARG PHP_EXT_GD=true
ARG PHP_EXT_IMAGICK=true
ARG PHP_EXT_VIPS=true
ARG PHP_EXT_XDEBUG=true
ARG PHP_EXT_INTL=true
ARG PHP_EXT_SOAP=false
ARG PHP_EXT_ZIP=true
ARG PHP_EXT_XSL=false
ARG PHP_EXT_GMP=false

# JS Runtimes
ARG JS_RUNTIME_NODE_VERSION=22
ARG JS_RUNTIME_REQUIRE_NODE=true
ARG JS_RUNTIME_REQUIRE_DENO=false
ARG JS_RUNTIME_REQUIRE_BUN=false
ARG JS_RUNTIME_REQUIRE_YARN=false
ARG JS_RUNTIME_REQUIRE_PNPM=false

# PHP build deps (split + core)
COPY common/build/scripts/mani-docker-install-php-ext-deps.sh /usr/local/bin/
COPY common/build/scripts/mani-docker-install-php-ext-deps-db.sh /usr/local/bin/
COPY common/build/scripts/mani-docker-install-php-ext-deps-image-drivers.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-php-ext-deps*.sh && \
    export PHP_EXT_PDO_PGSQL=$PHP_EXT_PDO_PGSQL PHP_EXT_PDO_MYSQL=$PHP_EXT_PDO_MYSQL \
           PHP_EXT_MONGODB=$PHP_EXT_MONGODB PHP_EXT_REDIS=$PHP_EXT_REDIS \
           PHP_EXT_MEMCACHED=$PHP_EXT_MEMCACHED PHP_EXT_GD=$PHP_EXT_GD \
           PHP_EXT_IMAGICK=$PHP_EXT_IMAGICK PHP_EXT_VIPS=$PHP_EXT_VIPS \
           PHP_EXT_INTL=$PHP_EXT_INTL PHP_EXT_SOAP=$PHP_EXT_SOAP \
           PHP_EXT_ZIP=$PHP_EXT_ZIP PHP_EXT_XSL=$PHP_EXT_XSL PHP_EXT_GMP=$PHP_EXT_GMP && \
    mani-docker-install-php-ext-deps.sh && \
    mani-docker-install-php-ext-deps-db.sh && \
    mani-docker-install-php-ext-deps-image-drivers.sh

# Core ext build/install (cache-friendly)
RUN set -eux; \
    docker-php-ext-install -j"$(nproc)" opcache; \
    [ "$PHP_EXT_PDO_MYSQL" = "true" ] && docker-php-ext-install pdo_mysql || true; \
    [ "$PHP_EXT_PDO_PGSQL" = "true" ] && docker-php-ext-install pdo_pgsql || true; \
    [ "$PHP_EXT_GD" = "true" ] && (docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp && docker-php-ext-install gd) || true; \
    [ "$PHP_EXT_INTL" = "true" ] && docker-php-ext-install intl || true; \
    [ "$PHP_EXT_SOAP" = "true" ] && docker-php-ext-install soap || true; \
    [ "$PHP_EXT_ZIP" = "true" ] && docker-php-ext-install zip || true; \
    [ "$PHP_EXT_XSL" = "true" ] && docker-php-ext-install xsl || true; \
    [ "$PHP_EXT_GMP" = "true" ] && docker-php-ext-install gmp || true

RUN set -eux; \
    [ "$PHP_EXT_REDIS" = "true" ] && (pecl install redis && docker-php-ext-enable redis) || true; \
    [ "$PHP_EXT_MEMCACHED" = "true" ] && (pecl install memcached && docker-php-ext-enable memcached) || true; \
    [ "$PHP_EXT_MONGODB" = "true" ] && (pecl install mongodb && docker-php-ext-enable mongodb) || true; \
    [ "$PHP_EXT_VIPS" = "true" ] && (pecl install vips && docker-php-ext-enable vips) || true; \
    [ "$PHP_EXT_IMAGICK" = "true" ] && (pecl install imagick && docker-php-ext-enable imagick) || true; \
    [ "$PHP_EXT_XDEBUG" = "true" ] && (pecl install xdebug) || true

# DB clients
RUN if [ "$INSTALL_DB_PGSQL_CLIENT" = "true" ]; then \
      apt-get update && apt-get install -y curl gnupg && \
      curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-key.gpg && \
      echo "deb [signed-by=/usr/share/keyrings/postgresql-key.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
      apt-get update && apt-get install -y postgresql-client-${DB_PGSQL_CLIENT_VERSION}; \
    fi
RUN if [ "$INSTALL_DB_MYSQL_CLIENT" = "true" ]; then apt-get update && apt-get install -y default-mysql-client; fi

# JS runtimes
COPY common/build/scripts/mani-docker-install-js-runtime.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-js-runtime.sh && \
    export JS_RUNTIME_REQUIRE_NODE=$JS_RUNTIME_REQUIRE_NODE \
           JS_RUNTIME_NODE_VERSION=$JS_RUNTIME_NODE_VERSION \
           JS_RUNTIME_REQUIRE_DENO=$JS_RUNTIME_REQUIRE_DENO \
           JS_RUNTIME_REQUIRE_BUN=$JS_RUNTIME_REQUIRE_BUN \
           JS_RUNTIME_REQUIRE_YARN=$JS_RUNTIME_REQUIRE_YARN \
           JS_RUNTIME_REQUIRE_PNPM=$JS_RUNTIME_REQUIRE_PNPM && \
    mani-docker-install-js-runtime.sh

# ---------- s6 overlay (multi-arch) ----------
FROM busybox:1.36 AS s6-installer
ARG S6_OVERLAY_VERSION="v3.1.6.2"
ARG TARGETARCH
RUN set -e; \
  case "${TARGETARCH}" in \
    amd64) ARCH=x86_64 ;; \
    arm64) ARCH=aarch64 ;; \
    arm)   ARCH=arm ;; \
    *)     ARCH=x86_64 ;; \
  esac; \
  wget -qO /tmp/s6-overlay-noarch.tar.xz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz && \
  wget -qO /tmp/s6-overlay-arch.tar.xz   https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz

# ---------- Composer ----------
FROM composer:latest AS composer

# ---------- Final base ----------
FROM base AS final_base

COPY --from=s6-installer /tmp/s6-overlay-*.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz

# Configs and s6 (legacy paths)
COPY common/runtime/configs/php/     /usr/local/etc/php/conf.d/
COPY common/runtime/configs/apache/  /etc/apache2/
COPY common/runtime/s6/cont-init.d/   /etc/cont-init.d/
COPY common/runtime/s6/cont-finish.d/ /etc/cont-finish.d/
COPY common/runtime/s6/variants/apache/services.d/ /etc/services.d/

# Normalize EOLs, strip BOMs, ensure +x, and fix apache log/run
RUN apt-get update && apt-get install -y --no-install-recommends dos2unix && rm -rf /var/lib/apt/lists/* && \
    find /etc/cont-init.d /etc/cont-finish.d /etc/services.d -type f -exec dos2unix {} \; && \
    chmod -R a+rx /etc/cont-init.d /etc/cont-finish.d && \
    find /etc/services.d -type f -name run -exec chmod a+rx {} \; && \
    find /etc/services.d -type f -name finish -exec chmod a+rx {} \; && \
    find /etc/services.d -type f -path '*/log/run' -exec chmod a+rx {} \; && \
    printf '%s\n' '#!/bin/sh' 'exec /command/s6-log n10 s100000 T /var/log/apache' > /etc/services.d/apache/log/run && \
    chmod +x /etc/services.d/apache/log/run

# Healthcheck
COPY common/runtime/healthchecks/healthcheck-apache.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck-apache.sh
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD /usr/local/bin/healthcheck-apache.sh || exit 1

# Runtime libs for enabled PHP extensions
COPY common/build/scripts/mani-docker-install-php-ext-runtime.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-php-ext-runtime.sh

# Re-declare subset of args to make them visible here
ARG PHP_EXT_GD=true
ARG PHP_EXT_IMAGICK=true
ARG PHP_EXT_VIPS=true
ARG PHP_EXT_MEMCACHED=false
ARG PHP_EXT_MONGODB=false
ARG PHP_EXT_REDIS=false
ARG PHP_EXT_XDEBUG=true

RUN export PHP_EXT_GD=$PHP_EXT_GD \
           PHP_EXT_IMAGICK=$PHP_EXT_IMAGICK \
           PHP_EXT_VIPS=$PHP_EXT_VIPS \
           PHP_EXT_MEMCACHED=$PHP_EXT_MEMCACHED \
           PHP_EXT_MONGODB=$PHP_EXT_MONGODB \
           PHP_EXT_REDIS=$PHP_EXT_REDIS && \
    mani-docker-install-php-ext-runtime.sh
#    mani-docker-install-php-ext-runtime.sh && \
#    { [ "$PHP_EXT_XDEBUG" = "true" ] || rm -f /usr/local/etc/php/conf.d/92-docker-php-ext-xdebug.ini; }

# ---------- Production ----------
FROM final_base AS production
WORKDIR /var/www/html
USER root

# Bring built extensions & tools
COPY --from=build_tools /usr/local/ /usr/local/
COPY --from=build_tools /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Composer (cache-friendly)
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader && rm /usr/local/bin/composer

# App code last
COPY . .
ENTRYPOINT ["/init"]

# ---------- Development ----------
FROM final_base AS development
USER root
COPY --from=build_tools /usr/local/ /usr/local/
COPY --from=build_tools /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

RUN mkdir -p /var/log/{php,apache2,frankenphp,nginx,swoole} \
 && chown -R www-data:www-data /var/log/{php,apache2,frankenphp,nginx,swoole} \
 && chmod -R 775 /var/log/{php,apache2,frankenphp,nginx,swoole}

WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["/init"]
