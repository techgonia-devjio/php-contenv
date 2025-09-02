# MANI PHP Stack

A modern, batteries-included PHP container stack with **multiple web servers** (Apache, Nginx+FPM, FrankenPHP, Swoole), **toggle-able extensions**, **Node runtimes**, **s6-managed services**, healthchecks, and developer niceties like a one-shot sanity tool and persistent shell history.

## Why this exists

- **Zero yak-shaving:** pick a server, hit `localhost:8081`, ship.
- **Repeatable builds:** split into **build** (compile/PECL) vs **runtime** (shared libs).
- **Feature flags:** turn PHP/DB/image extensions **on/off by args**, not by editing Dockerfiles.
- **Extensible at runtime:** drop files in an **overlay** and they’re applied on container boot.

> New to Docker? Start with **[Docker 101](docker-101.md)**, then **[Getting Started](getting-started.md)**.

## What you get

- PHP 8.2/8.3/8.4 images for **Apache / Nginx+FPM / FrankenPHP** (Swoole preview).
- Domain installers: core/db/image PHP extensions, JS runtimes (Node / pnpm / yarn; optional Deno/Bun).
- s6-overlay supervision with tidy service layout.
- Healthchecks + a portable `mani-sanity` diagnostic.

## Quick links

- **Run it:** [Getting Started](getting-started.md)
- **See how it’s built:** [Architecture](architecture.md)
- **All knobs:** [Config Reference](config-reference.md)
- **Docky commands:** [Docky CLI](docky-cli.md)
- **Extend at runtime:** [s6 & Services](s6-runtime.md)
