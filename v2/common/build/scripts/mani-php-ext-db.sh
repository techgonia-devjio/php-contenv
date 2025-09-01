#!/bin/sh

# ==============================================================================
# Domain: DATABASE CLIENTS & EXTENSIONS (MySQL, PostgreSQL, SQLite, Redis, Memcached, MongoDB)
# Modes:
#   --build   : add repos if needed, install -dev, compile/pecl, clients
#   --runtime : install runtime libs only (no -dev)
# ==============================================================================

set -eu
MODE="${1:---build}"
export DEBIAN_FRONTEND=noninteractive
[ "${DEBUG:-0}" = "1" ] && set -x && (env | grep -E '^(INSTALL_DB|DB_PGSQL|PHP_EXT_)' | sort || true)

# safe dedup without grep (avoids set -e pitfalls)
add() {
  case " ${PKG:-} " in *" $1 "*) ;; *) PKG="${PKG:-} $1" ;; esac
}

if [ "$MODE" = "--build" ]; then
  # Repos & clients
  if [ "${INSTALL_DB_PGSQL_CLIENT:-false}" = "true" ]; then
    apt-get update && apt-get install -y curl gnupg lsb-release && \
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql-key.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && apt-get install -y "postgresql-client-${DB_PGSQL_CLIENT_VERSION:-18}"
  fi
  if [ "${INSTALL_DB_MYSQL_CLIENT:-false}" = "true" ]; then
    apt-get update && apt-get install -y default-mysql-client
  fi

  # Build deps
  PKG=""
  [ "${PHP_EXT_PDO_PGSQL:-false}" = "true" ] && add libpq-dev
  if [ "${PHP_EXT_MEMCACHED:-false}" = "true" ]; then
    add libmemcached-dev; add zlib1g-dev; add libzstd-dev; add libevent-dev
  fi
  [ "${PHP_EXT_MONGODB:-false}" = "true" ] && add libssl-dev
  if [ "${PHP_EXT_SQLITE:-false}" = "true" ] || [ "${PHP_EXT_PDO_SQLITE:-false}" = "true" ]; then
    add libsqlite3-dev
  fi
  if [ -n "${PKG:-}" ]; then
    apt-get update && apt-get install -y --no-install-recommends $PKG && apt-get clean && rm -rf /var/lib/apt/lists/*
  fi

  # Core ext compile
  [ "${PHP_EXT_PDO_MYSQL:-false}" = "true" ]  && docker-php-ext-install -j"$(nproc)" pdo_mysql || true
  [ "${PHP_EXT_PDO_PGSQL:-false}" = "true" ]  && docker-php-ext-install -j"$(nproc)" pdo_pgsql || true
  [ "${PHP_EXT_SQLITE:-false}" = "true" ]     && docker-php-ext-install -j"$(nproc)" sqlite3   || true
  [ "${PHP_EXT_PDO_SQLITE:-false}" = "true" ] && docker-php-ext-install -j"$(nproc)" pdo_sqlite || true

  # PECL ext
  [ "${PHP_EXT_REDIS:-false}" = "true" ]      && { pecl install -o -f redis     && docker-php-ext-enable redis; }     || true
  [ "${PHP_EXT_MEMCACHED:-false}" = "true" ]  && { pecl install -o -f memcached && docker-php-ext-enable memcached; } || true
  [ "${PHP_EXT_MONGODB:-false}" = "true" ]    && { pecl install -o -f mongodb   && docker-php-ext-enable mongodb; }   || true
  exit 0
fi

# --runtime: libs only
PKG=""
[ "${PHP_EXT_PDO_PGSQL:-false}" = "true" ] && add libpq5
if [ "${PHP_EXT_MEMCACHED:-false}" = "true" ]; then
  add libmemcached11; add libzstd1; add libevent-2.1-7
fi
[ "${PHP_EXT_MONGODB:-false}" = "true" ] && add libssl3
if [ "${PHP_EXT_SQLITE:-false}" = "true" ] || [ "${PHP_EXT_PDO_SQLITE:-false}" = "true" ]; then
  add libsqlite3-0
fi
if [ -n "${PKG:-}" ]; then
  apt-get update && apt-get install -y --no-install-recommends $PKG && apt-get clean && rm -rf /var/lib/apt/lists/*
fi
