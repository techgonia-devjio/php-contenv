# Docky CLI

Docky is a thin helper that **merges stubs** and resolves **placeholders** into a ready-to-run `docker-compose.yml`.


## Key ideas
- The submodule ships a **read-only** `docky.yml` with defaults (`vars`) and choice lists (`OPTIONS`).
- Stubs can include **`$DOCKY_REPLACE_*`** tokens anywhere (e.g., paths, ports).
- On `gen`, Docky asks for values, saves them to **`.docky.answers.yml`** at the **project** root, then writes `docker-compose.yml`.

> Run `./.docker/v2/docky help` anytime.

### Placeholder lifecycle

1. Collect tokens like `$DOCKY_REPLACE_PHP_VERSION` or `${DOCKY_REPLACE_PHP_SERVER}`.
2. Resolve value from, in order:
   - `.docky.answers.yml` (project, if present)
   - environment variable named like the **base** (e.g., `PHP_VERSION`) *(optional convenience)*
   - submodule defaults in `docky.yml: vars`
   - submodule choices in `docky.yml: OPTIONS`
   - **interactive prompt** (unless `--no-ask`)
3. Persist to `.docky.answers.yml`.
4. Replace tokens in the merged YAML.

> **Important:** This replacement happens **before** compose is written. We do **not** rely on Docker’s env interpolation for Dockerfile paths.

## Commands

```bash
./.docker/v2/docky doctor
./.docker/v2/docky gen [--no-ask] [--envsubst]
./.docker/v2/docky list-svc
./.docker/v2/docky add-svc <name>
./.docker/v2/docky snippet php-ini <name>
./.docker/v2/docky snippet list
./.docker/v2/docky config show|set|reset
./.docker/v2/docky open-docs
# docker compose passthrough:
./.docker/v2/docky up|down|ps|logs|exec|build|restart|pull
```

### `gen` flags
- `--no-ask`: never prompt; uses .docky.answers.yml → defaults → first option.
- `--envsubst`: after replacement, also run envsubst on the final YAML while keeping unknowns intact. This is optional and not needed for Dockerfile paths.
### .docky.answers.yml
- Created in your project root on first gen.
- Safe to commit if you want teammates to share the same stack; or keep it local and document your preferred answers.

```env
DOCKY_REPLACE_PHP_VERSION: "8.4"
DOCKY_REPLACE_PHP_SERVER: "nginx"
DOCKY_REPLACE_PHP_TARGET: "development"
APP_PORT: "8081"
```


### `docky add-svc <name>`
Adds a stub from `stubs/services/<name>.yml` to `docky.yml` and regenerates compose.

### `docky list-svc`
Shows available stubs, stubs enabled in `docky.yml`, and services present in the generated compose.

### `docky snippet php-ini <name>`
Creates `.docker-snippets/php/<name>.ini` and mounts it automatically. Great for per-project PHP tweaks.

### `docky snippet list`
Lists available project snippets that will be mounted.

### `docky open-docs`
Opens `docs/index.html` if built, otherwise `README.md`. Handy for local doc browsing.

### Compose passthrough
`up | down | ps | logs | exec | run | restart | build | pull` are proxied to `docker compose`.

## Example flows

- **Add Typesense**:
  ```bash
  ./docky add-svc mysql
  ./docky up -d


### Snippets & Overlays

- **Snippets** (project): .docker-snippets/php/*.ini → auto-mounted to /usr/local/etc/php/conf.d/
    - Create via: ./.docker/v2/docky snippet php-ini myapp
- Overlays (from submodule by default): if docky.yml: overlays non-empty, they mount to /opt/overlay:ro and are applied by cont-init.d/20-overlay.sh:
    - php/conf.d/*.ini, php/pool.d/*.conf
    - nginx/conf.d/*.conf
    - frankenphp/Caddyfile and frankenphp/snippets/*
    - services.d/<name>/
    - cont-init.d/*, apt/packages.txt, certs/*.crt, remove/list
