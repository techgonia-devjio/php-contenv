# PHP 8.4 + FrankenPHP (Caddy) — Dev/Prod, s6, same extension installers, healthcheck
ARG PHP_VERSION=8.4
# OS: bookworm or alpine
ARG FrankenPHP_Version=1
ARG OS=bookworm
FROM dunglas/frankenphp:${FrankenPHP_Version}-php${PHP_VERSION}-${OS} AS base
# If this tag ever 404s, try: ghcr.io/dunglas/frankenphp:1-php8.4-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1

SHELL ["/bin/bash","-o","pipefail","-c"]

# Core OS deps (includes dos2unix)
COPY common/build/scripts/mani-docker-install-system-deps.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-system-deps.sh \
 && mani-docker-install-system-deps.sh

# ---------- Build tools & optional components ----------
FROM base AS build_tools

# DB Clients + PHP Extensions feature flags (same knobs you already use)
ARG INSTALL_DB_PGSQL_CLIENT=true
ARG DB_PGSQL_CLIENT_VERSION=18
ARG INSTALL_DB_MYSQL_CLIENT=true

ARG PHP_EXT_PDO_PGSQL=true
ARG PHP_EXT_PDO_MYSQL=true
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
ARG PHP_EXT_SOAP=false
ARG PHP_EXT_ZIP=true
ARG PHP_EXT_XSL=false
ARG PHP_EXT_GMP=false
ARG PHP_EXT_BCMATH=false
ARG PHP_EXT_EXIF=false
ARG PHP_EXT_PCNTL=false

# JS Runtimes
ARG JS_RUNTIME_NODE_VERSION=22
ARG JS_RUNTIME_REQUIRE_NODE=true
ARG JS_RUNTIME_REQUIRE_DENO=false
ARG JS_RUNTIME_REQUIRE_BUN=false
ARG JS_RUNTIME_REQUIRE_YARN=false
ARG JS_RUNTIME_REQUIRE_PNPM=false

# Extension installers (same domain scripts you already have)
COPY common/build/scripts/mani-php-ext-core.sh   /usr/local/bin/
COPY common/build/scripts/mani-php-ext-db.sh     /usr/local/bin/
COPY common/build/scripts/mani-php-ext-images.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-php-ext-*.sh

# Build-time passes
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

ENV PHP_EXT_GD=${PHP_EXT_GD} \
    PHP_EXT_IMAGICK=${PHP_EXT_IMAGICK} \
    PHP_EXT_VIPS=${PHP_EXT_VIPS}
RUN mani-php-ext-images.sh --build

ENV PHP_EXT_INTL=${PHP_EXT_INTL} \
    PHP_EXT_SOAP=${PHP_EXT_SOAP} \
    PHP_EXT_ZIP=${PHP_EXT_ZIP} \
    PHP_EXT_XSL=${PHP_EXT_XSL} \
    PHP_EXT_GMP=${PHP_EXT_GMP} \
    PHP_EXT_BCMATH=${PHP_EXT_BCMATH} \
    PHP_EXT_EXIF=${PHP_EXT_EXIF} \
    PHP_EXT_PCNTL=${PHP_EXT_PCNTL} \
    PHP_EXT_XDEBUG=${PHP_EXT_XDEBUG}
RUN mani-php-ext-core.sh --build

# JS runtimes
COPY common/build/scripts/mani-docker-install-js-runtime.sh /usr/local/bin/
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

# s6
COPY --from=s6-installer /tmp/s6-overlay-*.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
 && tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz \
 && rm /tmp/s6-overlay-*.tar.xz

# PHP conf + FrankenPHP (Caddyfile) + s6 services
COPY common/runtime/configs/php/           /usr/local/etc/php/conf.d/
COPY common/runtime/configs/frankenphp/    /etc/caddy/
COPY common/runtime/s6/cont-init.d/         /etc/cont-init.d/
COPY common/runtime/s6/cont-finish.d/       /etc/cont-finish.d/
COPY common/runtime/s6/variants/frankenphp/services.d/ /etc/services.d/

# Normalize EOLs and +x for s6
RUN find /etc/cont-init.d /etc/cont-finish.d /etc/services.d -type f -exec dos2unix {} \; \
 && chmod -R a+rx /etc/cont-init.d /etc/cont-finish.d \
 && find /etc/services.d -type f -name run -exec chmod a+rx {} \; \
 && find /etc/services.d -type f -name finish -exec chmod a+rx {} \; \
 && find /etc/services.d -type f -path '*/log/run' -exec chmod a+rx {} \; \
 && mkdir -p /var/log/{php,frankenphp} \
 && chown -R www-data:www-data /var/log/{php,frankenphp} \
 && chmod -R 775 /var/log/{php,frankenphp}


ENV HOME=/root \
    XDG_CONFIG_HOME=/etc/caddy \
    XDG_DATA_HOME=/var/lib/caddy \
    XDG_STATE_HOME=/var/lib/caddy

RUN mkdir -p /var/lib/caddy /etc/caddy \
 && chown -R www-data:www-data /var/lib/caddy || true
 
# Healthcheck
COPY common/runtime/healthchecks/healthcheck-frankenphp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck-frankenphp.sh
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD /usr/local/bin/healthcheck-frankenphp.sh || exit 1

# Runtime libs in final image (domain scripts in --runtime mode)
ARG INSTALL_DB_PGSQL_CLIENT=true
ARG DB_PGSQL_CLIENT_VERSION=18
ARG INSTALL_DB_MYSQL_CLIENT=true

ARG PHP_EXT_PDO_PGSQL=true
ARG PHP_EXT_PDO_MYSQL=true
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
ARG PHP_EXT_SOAP=false
ARG PHP_EXT_ZIP=true
ARG PHP_EXT_XSL=false
ARG PHP_EXT_GMP=false
ARG PHP_EXT_BCMATH=false
ARG PHP_EXT_EXIF=false
ARG PHP_EXT_PCNTL=false

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
    PHP_EXT_PCNTL=${PHP_EXT_PCNTL}

COPY common/build/scripts/mani-php-ext-core.sh   /usr/local/bin/
COPY common/build/scripts/mani-php-ext-db.sh     /usr/local/bin/
COPY common/build/scripts/mani-php-ext-images.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-php-ext-*.sh

RUN mani-php-ext-db.sh --runtime
RUN mani-php-ext-images.sh --runtime
RUN mani-php-ext-core.sh --runtime

# Sanity tool + bash history timestamping
COPY common/runtime/sanity/mani-sanity.sh /usr/local/bin/mani-sanity
COPY common/runtime/profile/zz-history.sh  /etc/profile.d/zz-history.sh
RUN chmod +x /usr/local/bin/mani-sanity && chmod 644 /etc/profile.d/zz-history.sh \
 && printf '\n[ -r /etc/profile.d/zz-history.sh ] && . /etc/profile.d/zz-history.sh\n' >> /etc/bash.bashrc

# COPY common/build/scripts/mani-sanity.sh /usr/local/bin/mani-sanity
# RUN chmod +x /usr/local/bin/mani-sanity

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

WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["/init"]
