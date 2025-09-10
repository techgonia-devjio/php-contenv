# Configuration Reference

This page enumerates **build args** (image features) and **runtime env** (container behavior). Defaults come from the submodule Dockerfiles and INIs.

## Build-time arguments (common across images)

| Arg                      |    Default | Purpose / Notes                                                                                                                    |
| ------------------------ | ---------: | ---------------------------------------------------------------------------------------------------------------------------------- |
| `PHP_VERSION`            |      `8.4` | Base PHP version tag used by images (e.g. `php:8.4-fpm-bookworm`, `php:8.4-cli-bookworm`, `dunglas/frankenphp:1-php8.4-bookworm`). |
| `OS` *(FrankenPHP only)* | `bookworm` | Base OS for FrankenPHP tag (e.g. `bookworm` or `alpine`).                                                                          |
| `FrankenPHP_Version`     |        `1` | Tag stem for `dunglas/frankenphp` (`1-php8.4-<OS>`).                                                                               |
| `S6_OVERLAY_VERSION`     | `v3.1.6.2` | s6-overlay tarballs to fetch in the multi-arch stage.                                                                              |


---

## Build args — DB clients & PHP DB extensions  *(mani-php-ext-db.sh)*

| Arg                       | Default | Notes |
| ---                       | ---: | --- |
| `INSTALL_DB_MYSQL_CLIENT` | `true`  | Installs `default-mysql-client`. |
| `INSTALL_DB_PGSQL_CLIENT` | `false` | Adds PGDG and installs `postgresql-client-<ver>`. |
| `DB_PGSQL_CLIENT_VERSION` | `18`    | PG client major version. |
| `PHP_EXT_PDO_MYSQL`       | `true`  | Enable/Compile `pdo_mysql`. |
| `PHP_EXT_PDO_PGSQL`       | `false` | Enable/Compile `pdo_pgsql` (needs `libpq-dev` during build). |
| `PHP_EXT_SQLITE`          | `false` | `sqlite3` ext. |
| `PHP_EXT_PDO_SQLITE`      | `false` | `pdo_sqlite` ext. |
| `PHP_EXT_REDIS`           | `false` | PECL `redis`. |
| `PHP_EXT_MEMCACHED`       | `false` | PECL `memcached` (+ runtime libs). |
| `PHP_EXT_MONGODB`         | `false` | PECL `mongodb` (+ `libssl` runtime). |


## Build args — Core PHP extensions  *(mani-php-ext-core.sh)*

| Arg              | Default | Notes |
| ---              | ---: | --- |
| `PHP_EXT_INTL`   | `true`  | `intl` + ICU runtime. |
| `PHP_EXT_SOAP`   | `false` | SOAP + libxml dev. |
| `PHP_EXT_ZIP`    | `true`  | `zip` + libzip. |
| `PHP_EXT_XSL`    | `false` | libxslt. |
| `PHP_EXT_GMP`    | `false` | libgmp. |
| `PHP_EXT_BCMATH` | `false` | `bcmath`. |
| `PHP_EXT_EXIF`   | `false` | `exif`. |
| `PHP_EXT_PCNTL`  | `false` | `pcntl` (CLI use). |
| `PHP_EXT_XDEBUG` | `true`  | Installs Xdebug; **runtime controls activation**. |
| `PHP_EXT_SWOOLE` | `false` | For Swoole profile; tries openswoole first. (Doesn't work yet) |

> opcache is always built in mani-php-ext-core.sh.

## Build args — Imaging  *(mani-php-ext-images.sh)*

| Arg | Default | Notes |
| --- | ---: | --- |
| `PHP_EXT_GD`      | `true` | GD compiled with jpeg/webp/freetype/xpm. |
| `PHP_EXT_IMAGICK` | `true` | PECL imagick + ImageMagick runtimes. |
| `PHP_EXT_VIPS`    | `true` | PECL vips + libvips runtimes. |


## JavaScript runtime installers (handled by mani-docker-install-js-runtime.sh)
| Arg                       | Default | Purpose / Notes                |
| ------------------------- | ------: | ------------------------------ |
| `JS_RUNTIME_REQUIRE_NODE` |  `true` | Install Node.js.               |
| `JS_RUNTIME_NODE_VERSION` |    `22` | Node major version to install. |
| `JS_RUNTIME_REQUIRE_DENO` | `false` | Install Deno if true.          |
| `JS_RUNTIME_REQUIRE_BUN`  | `false` | Install Bun if true.           |
| `JS_RUNTIME_REQUIRE_YARN` | `false` | Install Yarn if true.          |
| `JS_RUNTIME_REQUIRE_PNPM` | `false` | Install pnpm if true.          |


## Runtime environment variables (compose `environment:`)

| Var | Default | Meaning |
| --- | ---: | --- |
| `PUID` / `PGID` | `1000/1000` | Map container user/group `www-data` uid/gid to host user (perms for bind mounts/volumes permissions). |
| `XDEBUG_MODE` | `off` | `off`, `develop`, `debug`, etc. |
| `XDEBUG_CLIENT_HOST` | `host.docker.internal` | IDE host. Port 9003 by default (ini). |
| `XDEBUG_CLIENT_PORT`     |       `9003` *(implicit via ini)* | Only if you override; default is 9003. |

| App DB envs | *(yours)* | `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`. |
| Redis hints | *(yours)* | `REDIS_HOST`, `REDIS_PORT`. |
| Overlay controls | *(unset)* | `OVERLAY_DIR=/opt/overlay`, `EXTRA_APT_PACKAGES="jq yq"`. |


## Where to configure?
- **Features at build time**: set build args in your **docker compose** file once its generated or in existing one, so images are baked consistently.
- **Behavior at runtime**: set compose `environment:` values (e.g., `XDEBUG_MODE`).
- **Project-specific values in stubs**: use `$DOCKY_REPLACE_*` and let Docky resolve to concrete values for your project.


## Nginx + PHP-FPM image

Ports (in-container):
- Nginx listens on :80
- PHP-FPM listens on 127.0.0.1:9000 (wired in Nginx fastcgi_pass)
Runtime env used by the base:
- (none required) — Nginx and PHP-FPM are configured by files under /etc/nginx/ and /usr/local/etc/php-fpm.d/. You can override via overlay:
    - overlay/nginx/conf.d/*.conf
    - overlay/php/pool.d/*.conf
    - overlay/php/conf.d/*.ini


## FrankenPHP (Caddy) image

Ports (in-container):
- FrankenPHP/Caddy listens on :80 (HTTP only by default in dev)

Runtime env used by the base:
- (none required). Configuration via /etc/caddy/Caddyfile with overlay support:
    - overlay/frankenphp/Caddyfile → copied to /etc/caddy/Caddyfile.custom (your Caddyfile can import or replace).
    - overlay/frankenphp/snippets/* → copied under /etc/caddy/snippets.

> Standard Caddy envs (e.g., CADDY_ADMIN) can be used by you, but the base doesn’t set them.



## Swoole (OpenSwoole) image (not yet working properly, so won't use it)

Ports (in-container):
- Swoole HTTP server listens on :80 (configurable)

Runtime env consumed by `services.d/swoole/run` + `mani-swoole-server`:

| Env                        |                   Default | Purpose                                                                                                                       |
| -------------------------- | ------------------------: | ----------------------------------------------------------------------------------------------------------------------------- |
| `SWOOLE_HOST`              |                 `0.0.0.0` | Bind address for Swoole server.                                                                                               |
| `SWOOLE_PORT`              |                      `80` | Bind port.                                                                                                                    |
| `SWOOLE_DOCUMENT_ROOT`     |    `/var/www/html/public` | Docroot for static + front controller.                                                                                        |
| `SWOOLE_WORKER_NUM`        |                    `auto` | Worker count (`auto` ⇒ CPU count).                                                                                            |
| `SWOOLE_MAX_REQUESTS`      | `10000` (or your compose) | Max requests before worker recycle.                                                                                           |
| `SWOOLE_STATIC`            |                       `1` | Enable static file serving inside Swoole.                                                                                     |
| `SWOOLE_HTTP_COMPRESSION`  |                       `1` | Enable gzip/brotli compression if available.                                                                                  |
| `ENABLE_OCTANE`            |                   `false` | If `true` **and** `artisan` exists, runs `php artisan octane:start --server=swoole …` instead of the bare server.             |
| `OCTANE_ARGS`              |                 *(unset)* | Extra flags passed to Octane.                                                                                                 |
| `DISABLE_XDEBUG_IN_SWOOLE` |                       `1` | If set (and implemented in your init), disables Xdebug for coroutine safety (or set `XDEBUG_MODE=off`).                       |
| `SWOOLE_WATCH`             |                     `0/1` | Optional: if you add a watcher in overlay, you can key off this to hot-reload. (Base doesn’t implement a watcher by default.) |

> In Octane mode, the run script uses SWOOLE_WORKERS (Octane’s arg); set it if you want a fixed integer. Otherwise leave as auto.


## Extensibility (overlay hook)

These are the knobs used by `20-overlay.sh` cont-init:

| Env                  |        Default | Purpose                                                  |
| -------------------- | -------------: | -------------------------------------------------------- |
| `OVERLAY_DIR`        | `/opt/overlay` | Where the host project can mount customizations.         |
| `EXTRA_APT_PACKAGES` |      *(unset)* | Dev-time convenience to install extra packages on start. |


Overlay folder structure recognized:
- php/conf.d/*.ini → copied to /usr/local/etc/php/conf.d/
- php/pool.d/*.conf → /usr/local/etc/php-fpm.d/ (if FPM exists)
- nginx/conf.d/*.conf → /etc/nginx/conf.d/ (if Nginx exists)
- frankenphp/Caddyfile → /etc/caddy/Caddyfile.custom (if Caddy exists)
- frankenphp/snippets/* → /etc/caddy/snippets/
- services.d/<name>/{run,log/run,…} → overrides/adds s6 services
- cont-init.d/* → additional init scripts (executed after base init)
- apt/packages.txt → apt-get install (each line a package)
- certs/*.crt → trusted CA installed via update-ca-certificates
- remove/list → newline-separated relative paths under / to delete

## Healthchecks & utilities
Component	Details

| Component     | Details                                                                                                                                                                                                                                 |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `HEALTHCHECK` | Each image wires a healthcheck script (e.g., `healthcheck-nginx.sh`, `healthcheck-frankenphp.sh`, `healthcheck-swoole.sh`). They don’t require envs out of the box, but you can adapt them via overlay if you want to hit a custom URL. |
| `mani-sanity` | `/usr/local/bin/mani-sanity` prints system, services, PHP, Composer, JS runtimes, selected envs, PATH; great for quick diagnostics. No config needed.                                                                                   |
| History       | `/etc/profile.d/zz-history.sh` enables timestamped, persistent bash history across re-entries. No env required; works for the default user.                                                                                             |




- Ports (container):
    - Apache/Nginx/FrankenPHP/Swoole(Swoole not working properly yet): 80
    - PHP-FPM (Nginx flavor): 127.0.0.1:9000

- Xdebug (dev): set XDEBUG_MODE=develop,debug and XDEBUG_CLIENT_HOST=host.docker.internal (port 9003). Disable for Swoole/Octane (XDEBUG_MODE=off or DISABLE_XDEBUG_IN_SWOOLE=1).
> Overlay: mount ./xyz → /opt/overlay and set OVERLAY_DIR=/opt/overlay.