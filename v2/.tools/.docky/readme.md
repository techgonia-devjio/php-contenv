# docky — Zero-boilerplate Docker Compose helper

Opinionated Bash tooling to scaffold and evolve a `docker-compose.yml` from small, reusable **stubs**. Built for local dev stacks that change often.

---

## Features

- **Generate** a fresh compose from stubs (`gen`)
- **Merge** new services non-destructively (`add-svc`)
- **Validate** compose with `docker compose config`
- **Templating stubs** via `DOCKY_REPLACEABLE_*` variables, prompted at runtime
- **yq v4** merge when available; awk fallback otherwise
- **Doctor** checks your setup and stub integrity
- Handy **snippets**: php-ini, s6-service, nginx-conf

---

## Requirements

- **docker** + **docker compose**
- **Bash** 4+
- **Optional:** `yq` v4 (mikefarah). With `yq` installed, merges are lossless and schema-safe.

> Check: `docky doctor`

---

## Layout

```

.docker/v2/.tools/.docky/
├── docky.sh
├── commands/
│   ├── gen(erate).sh      # create/refresh docker-compose.yml
│   ├── add_service.sh     # merge a stub into compose
│   ├── doctor.sh          # diagnostics
│   ├── list_services.sh   # list stubs
│   └── snippet.sh         # create config snippets
├── lib/
│   ├── common.sh          # template render + stub orchestration
│   ├── merger.sh          # yq/awk merge strategies
│   ├── utils.sh           # logs, prompts, cache, validation
│   └── version.sh
└── stubs/
├────── app.sh
├────── mysql.sh
├────── postgres.sh
└────── redis.sh

```

Cache file:
```

.docker-snippets/.docky-cache

```

---

## Quick start

```bash
# 1) Generate a compose (prompts for variables)
.docker/v2/docky gen app

# 2) Add services (merges into existing compose)
.docker/v2/docky/docky add-svc mysql
.docker/v2/docky/docky add-svc redis

# 3) Up your stack
.docker/v2/docky up -d
```

---

## CLI

### generate / gen / rebuild

Create **or** overwrite `docker-compose.yml` from a list of stubs (defaults to `app`).

```bash
.docker/v2/docky gen 
```

* Prompts for all `DOCKY_REPLACEABLE_*` variables and writes them to `.docker-snippets/.docky-cache`.

### add-svc

Merge a stub into an **existing** compose.

```bash
docky add-svc <name>
```

* Uses `yq v4` merge if available, else awk best-effort merge.
* Validates the result with `docker compose config -q` before writing.

### list / list-svc

Show available service stubs.

```bash
docky list
```

### doctor

Diagnostics: dependencies, paths, stub functions, and stub YAML smoke tests.

```bash
docky doctor
```

### snippet

Create handy project snippets under `.docker-snippets/`.

```bash
docky snippet php-ini [name]
docky snippet s6-service <name>
docky snippet nginx-conf [name]
docky snippet list
```

---

## Stubs

Each stub defines 2 functions:

```bash
# stubs/<service>.sh

get_variables() {
  # prompt for DOCKY_REPLACEABLE_* values
  prompt_for_var "DOCKY_REPLACEABLE_NETWORK_NAME" "Network" "mainnet"
}

get_service_template() {
  cat <<'EOF'
  myservice:
    image: example:latest
    networks:
      - DOCKY_REPLACEABLE_NETWORK_NAME
EOF
}

# Optional
get_volumes_template() {
  cat <<'EOF'
  myservice_data:
    driver: local
EOF
}
```

* **Templating**: Any `DOCKY_REPLACEABLE_*` token in templates is substituted with the cached/prompted value.
* **Indentation**: Service keys must be indented 2 spaces under `services:`; volume keys under `volumes:`.
* **Validation**: `doctor` renders stub YAML and validates with `docker compose config`.


## Examples

#### Generate compose with app + postgres + redis

```bash
docky gen app postgres redis
```

#### Add mysql later

```bash
docky add-svc mysql
```

#### Create a PHP ini override snippet

```bash
docky snippet php-ini custom
# Mount in compose:
#   - ./.docker-snippets/php/custom.ini:/usr/local/etc/php/conf.d/99-custom.ini:ro
```

#### Create an s6 service skeleton

```bash
docky snippet s6-service queue-worker
# Mount in compose:
#   - ./.docker-snippets/s6-services/queue-worker:/etc/services.d/queue-worker:ro
```

---

## Behavior

* **Merging**

    * `yq v4` path: deep merge, preserves structure.
    * `awk` path: best-effort injection under `services:`/`volumes:`.
* **Safety**

    * `gen` creates timestamped backups.
    * `add-svc` validates before write; aborts on invalid YAML.
* **Networks**

    * Network name is taken from `DOCKY_REPLACEABLE_NETWORK_NAME` in cache; defaults to `mainnet` if absent.

---

## Troubleshooting

* `docker compose config` fails:

    * Run `docky doctor` for details.
    * Check indentation in stub templates.
    * Verify placeholders were fully replaced (`DOCKY_REPLACEABLE_*` tokens should not remain).

* Wrong values used:

    * Edit `.docker-snippets/.docky-cache` or delete it to re-prompt.

* Force awk path (debug merges):

    * `DOCKY_FORCE_NO_YQ=1 docky add-svc <name>`

