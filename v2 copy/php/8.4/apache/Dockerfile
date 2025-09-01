# ==============================================================================
# MANI PHP 8.4 Apache Environment (v3.3 - Corrected & Finalized)
#
# Description:
#   Builds either a lean production image or a full-featured development image
#   from a single, cache-optimized Dockerfile. It uses a structured,
#   prefix-based naming convention for all build arguments for clarity.
#
# Build Development Image:
#   docker build . -f php/8.4/apache/Dockerfile \
#     --target development \
#     --build-arg PHP_EXT_XDEBUG=true \
#     --build-arg JS_RUNTIME_REQUIRE_NODE=true \
#     -t mani-apache:8.4-dev
#
# Build Production Image (default):
#   docker build . -f php/8.4/apache/Dockerfile \
#     --target production \
#     -t mani-apache:8.4
# ==============================================================================

# --- Stage 1: Base ---
# Contains the OS, PHP, and the most stable system dependencies.
ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-apache-bookworm AS base

LABEL maintainer="mani"
ENV DEBIAN_FRONTEND=noninteractive

# This is the most stable layer. It installs core system tools that rarely change.
COPY common/build/scripts/mani-docker-install-system-deps.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-system-deps.sh && \
    mani-docker-install-system-deps.sh


# --- Stage 2: Build Tools & Optional Components ---
# This stage builds ON the base and installs all optional components.
FROM base AS build_tools

# --- Structured Build-Time Arguments (ARG) ---
# These are the "switches" passed from docker-compose.yml.

# Database Clients
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

# JavaScript Runtimes
ARG JS_RUNTIME_NODE_VERSION=lts
ARG JS_RUNTIME_REQUIRE_NODE=true
ARG JS_RUNTIME_REQUIRE_DENO=false
ARG JS_RUNTIME_REQUIRE_BUN=false
ARG JS_RUNTIME_REQUIRE_YARN=false
ARG JS_RUNTIME_REQUIRE_PNPM=false

# This script installs ALL potential dependencies. It runs if ANY extension is enabled.
COPY common/build/scripts/mani-docker-install-php-ext-deps.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-php-ext-deps.sh && \
    # Promote ARGs to ENVs so the script can read them
    export PHP_EXT_PDO_PGSQL=$PHP_EXT_PDO_PGSQL && \
    export PHP_EXT_PDO_MYSQL=$PHP_EXT_PDO_MYSQL && \
    export PHP_EXT_MONGODB=$PHP_EXT_MONGODB && \
    export PHP_EXT_REDIS=$PHP_EXT_REDIS && \
    export PHP_EXT_MEMCACHED=$PHP_EXT_MEMCACHED && \
    export PHP_EXT_GD=$PHP_EXT_GD && \
    export PHP_EXT_IMAGICK=$PHP_EXT_IMAGICK && \
    export PHP_EXT_VIPS=$PHP_EXT_VIPS && \
    export PHP_EXT_XDEBUG=$PHP_EXT_XDEBUG && \
    if [ "$PHP_EXT_PDO_PGSQL" = "true" ] || \
       [ "$PHP_EXT_PDO_MYSQL" = "true" ] || \
       [ "$PHP_EXT_MONGODB" = "true" ] || \
       [ "$PHP_EXT_REDIS" = "true" ] || \
       [ "$PHP_EXT_MEMCACHED" = "true" ] || \
       [ "$PHP_EXT_GD" = "true" ] || \
       [ "$PHP_EXT_IMAGICK" = "true" ] || \
       [ "$PHP_EXT_VIPS" = "true" ] || \
       [ "$PHP_EXT_XDEBUG" = "true" ]; then \
        mani-docker-install-php-ext-deps.sh; \
    fi

# --- Individual PHP Extension Layers for Optimal Caching ---
RUN if [ "$PHP_EXT_PDO_PGSQL" = "true" ]; then docker-php-ext-install pdo_pgsql; fi
RUN if [ "$PHP_EXT_PDO_MYSQL" = "true" ]; then docker-php-ext-install pdo_mysql; fi
RUN if [ "$PHP_EXT_GD" = "true" ]; then docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp && docker-php-ext-install gd; fi
RUN if [ "$PHP_EXT_REDIS" = "true" ]; then pecl install redis && docker-php-ext-enable redis; fi
RUN if [ "$PHP_EXT_MEMCACHED" = "true" ]; then pecl install memcached && docker-php-ext-enable memcached; fi
RUN if [ "$PHP_EXT_MONGODB" = "true" ]; then pecl install mongodb && docker-php-ext-enable mongodb; fi
RUN if [ "$PHP_EXT_VIPS" = "true" ]; then pecl install vips && docker-php-ext-enable vips; fi
RUN if [ "$PHP_EXT_IMAGICK" = "true" ]; then pecl install imagick && docker-php-ext-enable imagick; fi
RUN if [ "$PHP_EXT_XDEBUG" = "true" ]; then pecl install xdebug && docker-php-ext-enable xdebug; fi

# --- Individual Tooling Layers for Optimal Caching ---
RUN if [ "$INSTALL_DB_PGSQL_CLIENT" = "true" ]; then \
    apt-get update && \
    apt-get install -y curl gnupg && \
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-key.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-client-${DB_PGSQL_CLIENT_VERSION}; \
fi

# RUN if [ "$INSTALL_DB_PGSQL_CLIENT" = "true" ]; then apt-get update && apt-get install -y postgresql-client-${DB_PGSQL_CLIENT_VERSION}; fi
RUN if [ "$INSTALL_DB_MYSQL_CLIENT" = "true" ]; then apt-get update && apt-get install -y default-mysql-client; fi

# Layer: JS Runtime Installation - Runs unconditionally. The script is smart enough to handle what to install.
COPY common/build/scripts/mani-docker-install-js-runtime.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mani-docker-install-js-runtime.sh && \
    # Promote ARGs to ENVs so the script can read them
    export JS_RUNTIME_REQUIRE_NODE=$JS_RUNTIME_REQUIRE_NODE && \
    export JS_RUNTIME_NODE_VERSION=$JS_RUNTIME_NODE_VERSION && \
    export JS_RUNTIME_REQUIRE_DENO=$JS_RUNTIME_REQUIRE_DENO && \
    export JS_RUNTIME_REQUIRE_BUN=$JS_RUNTIME_REQUIRE_BUN && \
    export JS_RUNTIME_REQUIRE_YARN=$JS_RUNTIME_REQUIRE_YARN && \
    export JS_RUNTIME_REQUIRE_PNPM=$JS_RUNTIME_REQUIRE_PNPM && \
    mani-docker-install-js-runtime.sh


# --- Stage 3: S6 Installer ---
FROM busybox:1.36 AS s6-installer
ARG S6_OVERLAY_VERSION="v3.1.6.2"
ADD "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" /tmp
ADD "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" /tmp


# --- Stage 4: Composer ---
FROM composer:latest AS composer


# --- Stage 5: Final Base ---
FROM base AS final_base

COPY --from=s6-installer /tmp/*.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && rm /tmp/*.tar.xz

RUN groupadd -g 1000 mani && useradd -u 1000 -g mani -m -s /bin/bash mani

# COPY common/runtime/configs/php/php.ini /usr/local/etc/php/conf.d/99-dockery-custom.ini
COPY common/runtime/configs/php/ /usr/local/etc/php/conf.d/
COPY common/runtime/configs/apache/ /etc/apache2/
COPY common/runtime/s6/cont-init.d/ /etc/s6-overlay/cont-init.d/
COPY common/runtime/s6/cont-finish.d/ /etc/s6-overlay/cont-finish.d/
COPY common/runtime/s6/variants/apache/services.d/ /etc/s6-overlay/services.d/
RUN chmod +x /etc/s6-overlay/cont-init.d/* \
 && find /etc/s6-overlay/services.d -name run -exec chmod +x {} \; \
 && find /etc/s6-overlay/services.d -path '*/log/run' -exec chmod +x {} \;


# --- Stage 6: Production ---
FROM final_base AS production

WORKDIR /var/www/html
USER root
COPY --chown=mani:mani . .

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN composer install --no-dev --optimize-autoloader && rm /usr/local/bin/composer

USER mani
ENTRYPOINT [ "/init" ]


# --- Stage 7: Development ---
FROM final_base AS development

COPY --from=build_tools /usr/local/ /usr/local/
COPY --from=build_tools /etc/apt/sources.list.d/ /etc/apt/sources.list.d/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
# COPY common/runtime/configs/php/20-xdebug.ini /usr/local/etc/php/conf.d/

EXPOSE 80
WORKDIR /var/www/html
USER mani
ENTRYPOINT [ "/init" ]
