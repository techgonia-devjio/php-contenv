# s6 Overlay & Services

## Init

- `cont-init.d/10-init.sh`
  - Map `www-data` uid/gid to `PUID/PGID`
  - Fix perms for Laravel-typical dirs
  - Persistent history wiring

- `cont-init.d/20-overlay.sh`
  - Applies overlay rules (copy configs, services, packages, certs)
  - Safe and idempotent; logs its actions

## Services

- Apache: `/etc/services.d/apache/run`
- Nginx: `/etc/services.d/nginx/run` and `/etc/services.d/php-fpm/run`
- FrankenPHP: `/etc/services.d/frankenphp/run`
- Optional: your own services via overlay `services.d/<name>/run`

## Why s6?

- Deterministic supervision, fast, small for multi process containers
- Clean shutdown hooks; logs managed by `s6-log` if you enable per-service log dirs.
