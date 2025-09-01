# Conventions (v2)

## Directory layout
- `php/<version>/<variant>/Dockerfile` — one Dockerfile per variant (apache, nginx, frankenphp, swoole).
- `common/build/scripts/*` — idempotent, parametric installers (`mani-php-ext-*.sh`, `mani-docker-install-*.sh`).
- `common/runtime/configs/<variant>/*` — shipped defaults; safe to be overridden by overlay.
- `common/runtime/s6/variants/<variant>/services.d/*` — s6 longruns; `type` file declares longrun.
- `common/runtime/sanity/mani-sanity.sh` — prints env metadata.
- `common/runtime/profile/zz-history.sh` — persistent history & timestamps.

## File naming
- PHP INIs: `90-*.ini` (project defaults), `92-*xdebug*.ini` (debug stuff), user overlays can use `95-*.ini`.
- s6: service dir name == process name (`nginx`, `php-fpm`, `frankenphp`, `swoole`, `queue-worker`).
- healthchecks: `healthcheck-<variant>.sh` returning 0/1 quickly.

## s6 patterns
- **No duplicate services**: each variant image copies **only** its own `services.d/*`.
- Each service has `run`, optional `finish`, `log/run`. All with LF line endings and `+x`.
- `cont-init.d/10-init.sh` handles UID/GID, perms, history; `20-overlay.sh` (if present) applies overlays.

## overlay contract (external extensibility)
Mount an overlay to `/opt/overlay` and the image will apply it at boot:
- /opt/overlay/
- php/conf.d/.ini -> /usr/local/etc/php/conf.d/
- php/pool.d/.conf -> /usr/local/etc/php-fpm.d/ (if FPM exists)
- nginx/conf.d/.conf -> /etc/nginx/conf.d/ (if Nginx exists)
- frankenphp/Caddyfile -> /etc/caddy/Caddyfile.custom
- frankenphp/snippets/ -> /etc/caddy/snippets/
- services.d/<name>/* -> /etc/services.d/<name>/ (override/add)
- cont-init.d/* -> /etc/cont-init.d/ (post base init)
- apt/packages.txt -> apt-get install each line
- certs/*.crt -> install trust & update-ca-certificates
- remove/list -> rm -rf each listed path


**Env knobs**
- `OVERLAY_DIR=/opt/overlay` (change mount point if needed)
- `EXTRA_APT_PACKAGES="tini jq yq"` (optional; dev-only)
- Use `95-*.ini` for your overrides to win order.

## ports & listeners (in-container)
- Apache/Nginx/FrankenPHP/Swoole: `:80`
- PHP-FPM (Nginx flavor): `127.0.0.1:9000`

## Xdebug
- Default installed in dev images; enable via `XDEBUG_MODE=develop,debug`.
- For Swoole/Octane: **disable** (`XDEBUG_MODE=off`) to avoid coroutine issues.

## semantics
- Build args `PHP_EXT_*` gate installers; runtime leaves loaded modules on unless you drop their INIs via overlay.
- Healthchecks should hit `/` and time out fast (<5s).

