# Getting Started

## Prereqs
- Docker Desktop (or Engine) 20+ recommended
- Git
- Optional: Python 3 for docs (`pip install mkdocs mkdocs-material`)

## 1) Clone & env
```bash
git clone <your-repo> mani
cd mani
cp .env.example .env   # if you keep one; otherwise set env via compose
````

## 2) Pick a profile and run

**Apache**

```bash
docker compose -f docker-compose.profiles.yml --profile apache up --build
```

**Nginx (FPM)**

```bash
docker compose -f docker-compose.profiles.yml --profile nginx up --build
```

**FrankenPHP (Caddy)**

```bash
docker compose -f docker-compose.profiles.yml --profile frankenphp up --build
```

**Swoole**

```bash
docker compose -f docker-compose.profiles.yml --profile swoole up --build
```

Open: [http://localhost:8081](http://localhost:8081)

## 3) Verify

```bash
docker exec -it <container> bash
mani-sanity
```

You’ll see OS, PHP/extensions, Node, services, etc.

## 4) Common dev loop

* Code locally (mounted at `/var/www/html`).
* Logs:

  * Apache: `/var/log/apache2` (apache profile)
  * Nginx: `/var/log/nginx` (nginx profile)
  * PHP: `/var/log/php`
  * FrankenPHP: `/var/log/frankenphp` (if configured)
* Xdebug: default **installed**, **off** at runtime. Turn on with `XDEBUG_MODE=debug` in compose env (see [Configuration](configuration.md)).

