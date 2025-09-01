# Architecture

## Top-level layout (v2)
````

common/
build/scripts/           # domain installers + helpers
runtime/configs/         # apache|nginx|frankenphp|php configs
runtime/healthchecks/    # curl-based health scripts
runtime/s6/              # s6 init + services
php/
8.4/<server>/Dockerfile  # multi-stage per server
docker-compose.profiles.yml

```

## Multi-stage Dockerfiles
Stages:
- **base**: upstream `php:*` (apache|fpm|frankenphp base), core system deps
- **build_tools**: compiles extensions, PECL, Node runtimes
- **final_base**: s6 overlay, configs, healthchecks, *runtime* shared libs
- **development**/**production**: last-mile image variants

Why split build vs runtime?
- Build uses `-dev` headers & compilers (bigger layers, slower). We keep them *out* of the final image.
- Runtime only installs shared libraries needed by enabled extensions. Smaller, cleaner.

## Domain installers
- `mani-php-ext-core.sh` – intl, soap, zip, xsl, gmp, bcmath, exif, pcntl, xdebug (install only)
- `mani-php-ext-db.sh` – pdo_mysql, pdo_pgsql, sqlite/pdo_sqlite, redis, memcached, mongodb, and DB clients
- `mani-php-ext-images.sh` – gd (compiled), imagick (pecl), vips (pecl)
- Modes: `--build` (headers & compile) and `--runtime` (shared libs only)

## Process supervision (s6)
- Init scripts in `/etc/cont-init.d/*.sh`
- Long-running services in `/etc/services.d/<name>/run`
- Each profile ships the right services (e.g., `apache` OR `nginx`+`php-fpm`, etc.)

## Healthchecks
- Ping `http://127.0.0.1/` from inside the container with a small timeout, fail the container if unhealthy.
```

---

### `docs/configuration.md` (all variables)

```md
# Configuration (Build Args & Env)

All knobs can be set as Docker **build args** (at build time) or docker-compose **environment** (runtime). Defaults shown in **bold**.

> Tip: See `docker-compose.profiles.yml` anchors `x-build-args` and `x-env` for canonical defaults.

## Build-time: JS runtimes
| Arg | Default | Meaning |
|---|---|---|
| `JS_RUNTIME_REQUIRE_NODE` | **true** | Install Node via NVM (symlinked to `/usr/local/bin`). |
| `JS_RUNTIME_NODE_VERSION` | **22** | Node version (e.g., `lts`, `22`, `20.13.1`). |
| `JS_RUNTIME_REQUIRE_DENO` | **false** | Install Deno. |
| `JS_RUNTIME_REQUIRE_BUN`  | **false** | Install Bun. |
| `JS_RUNTIME_REQUIRE_YARN` | **false** | `npm i -g yarn` if Node installed. |
| `JS_RUNTIME_REQUIRE_PNPM` | **false** | Enable pnpm via Corepack or `npm -g`. |

## Build-time: DB clients & extensions
| Arg | Default | Notes |
|---|---|---|
| `INSTALL_DB_MYSQL_CLIENT` | **true** | Installs `default-mysql-client`. |
| `INSTALL_DB_PGSQL_CLIENT` | **false** | Adds PGDG repo + `postgresql-client-<ver>`. |
| `DB_PGSQL_CLIENT_VERSION` | **18** | Choose client major version. |
| `PHP_EXT_PDO_MYSQL` | **true** | Compiles `pdo_mysql`. |
| `PHP_EXT_PDO_PGSQL` | **false** | Compiles `pdo_pgsql` (needs `libpq-dev`). |
| `PHP_EXT_SQLITE` | **false** | Compiles `sqlite3`. |
| `PHP_EXT_PDO_SQLITE` | **false** | Compiles `pdo_sqlite`. |
| `PHP_EXT_REDIS` | **false** | Installs PECL `redis`. |
| `PHP_EXT_MEMCACHED` | **false** | Installs PECL `memcached`. |
| `PHP_EXT_MONGODB` | **false** | Installs PECL `mongodb`. |

## Build-time: Image/graphics
| Arg | Default | Notes |
|---|---|---|
| `PHP_EXT_GD` | **true** | Builds GD with jpeg/webp/freetype. |
| `PHP_EXT_IMAGICK` | **true** | PECL `imagick`; pulls ImageMagick runtimes. |
| `PHP_EXT_VIPS` | **true** | PECL `vips`; pulls libvips runtimes. |

## Build-time: Core PHP extensions
| Arg | Default |
|---|---|
| `PHP_EXT_INTL` | **true** |
| `PHP_EXT_SOAP` | **false** |
| `PHP_EXT_ZIP`  | **true** |
| `PHP_EXT_XSL`  | **false** |
| `PHP_EXT_GMP`  | **false** |
| `PHP_EXT_BCMATH` | **false** |
| `PHP_EXT_EXIF`   | **false** |
| `PHP_EXT_PCNTL`  | **false** |
| `PHP_EXT_XDEBUG` | **true** *(installed, but controlled at runtime)* |

## Runtime environment
| Var | Default | Meaning |
|---|---|---|
| `PUID` / `PGID` | **1000/1000** | Map `www-data` to host user/group for file perms. |
| `XDEBUG_MODE` | **off** | `off`, `develop`, `debug`, etc. |
| `XDEBUG_CLIENT_HOST` | **host.docker.internal** | Your IDE host. |
| `DB_HOST`/`DB_PORT`/`DB_DATABASE`/`DB_USERNAME`/`DB_PASSWORD` | various | App DB connection. |
| `REDIS_HOST`/`REDIS_PORT` | `redis` / `6379` | Redis connection hints. |
| `ENABLE_QUEUE_WORKER` | **false** | Apache profile only: enable `queue-worker` service if your app has `artisan`. |

## PHP config
- System php.ini lives in `common/runtime/configs/php/`
  - `90-docker-custom.ini` : dev-friendly defaults (display errors on, opcache, memory limits)
  - `92-docker-php-ext-xdebug.ini` : Xdebug 3 settings (start with request, port 9003)
```

---