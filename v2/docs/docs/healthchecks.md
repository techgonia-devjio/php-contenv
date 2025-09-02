# Healthchecks

Each profile ships a simple **curl** healthcheck (30s interval, 5s timeout) against `127.0.0.1:80`.

- Apache: `common/runtime/healthchecks/healthcheck-apache.sh`
- Nginx: `common/runtime/healthchecks/healthcheck-nginx.sh`
- FrankenPHP: `common/runtime/healthchecks/healthcheck-frankenphp.sh`

**Why?** Orchestrators restart unhealthy containers. Locally, it’s a quick smoke test.

