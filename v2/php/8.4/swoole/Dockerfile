# PHP 8.4 + Swoole/OpenSwoole — Dev/Prod, optional Nginx front, s6, healthchecks
ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-cli-bookworm AS base

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1
SHELL ["/bin/bash","-o","pipefail","-c"]

# Core OS deps (includes dos2unix, gosu, etc.)
COPY common/build/scripts/mani-docker-install-system-deps.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-system-deps.sh \
 && mani-docker-install-system-deps.sh

# ---------- Build tools ----------
FROM base AS build_tools

# Feature flags
ARG PHP_EXT_SWOOLE=false
ARG PHP_EXT_INTL=true
ARG PHP_EXT_ZIP=true
ARG PHP_EXT_GD=true
ARG PHP_EXT_IMAGICK=true
ARG PHP_EXT_VIPS=true
ARG PHP_EXT_PDO_MYSQL=true
ARG PHP_EXT_PDO_PGSQL=false
ARG PHP_EXT_PDO_SQLITE=false
ARG PHP_EXT_SQLITE=false
ARG PHP_EXT_MONGODB=false
ARG PHP_EXT_REDIS=false
ARG PHP_EXT_MEMCACHED=false
ARG PHP_EXT_XDEBUG=true

# DB clients (optional)
ARG INSTALL_DB_PGSQL_CLIENT=false
ARG DB_PGSQL_CLIENT_VERSION=18
ARG INSTALL_DB_MYSQL_CLIENT=true

# JS Runtimes (optional)
ARG JS_RUNTIME_REQUIRE_NODE=true
ARG JS_RUNTIME_NODE_VERSION=22
ARG JS_RUNTIME_REQUIRE_DENO=false
ARG JS_RUNTIME_REQUIRE_BUN=false
ARG JS_RUNTIME_REQUIRE_YARN=false
ARG JS_RUNTIME_REQUIRE_PNPM=false

# Domain scripts
COPY common/build/scripts/mani-php-ext-core.sh   /usr/local/bin/
COPY common/build/scripts/mani-php-ext-db.sh     /usr/local/bin/
COPY common/build/scripts/mani-php-ext-images.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-php-ext-*.sh

# Build-time passes
ENV PHP_EXT_SWOOLE=${PHP_EXT_SWOOLE} \
    PHP_EXT_INTL=${PHP_EXT_INTL} \
    PHP_EXT_ZIP=${PHP_EXT_ZIP} \
    PHP_EXT_GD=${PHP_EXT_GD} \
    PHP_EXT_IMAGICK=${PHP_EXT_IMAGICK} \
    PHP_EXT_VIPS=${PHP_EXT_VIPS} \
    PHP_EXT_PDO_MYSQL=${PHP_EXT_PDO_MYSQL} \
    PHP_EXT_PDO_PGSQL=${PHP_EXT_PDO_PGSQL} \
    PHP_EXT_PDO_SQLITE=${PHP_EXT_PDO_SQLITE} \
    PHP_EXT_SQLITE=${PHP_EXT_SQLITE} \
    PHP_EXT_MONGODB=${PHP_EXT_MONGODB} \
    PHP_EXT_REDIS=${PHP_EXT_REDIS} \
    PHP_EXT_MEMCACHED=${PHP_EXT_MEMCACHED} \
    INSTALL_DB_PGSQL_CLIENT=${INSTALL_DB_PGSQL_CLIENT} \
    DB_PGSQL_CLIENT_VERSION=${DB_PGSQL_CLIENT_VERSION} \
    INSTALL_DB_MYSQL_CLIENT=${INSTALL_DB_MYSQL_CLIENT} \
    PHP_EXT_XDEBUG=${PHP_EXT_XDEBUG}
RUN mani-php-ext-db.sh --build
RUN mani-php-ext-images.sh --build
RUN mani-php-ext-core.sh --build

# JS runtimes (optional)
COPY common/build/scripts/mani-docker-install-js-runtime.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-js-runtime.sh \
 && JS_RUNTIME_REQUIRE_NODE=${JS_RUNTIME_REQUIRE_NODE} \
    JS_RUNTIME_NODE_VERSION=${JS_RUNTIME_NODE_VERSION} \
    JS_RUNTIME_REQUIRE_DENO=${JS_RUNTIME_REQUIRE_DENO} \
    JS_RUNTIME_REQUIRE_BUN=${JS_RUNTIME_REQUIRE_BUN} \
    JS_RUNTIME_REQUIRE_YARN=${JS_RUNTIME_REQUIRE_YARN} \
    JS_RUNTIME_REQUIRE_PNPM=${JS_RUNTIME_REQUIRE_PNPM} \
    mani-docker-install-js-runtime.sh

# ---------- s6 overlay ----------
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

# ---------- Final base (swoole-only) ----------
FROM base AS final_base

COPY --from=s6-installer /tmp/s6-overlay-*.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
 && tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz \
 && rm /tmp/s6-overlay-*.tar.xz

# PHP ini + s6 services + server + sanity/history + healthcheck
COPY common/runtime/configs/php/                              /usr/local/etc/php/conf.d/
COPY common/runtime/s6/cont-init.d/                           /etc/cont-init.d/
COPY common/runtime/s6/cont-finish.d/                         /etc/cont-finish.d/
COPY common/runtime/s6/variants/swoole/services.d/            /etc/services.d/
COPY common/runtime/healthchecks/healthcheck-swoole.sh        /usr/local/bin/
COPY common/runtime/swoole/mani-swoole-server                 /usr/local/bin/mani-swoole-server
COPY common/runtime/sanity/mani-sanity.sh                     /usr/local/bin/mani-sanity
COPY common/runtime/profile/zz-history.sh                     /etc/profile.d/zz-history.sh

RUN chmod +x /usr/local/bin/healthcheck-swoole.sh \
            /usr/local/bin/mani-swoole-server \
            /usr/local/bin/mani-sanity \
 && find /etc/cont-init.d /etc/cont-finish.d /etc/services.d -type f -exec dos2unix {} \; \
 && chmod -R a+rx /etc/cont-init.d /etc/cont-finish.d \
 && find /etc/services.d -type f -name run -exec chmod a+rx {} \; \
 && mkdir -p /var/log/{php,swoole} \
 && chown -R www-data:www-data /var/log/{php,swoole} \
 && chmod -R 775 /var/log/{php,swoole} \
 && printf '\n[ -r /etc/profile.d/zz-history.sh ] && . /etc/profile.d/zz-history.sh\n' >> /etc/bash.bashrc

HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD /usr/local/bin/healthcheck-swoole.sh || exit 1

# Runtime libs (domain scripts in --runtime mode)
ARG PHP_EXT_SWOOLE=false
ARG PHP_EXT_INTL=true
ARG PHP_EXT_ZIP=true
ARG PHP_EXT_GD=true
ARG PHP_EXT_IMAGICK=true
ARG PHP_EXT_VIPS=true
ARG PHP_EXT_PDO_MYSQL=true
ARG PHP_EXT_PDO_PGSQL=false
ARG PHP_EXT_PDO_SQLITE=false
ARG PHP_EXT_SQLITE=false
ARG PHP_EXT_MONGODB=false
ARG PHP_EXT_REDIS=false
ARG PHP_EXT_MEMCACHED=false
ARG PHP_EXT_XDEBUG=true
ARG INSTALL_DB_PGSQL_CLIENT=false
ARG DB_PGSQL_CLIENT_VERSION=18
ARG INSTALL_DB_MYSQL_CLIENT=true

ENV PHP_EXT_SWOOLE=${PHP_EXT_SWOOLE} \
    PHP_EXT_INTL=${PHP_EXT_INTL} \
    PHP_EXT_ZIP=${PHP_EXT_ZIP} \
    PHP_EXT_GD=${PHP_EXT_GD} \
    PHP_EXT_IMAGICK=${PHP_EXT_IMAGICK} \
    PHP_EXT_VIPS=${PHP_EXT_VIPS} \
    PHP_EXT_PDO_MYSQL=${PHP_EXT_PDO_MYSQL} \
    PHP_EXT_PDO_PGSQL=${PHP_EXT_PDO_PGSQL} \
    PHP_EXT_PDO_SQLITE=${PHP_EXT_PDO_SQLITE} \
    PHP_EXT_SQLITE=${PHP_EXT_SQLITE} \
    PHP_EXT_MONGODB=${PHP_EXT_MONGODB} \
    PHP_EXT_REDIS=${PHP_EXT_REDIS} \
    PHP_EXT_MEMCACHED=${PHP_EXT_MEMCACHED} \
    INSTALL_DB_PGSQL_CLIENT=${INSTALL_DB_PGSQL_CLIENT} \
    DB_PGSQL_CLIENT_VERSION=${DB_PGSQL_CLIENT_VERSION} \
    INSTALL_DB_MYSQL_CLIENT=${INSTALL_DB_MYSQL_CLIENT} \
    PHP_EXT_XDEBUG=${PHP_EXT_XDEBUG}

COPY common/build/scripts/mani-php-ext-core.sh   /usr/local/bin/
COPY common/build/scripts/mani-php-ext-db.sh     /usr/local/bin/
COPY common/build/scripts/mani-php-ext-images.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-php-ext-*.sh \
 && mani-php-ext-db.sh --runtime \
 && mani-php-ext-images.sh --runtime \
 && mani-php-ext-core.sh --runtime

# ---------- Optional Nginx front ----------
FROM final_base AS nginx_base
RUN apt-get update && apt-get install -y --no-install-recommends nginx && rm -rf /var/lib/apt/lists/*
COPY common/runtime/configs/nginx/                          /etc/nginx/
COPY common/runtime/healthchecks/healthcheck-nginx.sh       /usr/local/bin/
COPY common/runtime/s6/variants/nginx-swoole/services.d/    /etc/services.d/
RUN chmod +x /usr/local/bin/healthcheck-nginx.sh \
 && find /etc/services.d -type f -name run -exec chmod a+rx {} \; \
 && mkdir -p /var/log/nginx \
 && chown -R www-data:www-data /var/log/nginx \
 && chmod -R 775 /var/log/nginx
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD /usr/local/bin/healthcheck-nginx.sh || exit 1

# ---------- Production (swoole-only) ----------
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

# ---------- Development (swoole-only) ----------
FROM final_base AS development
USER root
COPY --from=build_tools /usr/local/ /usr/local/
COPY --from=build_tools /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["/init"]

# ---------- Production (nginx → swoole) ----------
FROM nginx_base AS production-nginx
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

# ---------- Development (nginx → swoole) ----------
FROM nginx_base AS development-nginx
USER root
COPY --from=build_tools /usr/local/ /usr/local/
COPY --from=build_tools /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
WORKDIR /var/www/html
EXPOSE 80
ENTRYPOINT ["/init"]
