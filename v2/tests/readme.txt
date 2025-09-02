here’s a tiny, no-frills README you can drop at `v2/tests/README.md` (plain text is fine too).

---

# php-contenv v2 — tests

## What these tests do

* **Build** your PHP images (default: PHP 8.4 for `nginx`, `apache`, `frankenphp`) with common build args enabled.
* **Run** each image and probe it:

  * HTTP responds `200 /`
  * Server process is running (nginx/apache/frankenphp)
  * Expected PHP extensions are loaded (intl, zip, gd, imagick, vips, pdo\_mysql, pdo\_pgsql)
  * Xdebug is **present** but effectively **off**
  * A mounted `99-test.ini` overrides `memory_limit` to `384M`
  * A sample **overlay service** writes `/tmp/hello.probe`
  * Node & npm available when requested
* **Docky smoke test:** generate a compose file and add a stub service in a temp project.

> Build context auto-detect:
>
> * If a consumer project has `./.docker/v2/` → use that.
> * Otherwise (inside this repo) → use the package’s `v2/` directory.
>   No symlink needed.

## Requirements

* Docker (Desktop or Engine)
* Bash, curl
* (Optional) **yq v4** — only needed for the docky smoke test
* (Optional) **dgoss/goss** — if you want to run the goss example

## How to run

From **any** directory:

```bash
make -C v2/tests
```

or inside the folder:

```bash
cd v2/tests
make
```

That runs the default **matrix** (nginx, apache, frankenphp on PHP 8.4).

### Useful targets

* Full matrix (default):

  ```bash
  make -C v2/tests matrix
  ```
* Single quick run (nginx example):

  ```bash
  make -C v2/tests runtime-nginx
  ```
* Docky smoke test (compose generation + add-svc):

  ```bash
  make -C v2/tests docky
  ```
* Goss example (if you have `dgoss`):

  ```bash
  make -C v2/tests goss
  ```
* Cleanup any leftover test containers/images:

  ```bash
  make -C v2/tests clean
  ```

## Configuration knobs

* Change base port for HTTP checks (defaults to `9300`):

  ```bash
  make -C v2/tests PORT_BASE=9500
  ```
* Select a different build target (e.g. `production` if your Dockerfiles define it):

  ```bash
  make -C v2/tests TARGET=production
  ```
* Limit which pairs to test (format: `<DockerfileRelPath> <server>`):

  ```bash
  make -C v2/tests \
    PAIRS="php/8.4/nginx/Dockerfile nginx php/8.4/apache/Dockerfile apache"
  ```

## What gets mounted during runtime tests

* App code: the package `v2/` directory → `/var/www/html`
* PHP ini override: `tests/fixtures/php/99-test.ini` → `/usr/local/etc/php/conf.d/99-test.ini:ro`
* Overlay example: `tests/fixtures/overlays/hello-svc` → `/opt/overlay/hello-svc:ro`
* `OVERLAY_DIRS=/opt/overlay` is set so the init script loads overlays.

## Troubleshooting

* **“path .docker/v2 not found”**
  You’re running inside the package repo and the script couldn’t find a consumer `.docker/v2`. The tests will fall back to `v2/` automatically (with the provided scripts). Make sure you updated the test scripts as in repo.
* **Port already in use**
  Change `PORT_BASE` or stop whatever is using the port.
* **Slow startup**
  Docker Desktop may need more CPU/RAM. Give it a few seconds; the test waits up to 60s for HTTP.
* **xdebug appears on**
  Ensure `XDEBUG_MODE=off` is respected; the test will fail if it isn’t.

That’s it—`make -C v2/tests` should give you green ✅ when everything’s wired correctly.
