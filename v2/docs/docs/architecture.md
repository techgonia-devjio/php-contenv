# Architecture


## Layout (submodule)

## Top-level layout (v2)
```md
- common/
  - build/scripts/ # domain installers (core, db, imaging) + helpers
  - runtime/configs/ # php + server configs
  - runtime/healthchecks/ # lightweight curl checks
  - runtime/s6/ # init + services by variant
- php/
  - 8.4/<server>/Dockerfile # multi-stage per server
- stubs/
  - services/.yml # compose fragments (may contain $DOCKY_REPLACE_)
- docky.yml # defaults + OPTIONS (read-only in submodule)
- docky # CLI entrypoint
- docs/ # mkdocs site
```

## Multi-stage Dockerfiles
Stages:
- **base**: upstream `php:*` (apache|fpm|frankenphp base), core system deps
- **build_tools**: compiles extensions, PECL, Node runtimes
- **final_base**: s6 overlay, configs, healthchecks, *runtime* shared libs
- **development**/**production**: last-mile image variants

**Why split build/runtime?**

- Keep final layers small and free of dev headers/compilers.
- Faster rebuilds when toggling features.

## Domain installers

- `mani-php-ext-core.sh`: intl, zip, soap, xsl, gmp, bcmath, exif, pcntl, xdebug (install only).
- `mani-php-ext-db.sh`: pdo_mysql, pdo_pgsql, sqlite/pdo_sqlite, redis, memcached, mongodb + DB clients.
- `mani-php-ext-images.sh`: gd (compiled), imagick (pecl), vips (pecl).
- Each supports `--build` (compile/headers) and `--runtime` (shared libs only).

## s6 overlay

- `cont-init.d/10-init.sh`: maps PUID/PGID, fixes perms, history.
- `cont-init.d/20-overlay.sh`: applies overlay rules.
- services: `/etc/services.d/<name>/run` (e.g., `nginx`, `php-fpm`, `apache`, `frankenphp`).

## Healthchecks

- Simple, fast `curl -fsS http://127.0.0.1:80/` with short timeout.
- Goal: catch obvious boot regressions; not a full probe.


