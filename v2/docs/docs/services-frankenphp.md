# FrankenPHP Profile

- Base: `dunglas/frankenphp:1-php8.4-bookworm` (Caddy inside)
- Config: `common/runtime/configs/frankenphp/Caddyfile`
- Serves PHP directly (no FPM), HTTP/1 with optional h2/h3 when TLS enabled.

**Run**
```bash
docker compose -f docker-compose.profiles.yml --profile frankenphp up --build
````

**Notes**

* You’ll see warnings about TLS when binding to `:80` — normal for local dev.
* Set `HOME=/root` (Compose already does) to silence Caddy `$HOME` warning.
* Access logs via `/var/log/php` (and optionally configure Caddy’s logging if desired).

**Why FrankenPHP?**

* Zero FPM hop, great performance, first-class worker mode options for modern PHP apps.
