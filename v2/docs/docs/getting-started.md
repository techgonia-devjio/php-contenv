# Getting Started

## Prereqs
- Docker Desktop (or Engine) 20+ recommended
- Git
- Optional for viewing docs locally: `pip install mkdocs mkdocs-material`
- Optional for using docky or generating docker-compose.yml file: `yq` and `gettext`

## 1) Clone & env
```bash
git submodule add https://github.com/techgonia-devjio/php-contenv .docker
git submodule update --init --recursive
```

This will add the submodule in your project and will be easy to update with new changes without breaking the docker env.

## 2) Generate compose
```bash
# interactively resolve placeholders (first time)
./.docker/v2/docky gen

# or, skip prompts and take defaults/saved answers
./.docker/v2/docky gen --no-ask
```

What happens:
- Docky merges the selected stubs into an in-memory YAML.
- It detects $DOCKY_REPLACEABLE_* tokens and asks for values.
- Answers are saved to .docker-snippets/.docky-cache in your project. You can delete or add it to the gitignore if really don't want in project
- Writes docker-compose.yml at the project root.
> You can pre-seed .docker-snippets/.docky-cache, or set values via ./.docker/v2/docky config set KEY value


## 3) Start the stack
`./.docker/v2/docky up` or `docker compose up`

### first run will build images; add -d to detach
Open: `http://localhost:8081`

## 4) Verify the container

```bash
./.docker/v2/docky exec app bash
mani-sanity
```
You’ll see OS, PHP version, loaded extensions, Node, and services.

## 5) Typical dev loop
Edit files on your host editor (the project is bind-mounted).
- Edit code locally (bind-mounted at /var/www/html).
- Logs:
  - Apache → /var/log/apache2
  - Nginx → /var/log/nginx
  - PHP → /var/log/php
  - FrankenPHP → /var/log/frankenphp

Tail logs:
`./.docker/v2/docky logs -f app`

Toggle Xdebug:
- Off (faster by default): `XDEBUG_MODE=off`
- On for stepping: `XDEBUG_MODE=debug|develop` and restart


## 6) Docs (optional)
`./.docker/v2/docky open-docs   # serves docs on http://127.0.0.1:5105`

If you prefer manual:
- `cd ./.docker/v2/docs`
- `mkdocs serve -a 127.0.0.1:5105`

### FAQ snippets
- Port busy? Change app port mapping in .env APP_PORT as needed, or directly in the docker compose file.
- Permissions? Set PUID/PGID to your host uid/gid (defaults 1000/1000).
- Switch servers? Change answers for DOCKY_REPLACEABLE_PHP_SERVER (apache|nginx|frankenphp), run gen, then up -d.



