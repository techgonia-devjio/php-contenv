# MANI PHP Stack

A modern, batteries-included PHP container stack with **multiple web servers** (Apache, Nginx+FPM, FrankenPHP, Swoole), **toggle-able extensions**, **Node runtimes**, **s6-managed services**, **healthchecks**, and **developer niceties** like a one-shot sanity tool and shell history quality-of-life.

**Goals**

- **1st-class DX**: run `docker compose up`, code in your editor, hit `localhost:8081`.
- **Predictable builds**: multi-stage Dockerfiles split into “build” (compile/PECL) and “runtime” (shared libs), with stable caching.
- **Switch servers** instantly: enable one profile: `apache`, `nginx`, `frankenphp`, or `swoole`.
- **Feature flags**: enable PHP extensions and DB clients with build args; no custom Dockerfile hacking.
- **Sane defaults**: Xdebug (off by default at runtime), Opcache, intl, image stacks (GD/Imagick/Vips), composer, Node (optional).
- **Multi-arch**: s6 overlay works on x86_64/arm64.

> TL;DR: Choose your server profile. Turn on only what you need. Repeatable builds. Nice logs. Minimal yak-shaving.

