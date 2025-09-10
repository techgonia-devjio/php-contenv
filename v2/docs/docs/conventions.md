# Conventions

## Paths
- `php/<version>/<variant>/Dockerfile` — one per server (apache, nginx, frankenphp).
- `common/build/scripts/*` — idempotent, parametric installers.
- `common/runtime/configs/<variant>/*` — shipped defaults (override via overlay).
- `common/runtime/s6/variants/<variant>/services.d/*` — s6 longruns; include `type`.
- `stubs/services/*.yml` — compose fragments (can use `$DOCKY_REPLACEABLE_*`).

## Naming
- PHP INIs: `90-*.ini` project defaults, `92-*-xdebug*.ini` for debug.
- Healthchecks: `healthcheck-<variant>.sh` returning 0/1 quickly.

## Overlays contract
- `/opt/overlay/php/conf.d/*.ini` → `/usr/local/etc/php/conf.d/`
- `/opt/overlay/php/pool.d/*.conf` → `/usr/local/etc/php-fpm.d/`
- `/opt/overlay/nginx/conf.d/*.conf` → `/etc/nginx/conf.d/`
- `/opt/overlay/frankenphp/Caddyfile` → `/etc/caddy/Caddyfile.custom`
- `/opt/overlay/frankenphp/snippets/*` → `/etc/caddy/snippets`
- `/opt/overlay/services.d/<name>/*` → `/etc/services.d/<name>/`
- `/opt/overlay/cont-init.d/*` → run after base init
- `/opt/overlay/apt/packages.txt` → apt-get install each line
- `/opt/overlay/certs/*.crt` → trusted CAs
- `/opt/overlay/remove/list` → delete listed paths under `/`

**Env knobs**

- `OVERLAY_DIR=/opt/overlay`
- `EXTRA_APT_PACKAGES="jq yq curl"`


## s6 patterns
- **No duplicate services**: each variant image copies **only** its own `services.d/*`.
- Each service has `run`, optional `finish`, `log/run`. All with LF line endings and `+x`.
- `cont-init.d/10-init.sh` handles UID/GID, perms, history; `20-overlay.sh` (if present) applies overlays.

**Env knobs**
- `OVERLAY_DIR=/opt/overlay` (change mount point if needed)
- `EXTRA_APT_PACKAGES="tini jq yq"` (optional; dev-only)
- Use `95-*.ini` for your overrides to win order.

## ports & listeners (in-container)
- Apache/Nginx/FrankenPHP: `:80`
- PHP-FPM (Nginx flavor): `127.0.0.1:9000`

## Xdebug
- Default installed in dev images; enable via `XDEBUG_MODE=develop,debug`.
- For Swoole/Octane: **disable** (`XDEBUG_MODE=off`) to avoid coroutine issues.

## semantics
- Build args `PHP_EXT_*` gate installers; runtime leaves loaded modules on unless you drop their INIs via overlay.
- Healthchecks should hit `/` and time out fast (<5s).

