ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-apache-bookworm AS base

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1

SHELL ["/bin/bash","-o","pipefail","-c"]

# Path to the common resources relative to the build context
ARG DOCKER_RESOURCES_PATH=common

# Core OS deps (includes dos2unix)
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-docker-install-system-deps.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-system-deps.sh \
 && mani-docker-install-system-deps.sh

# Apache modules
RUN a2enmod rewrite headers env dir mime proxy proxy_fcgi setenvif

# ---------- Build tools & optional components ----------
FROM base AS build_tools

# DB Clients
ARG INSTALL_DB_PGSQL_CLIENT=false
ARG DB_PGSQL_CLIENT_VERSION=18
ARG INSTALL_DB_MYSQL_CLIENT=false

# PHP Extensions (feature flags)
ARG PHP_EXT_PDO_PGSQL=false
ARG PHP_EXT_PDO_MYSQL=false
ARG PHP_EXT_PDO_SQLITE=false
ARG PHP_EXT_SQLITE=false
ARG PHP_EXT_MONGODB=false
ARG PHP_EXT_REDIS=false
ARG PHP_EXT_MEMCACHED=false

ARG PHP_EXT_GD=true
ARG PHP_EXT_IMAGICK=true
ARG PHP_EXT_VIPS=true

ARG PHP_EXT_XDEBUG=true
ARG PHP_EXT_INTL=true
ARG PHP_EXT_SOAP=true
ARG PHP_EXT_ZIP=true
ARG PHP_EXT_XSL=true
ARG PHP_EXT_GMP=true
ARG PHP_EXT_BCMATH=true
ARG PHP_EXT_EXIF=true
ARG PHP_EXT_PCNTL=true
ARG PHP_EXT_FTP=true

# JS Runtimes
ARG JS_RUNTIME_NODE_VERSION=22
ARG JS_RUNTIME_REQUIRE_NODE=true
ARG JS_RUNTIME_REQUIRE_DENO=false
ARG JS_RUNTIME_REQUIRE_BUN=false
ARG JS_RUNTIME_REQUIRE_YARN=false
ARG JS_RUNTIME_REQUIRE_PNPM=false

# Domain scripts
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-php-ext-core.sh   /usr/local/bin/
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-php-ext-db.sh     /usr/local/bin/
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-php-ext-images.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-php-ext-*.sh

# Build-time: DB stack
ENV INSTALL_DB_PGSQL_CLIENT=${INSTALL_DB_PGSQL_CLIENT} \
    DB_PGSQL_CLIENT_VERSION=${DB_PGSQL_CLIENT_VERSION} \
    INSTALL_DB_MYSQL_CLIENT=${INSTALL_DB_MYSQL_CLIENT} \
    PHP_EXT_PDO_PGSQL=${PHP_EXT_PDO_PGSQL} \
    PHP_EXT_PDO_MYSQL=${PHP_EXT_PDO_MYSQL} \
    PHP_EXT_PDO_SQLITE=${PHP_EXT_PDO_SQLITE} \
    PHP_EXT_SQLITE=${PHP_EXT_SQLITE} \
    PHP_EXT_MONGODB=${PHP_EXT_MONGODB} \
    PHP_EXT_REDIS=${PHP_EXT_REDIS} \
    PHP_EXT_MEMCACHED=${PHP_EXT_MEMCACHED}
RUN mani-php-ext-db.sh --build

# Build-time: Image drivers
ENV PHP_EXT_GD=${PHP_EXT_GD} \
    PHP_EXT_IMAGICK=${PHP_EXT_IMAGICK} \
    PHP_EXT_VIPS=${PHP_EXT_VIPS}
RUN mani-php-ext-images.sh --build

# Build-time: Core non-DB extensions (+ Xdebug install only)
ENV PHP_EXT_INTL=${PHP_EXT_INTL} \
    PHP_EXT_SOAP=${PHP_EXT_SOAP} \
    PHP_EXT_ZIP=${PHP_EXT_ZIP} \
    PHP_EXT_XSL=${PHP_EXT_XSL} \
    PHP_EXT_GMP=${PHP_EXT_GMP} \
    PHP_EXT_BCMATH=${PHP_EXT_BCMATH} \
    PHP_EXT_EXIF=${PHP_EXT_EXIF} \
    PHP_EXT_PCNTL=${PHP_EXT_PCNTL} \
    PHP_EXT_FTP=${PHP_EXT_FTP} \
    PHP_EXT_XDEBUG=${PHP_EXT_XDEBUG}
RUN mani-php-ext-core.sh --build

# JS runtimes
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-docker-install-js-runtime.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-js-runtime.sh \
 && JS_RUNTIME_REQUIRE_NODE=${JS_RUNTIME_REQUIRE_NODE} \
    JS_RUNTIME_NODE_VERSION=${JS_RUNTIME_NODE_VERSION} \
    JS_RUNTIME_REQUIRE_DENO=${JS_RUNTIME_REQUIRE_DENO} \
    JS_RUNTIME_REQUIRE_BUN=${JS_RUNTIME_REQUIRE_BUN} \
    JS_RUNTIME_REQUIRE_YARN=${JS_RUNTIME_REQUIRE_YARN} \
    JS_RUNTIME_REQUIRE_PNPM=${JS_RUNTIME_REQUIRE_PNPM} \
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
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
 && tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz \
 && rm /tmp/s6-overlay-*.tar.xz

# Configs + s6
COPY ${DOCKER_RESOURCES_PATH}/runtime/configs/php/     /usr/local/etc/php/conf.d/
COPY ${DOCKER_RESOURCES_PATH}/runtime/configs/apache2/apache2.conf /etc/apache2/apache2.conf
COPY ${DOCKER_RESOURCES_PATH}/runtime/configs/apache2/conf-available/ /etc/apache2/conf-available/
COPY ${DOCKER_RESOURCES_PATH}/runtime/configs/apache2/sites-available/ /etc/apache2/sites-available/

COPY ${DOCKER_RESOURCES_PATH}/runtime/s6/cont-init.d/   /etc/cont-init.d/
COPY ${DOCKER_RESOURCES_PATH}/runtime/s6/cont-finish.d/ /etc/cont-finish.d/
COPY ${DOCKER_RESOURCES_PATH}/runtime/s6/variants/apache/services.d/ /etc/services.d/

# Normalize EOLs and ensure +x for s6 scripts
RUN find /etc/cont-init.d /etc/cont-finish.d /etc/services.d -type f -exec dos2unix {} \; \
 && chmod -R a+rx /etc/cont-init.d /etc/cont-finish.d \
 && find /etc/services.d -type f -name run -exec chmod a+rx {} \; \
 && find /etc/services.d -type f -name finish -exec chmod a+rx {} \; \
 && find /etc/services.d -type f -path '*/log/run' -exec chmod a+rx {} \;
# && printf '%s\n' '#!/bin/sh' 'exec /command/s6-log n10 s100000 T /var/log/apache' > /etc/services.d/apache/log/run \
# && chmod +x /etc/services.d/apache/log/run

# Sanity check script + bash history
COPY ${DOCKER_RESOURCES_PATH}/runtime/sanity/mani-sanity.sh /usr/local/bin/mani-sanity
COPY ${DOCKER_RESOURCES_PATH}/runtime/profile/zz-history.sh  /etc/profile.d/zz-history.sh
RUN chmod +x /usr/local/bin/mani-sanity && chmod 644 /etc/profile.d/zz-history.sh \
 && printf '\n[ -r /etc/profile.d/zz-history.sh ] && . /etc/profile.d/zz-history.sh\n' >> /etc/bash.bashrc

# Healthcheck
ARG ENABLE_HEALTHCHECK=false
ENV ENABLE_HEALTHCHECK=${ENABLE_HEALTHCHECK}
COPY ${DOCKER_RESOURCES_PATH}/runtime/healthchecks/healthcheck-apache.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck-apache.sh
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD /usr/local/bin/healthcheck-apache.sh || exit 1

ARG INSTALL_DB_PGSQL_CLIENT=false
ARG DB_PGSQL_CLIENT_VERSION=18
ARG INSTALL_DB_MYSQL_CLIENT=false

ARG PHP_EXT_PDO_PGSQL=false
ARG PHP_EXT_PDO_MYSQL=false
ARG PHP_EXT_PDO_SQLITE=false
ARG PHP_EXT_SQLITE=false
ARG PHP_EXT_MONGODB=false
ARG PHP_EXT_REDIS=false
ARG PHP_EXT_MEMCACHED=false

ARG PHP_EXT_GD=true
ARG PHP_EXT_IMAGICK=true
ARG PHP_EXT_VIPS=true

ARG PHP_EXT_XDEBUG=true
ARG PHP_EXT_INTL=true
ARG PHP_EXT_SOAP=true
ARG PHP_EXT_ZIP=true
ARG PHP_EXT_XSL=true
ARG PHP_EXT_GMP=true
ARG PHP_EXT_BCMATH=true
ARG PHP_EXT_EXIF=true
ARG PHP_EXT_FTP=true
ARG PHP_EXT_PCNTL=true

ENV INSTALL_DB_PGSQL_CLIENT=${INSTALL_DB_PGSQL_CLIENT} \
    DB_PGSQL_CLIENT_VERSION=${DB_PGSQL_CLIENT_VERSION} \
    INSTALL_DB_MYSQL_CLIENT=${INSTALL_DB_MYSQL_CLIENT} \
    PHP_EXT_PDO_PGSQL=${PHP_EXT_PDO_PGSQL} \
    PHP_EXT_PDO_MYSQL=${PHP_EXT_PDO_MYSQL} \
    PHP_EXT_PDO_SQLITE=${PHP_EXT_PDO_SQLITE} \
    PHP_EXT_SQLITE=${PHP_EXT_SQLITE} \
    PHP_EXT_MONGODB=${PHP_EXT_MONGODB} \
    PHP_EXT_REDIS=${PHP_EXT_REDIS} \
    PHP_EXT_MEMCACHED=${PHP_EXT_MEMCACHED} \
    PHP_EXT_GD=${PHP_EXT_GD} \
    PHP_EXT_IMAGICK=${PHP_EXT_IMAGICK} \
    PHP_EXT_VIPS=${PHP_EXT_VIPS} \
    PHP_EXT_XDEBUG=${PHP_EXT_XDEBUG} \
    PHP_EXT_INTL=${PHP_EXT_INTL} \
    PHP_EXT_SOAP=${PHP_EXT_SOAP} \
    PHP_EXT_ZIP=${PHP_EXT_ZIP} \
    PHP_EXT_XSL=${PHP_EXT_XSL} \
    PHP_EXT_GMP=${PHP_EXT_GMP} \
    PHP_EXT_BCMATH=${PHP_EXT_BCMATH} \
    PHP_EXT_EXIF=${PHP_EXT_EXIF} \
    PHP_EXT_FTP=${PHP_EXT_FTP} \
    PHP_EXT_PCNTL=${PHP_EXT_PCNTL}

# Copy domain scripts for runtime pass
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-php-ext-core.sh   /usr/local/bin/
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-php-ext-db.sh     /usr/local/bin/
COPY ${DOCKER_RESOURCES_PATH}/build/scripts/mani-php-ext-images.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-php-ext-*.sh

# Runtime passes (only shared libs and ini toggles)
RUN mani-php-ext-db.sh --runtime
RUN mani-php-ext-images.sh --runtime
RUN mani-php-ext-core.sh --runtime

# ---------- Production ----------
FROM final_base AS production
WORKDIR /var/www/html
USER root

COPY --from=build_tools /usr/local/ /usr/local/
COPY --from=build_tools /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader \
 && rm /usr/local/bin/composer

COPY . .
ENTRYPOINT ["/init"]

# ---------- Development ----------
FROM final_base AS development
USER root
COPY --from=build_tools /usr/local/ /usr/local/
COPY --from=build_tools /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

RUN mkdir -p /var/log/{php,apache2} \
 && chown -R www-data:www-data /var/log/{php,apache2} \
 && chmod -R 775 /var/log/{php,apache2}

WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["/init"]
