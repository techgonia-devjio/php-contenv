Each profile ships a small curl-based healthcheck (30s interval, 5s timeout).

- Apache: `common/runtime/healthchecks/healthcheck-apache.sh` (enabled by default)
- Nginx: `common/runtime/healthchecks/healthcheck-nginx.sh` (**disabled by default**; enable with `ENABLE_HEALTHCHECK=true`)
- FrankenPHP: `common/runtime/healthchecks/healthcheck-frankenphp.sh` (enabled by default)