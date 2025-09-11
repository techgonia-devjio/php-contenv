# FrankenPHP Profile

- Base: `dunglas/frankenphp:1-php8.4-bookworm` (Caddy inside)
- Config: `common/runtime/configs/frankenphp/Caddyfile`
- Serves PHP directly (no FPM hop), HTTP/1 on `:80` with optional h2/h3 when TLS enabled.

**Run**
```bash
./.docker/v2/docky gen
./.docker/v2/docky up -d
```

## Notes
- You might see TLS/home warnings in local HTTP; harmless.
- You’ll see warnings about TLS when binding to `:80` — normal for local dev.
- Set `HOME=/root` (Compose already does) to silence Caddy `$HOME` warning.
- Access logs via `/var/log/php` (and optionally configure Caddy’s logging if desired).

## Why FrankenPHP?
- Fewer moving parts, excellent performance, worker mode options for modern PHP.

