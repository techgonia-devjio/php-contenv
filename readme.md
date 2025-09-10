# php-contenv v2

`php-contenv` provides pre-configured Docker environments tailored for PHP development, particularly for framework Laravel. The goal is to offer a simple, consistent, and ready-to-go development environment that can be easily integrated into any project without requiring local installations of PHP, Composer, or Node.js. It comes with batteries-included PHP runtime (8.1–8.4) with Nginx/Apache/FrankenPHP, s6-overlay, and a tiny helper (`docky`) to assemble a `docker-compose.yml` from stubs.

Just Recommendation: use this package as a Git submodule in your app repo. That keeps the Docker setup separate and easy to update across projects.

By using `php-contenv` as a Git submodule, you can keep your project's Docker configuration separate and easily update it across multiple projects.



## Purpose

The primary purpose of `php-contenv` is to:

- Dockerfiles & configs for multiple PHP versions and servers (Apache, Nginx, FrankenPHP — coming soon).
- Common dev tools/extensions (Composer, Node.js, Xdebug, image libs, DB clients) enabled via build args/env.
- Live code/config via bind mounts (no rebuild for typical edits).
- Simple setup that feels production-ish locally.
- Handy for JS runtime tasks inside the container so the host stays clean.


## Requirements
- Docker + **Docker Compose** (`docker compose …`)
- Optional for `docky`: **yq v4**

## Use in your project

1.  **Add as a Git Submodule:**
```bash
git submodule add https://github.com/techgonia-devjio/php-contenv .docker
git submodule update --init --recursive

# If you don’t want submodules, copy the v2 folder from repo:
#   cp -a v2 YOUR_APP/.docker/v2 or add as submodule then cut the link or remove ´rm -rf .docker/.git´ and also in your root project if exists .gitmodules or .gitsubmodules remove the ref also from there.
```


### 2) Minimal compose (manual)

Create `docker-compose.yml` in your app repo:

```yaml
services:
  app:
    container_name: my-app
    build:
      context: .docker/v2
      dockerfile: php/8.4/nginx/Dockerfile
      # target: development/production
    ports:
      - "${APP_PORT:-8081}:80"
    volumes:
      - .:/var/www/html
    networks:
      - optimesh

networks:
  optimesh:
    driver: bridge
```

> Compose auto-loads `.env`, so `APP_PORT` can live there (a default is provided in the example).

### 3) Or generate compose with **docky** (optional)

```bash
./.docker/v2/docky gen            # writes ./docker-compose.yml from stubs
./.docker/v2/docky list-svc       # see available/enabled service stubs
./.docker/v2/docky add-svc mysql  # enable a service and re-generate compose
```

### 4.) Running container
- **Run the Setup Script:**
  Navigate to your project's root directory and run the setup script if you want to generate docker compose file:
    - **Linux/macOS:** (might require some permission chmod +x ./.docker/v2/docky)
        ```bash
        bash ./.docker/docky gen
        ```
    * **Windows:**
      Use git bash or similar tool which can run bash script(or WSL).
      The script will guide you through selecting your desired PHP version and web server, set up the necessary `docker-compose.yml`.

- **Start the Environment:**
  Once the setup is complete, start your Docker environment:
    ```bash
    docker compose up
    ```
-  **Access Your Application:**
   Your application should now be accessible via the port configured in your `.env` file (defaulting to 8081 if using the example `docker-compose.yml`)

- **Running Artisan Commands:**
    ```bash
    docker exec laravel.app php artisan <command>
    ```

- **Running Composer Commands:**
    ```bash
    docker exec laravel.app composer <command>
    ```

- **Or just Bash it:**
    ```bash
    docker exec laravel.app bash
    ```

If the app name couldn't be found, you can run `docker container ls` and copy the container id or name and run `docker exec -it container_name_or_id bash`.


## Advanced: extend without touching the submodule
You can keep project-specific tweaks in a folder like `.docker-snippets/` and mount them via `volumes`:

**Add custom PHP INI**

```yaml
# docker-compose.yml file
services:
  app:
    volumes:
      - ./.docker-snippets/php/custom.ini:/usr/local/etc/php/conf.d/99-custom.ini:ro
```

**Add s6 services via overlays**

```
.docker-snippets/
└─ overlays/
   └─ hello-svc/
      └─ services.d/hello/{run,type,log/run}
```

Mount and activate:

```yaml
services:
  app:
    volumes:
      - ./.docker-snippets/overlays:/opt/overlay:ro
    environment:
      OVERLAY_DIR: /opt/overlay
```

**Override server configs**

```yaml
services:
  app:
    volumes:
      - ./.docker-snippets/configs/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```

--

## Running some basic tests

From the **repo root**:

```bash
make -C v2/tests               # builds images (nginx/apache/frankenphp) and runs runtime checks
make -C v2/tests runtime-nginx # quick single run
make -C v2/tests docky         # smoke-test the docky CLI
```

What the tests cover:

* Build matrix for 8.4 (and easily extendable) across Nginx/Apache/FrankenPHP
* Runtime probes: HTTP 200, server process, required PHP extensions, Xdebug present but disabled by default
* Overlay boot (example longrun service) + mounted PHP INI override works

## docs
`bash .docker/v2/docky open-doc`

## Troubleshooting

* **`yq` errors**: ensure v4 (`yq --version`).
* **`docker compose` vs `docker-compose`**: this project expects the v2 syntax (`docker compose`).


## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

This project is open-source software licensed under the [MIT License](../LICENSE).
