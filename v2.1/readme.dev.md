# Developer Guide — php-contenv v2

This guide is for maintainers and contributors to **php-contenv v2**. The main `readme.md` is end-user facing; this explains how v2 is organized, how `docky` works internally, and how to test, extend, and release changes.

## 1) Core principles

1. **Simplicity** – end users can copy a minimal compose or run `docky gen` or see the v2/examples.
2. **Consistency** – same shape across PHP versions and servers. Its redundant to repeat dockerfiles with different version but sometimes its easy to maintain or for future upgrade
3. **Speed** – fast rebuilds; common layers are shared; no host installs required.
4. **Flexibility** – sensible defaults, but easy to extend (overlays, snippets, extra services).

---

## 2) Repository layout (v2)

```
v2/
├── common/
│   ├── build/scripts/                 # build-time helpers
│   │   ├── mani-docker-install-js-runtime.sh
│   │   ├── mani-docker-install-system-deps.sh
│   │   ├── mani-php-ext-core.sh
│   │   ├── mani-php-ext-db.sh
│   │   └── mani-php-ext-images.sh
│   └── runtime/                       # runtime bits included in final images
│       ├── configs/                   # nginx/apache/php configs
│       ├── healthchecks/              # healthcheck scripts
│       ├── profile/zz-history.sh
│       ├── s6/                        # s6-overlay: cont-init.d / services.d variants
│       └── sanity/mani-sanity.sh
├── php/
│   ├── 8.1/{nginx,apache,frankenphp}/Dockerfile
│   ├── 8.2/{nginx,apache,frankenphp}/Dockerfile
│   ├── 8.3/{nginx,apache,frankenphp}/Dockerfile
│   └── 8.4/{nginx,apache,frankenphp}/Dockerfile
├── overlays/                          # built-in example overlays (can be enabled via compose)
│   ├── locales/cont-init.d/10-locales.sh
│   └── queue-worker/services.d/queue-worker/{run,type,log/run}
├── stubs/services/                    # compose stubs used by docky
│   ├── app.yml
│   ├── mysql.yml
│   ├── to add more stubs yet, such as postgresql,redis,mailpit,keyclock etc which will be the docker services 
│   └── typesense.yml
├── docs/                              # docs can be run via mkdocs
├── public/                            # tiny probe app for HTTP 200 in tests
├── scripts/                           # maintainer utilities (lint/smoke etc.)
│   ├── ci-matrix.sh
│   ├── lint-dockerfiles.sh
│   ├── lint-shell.sh
│   ├── smoke.sh
│   └── validate-s6.sh
├── tests/                             # local test harness (no CI required)
│   ├── Makefile
│   ├── fixtures/ (overlay + php ini)
│   ├── scripts/{test-matrix.sh,test-runtime.sh}
│   └── test-docky.sh
├── docky                              # v2 docky (yq v4; merges stubs)
├── docky.yml                          # internal defaults for docky (devs only)
├── docker-compose.test.yml            # internal/testing compose
└── readme.md                          # user docs (how to consume)
```

**Key ideas**

* **common/** holds everything shared by all images.
* **php/** contains the server variants per PHP version.
* **overlays/** are optional runtime additions (applied by `cont-init.d/20-overlay.sh` when mounted).
* **stubs/services/** are YAML slices assembled by `docky gen`.

---

## 3) Images & build args (what you can toggle)

Dockerfiles accept build args to include features without editing Dockerfiles:

-  DB clients: `INSTALL_DB_MYSQL_CLIENT=true`, `INSTALL_DB_PGSQL_CLIENT=true`, `DB_PGSQL_CLIENT_VERSION=17`
- PHP extensions (compiled/installed as needed):
  * `PHP_EXT_PDO_MYSQL=true`, `PHP_EXT_PDO_PGSQL=true`
  * `PHP_EXT_INTL=true`, `PHP_EXT_ZIP=true`, `PHP_EXT_GD=true`
  * `PHP_EXT_IMAGICK=true`, `PHP_EXT_VIPS=true`
  * `PHP_EXT_XDEBUG=true` *(present but off by default at runtime)*
- JS runtime:
  * `JS_RUNTIME_REQUIRE_NODE=true`, `JS_RUNTIME_NODE_VERSION=22`
  * you can install deno, or bun, and packages manager yarn,pnpm too via args.

At runtime you can control:

- `XDEBUG_MODE` (default off), `XDEBUG_CLIENT_HOST`
- `OVERLAY_DIRS=/opt/overlay` (colon-separated list of overlay roots)

---

## 4) s6 overlay & runtime

* `common/runtime/s6/cont-init.d/` runs on container boot.
* `common/runtime/s6/variants/<server>/services.d/` contains the main server service(s).
* `cont-init.d/20-overlay.sh` discovers overlays when `OVERLAY_DIRS` is set and symlinks `services.d/*` and `cont-*` into `/etc/…`.

**Custom overlay pattern (user land)**

```
.docker-snippets/overlays/<name>/services.d/<svc>/{run,type,log/run}
```

Mount as:

```yaml
volumes:
  - ./.docker-snippets/overlays:/opt/overlay:ro
environment:
  OVERLAY_DIRS: /opt/overlay
```

---

## 5) Docky (internal details) (its not perfact)

`v2/docky` is a Bash helper that uses **yq v4** to merge service stubs into a final `docker-compose.yml`.

* Default config: `v2/docky.yml` (devs only; **not** for end users).
* Stubs live in `v2/stubs/services/*.yml` (e.g., `app.yml`, `mysql.yml`).
* Pipeline:

  1. Collect selected stubs (`.stubs` from `docky.yml`).
  2. Merge with `yq` (app first, then the rest).
  3. Patch networks, app env/ports/volumes from config, add overlays/snippets mounts, extras.
  4. Resolve placeholders (interactive unless `--no-ask`).

**Common dev commands**

```bash
# from a fake consumer project
./.docker/v2/docky gen           # writes ./docker-compose.yml
./.docker/v2/docky list-svc
./.docker/v2/docky add-svc mysql
./.docker/v2/docky doctor
```

> For users, we still recommend either a manual minimal compose or `docky gen`. `docky.yml` should remain **internal** to php-contenv; only maintainers touch it.

---

## 6) Tests (local, no CI needed)

Everything lives in `v2/tests/`.

### What they do

* Build a **matrix** of images (8.4 × nginx/apache/frankenphp by default).
* Run each container, wait for HTTP 200, verify server process, ensure core PHP extensions exist, confirm **Xdebug is present but off**, check INI override via mounted `99-test.ini`, and assert overlay longrun service runs (creates `/tmp/hello.probe`).
* Smoke-test `docky` in a temp project.

### Run

From repo root:

```bash
make -C v2/tests               # full matrix (default TARGET=development, PORT_BASE=9300)
make -C v2/tests runtime-nginx # single target quick run
make -C v2/tests docky         # docky smoke test (no changes to your repo)
```

Env knobs:

```bash
PORT_BASE=9400 TARGET=development make -C v2/tests
```

Key files:

* `tests/scripts/test-runtime.sh` – build/run/probe one variant.
* `tests/scripts/test-matrix.sh` – iterates pairs (`Dockerfile` + server name).
* `tests/fixtures/` – overlay & php ini used in probes.
* `tests/test-docky.sh` – copies `v2` into a temp app, runs `docky gen`, `docky add-svc`.

---

## 7) Linting & sanity checks (maintainers)

Useful helpers in `v2/scripts/`:

```bash
bash v2/scripts/lint-shell.sh         # shellcheck all scripts
bash v2/scripts/lint-dockerfiles.sh   # hadolint (if you use it)
bash v2/scripts/validate-s6.sh        # quick sanity of s6 tree
bash v2/scripts/smoke.sh              # quick smoke build
```

Recommended local tools:

* `yq` v4
* `shellcheck`
* `hadolint` (optional)
* `dos2unix` (used in Dockerfiles to normalize line endings)

---

## 8) Adding/Changing things

### Add a PHP version

1. Copy an existing tree (e.g., `php/8.4` → `php/9.0`) and adjust `FROM` tags.
2. Verify `common/` compatibility; adjust if necessary.
3. Extend tests to include the new version (update matrix pairs).

### Add a server (variant)

1. Create `php/<ver>/<server>/Dockerfile`.
2. Add an s6 service under `common/runtime/s6/variants/<server>/services.d/<server>/`.
3. Update matrix to test it; add/adjust server process probe (pgrep check).

### Add an overlay

1. Create under `v2/overlays/<name>/…`.
2. Document intended mount (`/opt/overlay/<name>`).
3. Optionally provide a matching example in `examples/`.

### Add a compose service stub

1. Create `v2/stubs/services/<name>.yml`.
2. Reference it in `docky.yml` for dev testing (internal).
3. Re-run `./v2/docky gen` in a temp app to verify merge.

---

## 9) Release notes (optional workflow)

If you publish prebuilt images:

* Decide tags (e.g., `techgonia-devjio/php-contenv:8.4-nginx-v2.X.Y`).
* Build locally with desired args, push images.
* If you embed image tags in stubs, bump them; otherwise, user projects can build from Dockerfiles (recommended for dev).

---

## 10) Gotchas

* **macOS `realpath`**: BSD `realpath` differs; our scripts avoid GNU-only flags. If you change path ops, keep macOS compatibility.
* **`yq`**: v4 required. Use `yq eval` (`yq e`), not v3 syntax.
* **`docker compose`**: v2 CLI (`docker compose …`) everywhere.
* **Xdebug**: present by default (if enabled at build) but **off** at runtime; tests rely on this.

---

## 11) Maintainer checklist (before merging)

* [ ] `make -C v2/tests` passes locally for your target set.
* [ ] Nginx/Apache/FrankenPHP probes succeed (or update matrix if you intentionally limit).
* [ ] Overlays and `99-test.ini` mount verified.
* [ ] `docky` smoke test passes.
* [ ] Lint scripts (optional but nice).

---

Questions later? Drop them in issues with:

* Dockerfile path you tested,
* OS(host),docker version
* exact build args/env,
* test script output (from `v2/tests/scripts/test-runtime.sh`).
