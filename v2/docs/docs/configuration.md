### (all variables)

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