==================================================
 Directory Snapshot
==================================================
Source Path:   /Users/manpreet/Documents/kreatif/laravel/tech_proj/tag-der-bibliothek/.docker/v2/.tools/.docky
Generated on:  Wed Sep 10 21:35:29 CEST 2025
Ignored Dirs:  docs|common|database|examples|overlays|php|public|scripts
Ignored Files: Makefile|docky.bkup|*.yml|grabber.sh|LICENSE|Makefile|*.txt
--------------------------------------------------

### DIRECTORY TREE ###

.tools/.docky/
├── commands/
│   ├── add_service.sh
│   ├── doctor.sh
│   ├── generate.sh
│   ├── list_services.sh
│   ├── open_docs.sh
│   └── snippet.sh
├── docky.sh*
├── lib/
│   ├── common.sh
│   ├── merger.sh
│   ├── utils.sh
│   └── version.sh
├── readme.md
└── stubs/
    ├── app.sh
    ├── mysql.sh
    ├── postgres.sh
    └── redis.sh

4 directories, 16 files

---

### FILE: stubs/redis.sh ###

#!/usr/bin/env bash

get_variables() {
  info "--- Configuring Redis Service ---"
  prompt_for_var "DOCKY_REPLACEABLE_REDIS_PORT" "Enter host port for Redis" "6379"
  prompt_for_var "DOCKY_REPLACEABLE_REDIS_PASSWORD" "Enter Redis password (leave empty for none)" "password"
}

get_service_template() {
cat <<'EOF'
  redis:
    image: redis:alpine
    container_name: ${APP_NAME:-DOCKY_REPLACEABLE_APP_NAME}-redis
    command: redis-server --requirepass "${REDIS_PASSWORD:-DOCKY_REPLACEABLE_REDIS_PASSWORD}"
    ports:
      - "${REDIS_PORT:-DOCKY_REPLACEABLE_REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD:-DOCKY_REPLACEABLE_REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - "DOCKY_REPLACEABLE_NETWORK_NAME"
EOF
}

get_volumes_template() {
cat <<'EOF'
  redis_data:
    driver: local
EOF
}

---

### FILE: stubs/app.sh ###

#!/usr/bin/env bash

init_service_vars(){ :; }

get_variables() {
  info "--- Configuring App Service (Global Settings) ---"
  prompt_for_var "DOCKY_REPLACEABLE_APP_NAME" "Enter your application name" "docky_app"
  prompt_for_var "DOCKY_REPLACEABLE_APP_PORT" "Enter the web port to expose on your host" "8081"
  prompt_for_var "DOCKY_REPLACEABLE_VITE_PORT" "Enter the Vite port" "5170"
  prompt_for_var "DOCKY_REPLACEABLE_PHP_VERSION" "Enter PHP version (e.g., 8.4, 8.3)" "8.4"
  prompt_for_var "DOCKY_REPLACEABLE_WEBSERVER" "Enter webserver (nginx, apache, frankenphp)" "nginx"
  prompt_for_var "DOCKY_REPLACEABLE_NETWORK_NAME" "Enter Docker network name" "optimesh"
}

get_service_template() {
cat <<'EOF'
  app:
    container_name: ${APP_SERVICE_NAME:-DOCKY_REPLACEABLE_APP_NAME}
    build:
      context: "${DOCKER_CONTEXT:-./.docker/v2}"
      dockerfile: php/DOCKY_REPLACEABLE_PHP_VERSION/DOCKY_REPLACEABLE_WEBSERVER/Dockerfile
      # target: development or production
      target: ${PHP_DOCKER_TARGET:-development}
      args:
        JS_RUNTIME_REQUIRE_NODE: "true"
        JS_RUNTIME_NODE_VERSION: "22"
        INSTALL_DB_MYSQL_CLIENT: "true"
        PHP_EXT_PDO_MYSQL: "true"
        # look docs for more options to add or disable default extensions and packages
    extra_hosts:
      - "host.docker.internal:host-gateway"
    ports:
      - "${APP_PORT:-DOCKY_REPLACEABLE_APP_PORT}:80"
      - "${VITE_PORT:-DOCKY_REPLACEABLE_VITE_PORT}:${VITE_PORT:-5170}"
    environment:
      PUID: ${WWWUSER:-1000}
      PGID: ${WWWGROUP:-1000}
      # Must match the server name in PHPStorm's server configuration, need for xdebug
      PHP_IDE_CONFIG: "serverName=docker"
      XDEBUG_MODE: "off"
      XDEBUG_CONFIG: '${XDEBUG_CONFIG:-client_host=host.docker.internal}'
      IGNITION_LOCAL_SITES_PATH: '${PWD}'
      SUPERVISOR_PHP_USER: "www-data"
    volumes:
      # - "${DOCKER_SUBMODULE_DIR:-.docker/v2}/common/runtime/configs/php/92-docker-php-ext-xdebug.ini:/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
      # - ./.docker/v2/overlays/queue-worker:/opt/overlay/queue-worker:ro # example overlay mount provided by default
      # - ./.docker/v2/overlays/locales:/opt/overlay/locales:ro # example overlay mount provided by default
      # - ".docker-snippets/php/98-custom.ini:/usr/local/etc/php/conf.d/99-custom.ini" # custom user php.ini snippet
      - ./logs/:/var/log
      - .:/var/www/html
    # healthcheck:
      # test: ["CMD", "/usr/local/bin/healthcheck-nginx.sh"]
      # interval: 30s
      # timeout: 3s
      # retries: 5
      # disable: true # uncomment to disable healthcheck
    # use depends_on to ensure db is started before app, but does not wait for db to be "ready", only start the docker container
    # depends_on:
    #  - db
    networks:
      - DOCKY_REPLACEABLE_NETWORK_NAME

EOF
}
get_volumes_template(){ :; }

---

### FILE: stubs/postgres.sh ###

#!/usr/bin/env bash

get_variables() {
  info "--- Configuring PostgreSQL Service ---"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PORT" "Enter host port for PostgreSQL" "5432"
  prompt_for_var "DOCKY_REPLACEABLE_DB_DATABASE" "Enter PostgreSQL database name" "laravel"
  prompt_for_var "DOCKY_REPLACEABLE_DB_USERNAME" "Enter PostgreSQL user" "sail"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PASSWORD" "Enter PostgreSQL password" "password"
}

get_service_template() {
cat <<'EOF'
  postgres:
    image: postgres:18-alpine
    container_name: ${DB_CONTAINER_NAME:-DOCKY_REPLACEABLE_APP_NAME}-pgsql
    environment:
      PGPASSWORD: '${DB_PASSWORD:-secret}'
      POSTGRES_DB: "${DB_DATABASE:-DOCKY_REPLACEABLE_DB_DATABASE}"
      POSTGRES_USER: "${DB_USERNAME:-DOCKY_REPLACEABLE_DB_USERNAME}"
      POSTGRES_PASSWORD: "${DB_PASSWORD:-DOCKY_REPLACEABLE_DB_PASSWORD}"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "${DB_PORT:-DOCKY_REPLACEABLE_DB_PORT}:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME:-DOCKY_REPLACEABLE_DB_USERNAME} -d ${DB_DATABASE:-DOCKY_REPLACEABLE_DB_DATABASE}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - "DOCKY_REPLACEABLE_NETWORK_NAME"
    restart: unless-stopped
EOF
}

get_volumes_template() {
cat <<'EOF'
  postgres_data:
    driver: local
EOF
}

---

### FILE: stubs/mysql.sh ###

#!/usr/bin/env bash

get_variables() {
  info "--- Configuring MySQL Service ---"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PORT" "Enter host port for MySQL" "3306"
  prompt_for_var "DOCKY_REPLACEABLE_DB_DATABASE" "Enter MySQL database name" "laravel"
  prompt_for_var "DOCKY_REPLACEABLE_DB_USERNAME" "Enter MySQL user" "sail"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PASSWORD" "Enter MySQL password" "password"
  prompt_for_var "DOCKY_REPLACEABLE_DB_ROOT_PASSWORD" "Enter MySQL root password" "secret"
}

get_service_template() {
cat <<'EOF'
  mysql:
    image: mysql:8.0
    container_name: ${APP_NAME:-DOCKY_REPLACEABLE_APP_NAME}-mysql
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_ROOT_PASSWORD:-DOCKY_REPLACEABLE_DB_ROOT_PASSWORD}"
      MYSQL_DATABASE: "${DB_DATABASE:-DOCKY_REPLACEABLE_DB_DATABASE}"
      MYSQL_USER: "${DB_USERNAME:-DOCKY_REPLACEABLE_DB_USERNAME}"
      MYSQL_PASSWORD: "${DB_PASSWORD:-DOCKY_REPLACEABLE_DB_PASSWORD}"
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "${DB_PORT:-DOCKY_REPLACEABLE_DB_PORT}:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    networks:
      - "DOCKY_REPLACEABLE_NETWORK_NAME"
EOF
}

get_volumes_template() {
cat <<'EOF'
  db_data:
    driver: local
EOF
}


---

### FILE: readme.md ###

How does docky work?

Docky is simple bash script that should act as an assistant for non-beginner docker users. Basically, it has some useful commands
that one can run in order to make their life easier. If a user doesn't have experience with docker, user can run some simple commands
that will help the user to get started with this package. 

Docky is simple assistant whose main goal is to provide assitance with docker compose file along with other helpful.
Primary goal is to add the docker services and run the app. One can generate new docker compose file if not exists by running .docker/v2/docky gen.

So basically this package is a setup for setting a docker enviornment in any project. Suppose you have a project web app and you 
want to run and develop this project in docker wihtout installing any dependencies on your local machine. You can use this package and you just have to add 
this package as a git submodule in your project. After that you can run the command .docker/v2/docky gen to generate a docker compose file.
Where .docker is the folder name of submodule and v2 is the second version of this package. After that you can run the command .docker/v2/docky up to start the docker services.
So from the main project web app, one can execute our docky script to manage the docker services.

In our this package we provide some stubs for starting and i have planned to add more stubs in future. 
Currrently, docky would read the stubs from .docker/v2/stubs and see what we have and then it will add the service in docker composer.

Docky uses yq to manipulate the yaml files. Basically, if user is generating the docker compose file, it will add the app.yml for the first time.
Then later user can run the command .docker/v2/docky add-svc <service-name> to add more services, in this case docky will merge the exisitng docker compose file
with the new service stub file without effecting the existing services in the docker compose file. This is important, it must now touch the exisitng services in docker compose file. Because
it could happen that the docker compose file already exists and has already lets say the app service and with some overridden values and so it would be bad if we override the existing values.

The stub also contains the some prefix variables like $DOCKY_REPLACE_NETWORK_NAME, and this should be parsed before merging from the stub files.
All the substitute variable start with $DOCKY_REPLACE_ and then the variable name. This is important to avoid any conflict with the other variables in the stub files.
in this case, docky will prompt in stdin to ask the user to provide the value for the variable, in this case it will ask for the network name and
then it will replace the variable with the user provided value.

we would remove the docky.yml file which i have added for the default variables but this didn't work i have expacted. 
Currently, the docky doesn't working properly it is failing to regenerate the docker compose file... most of the time script fails to read or write the compose file. I was thinking
if can turn our yml files into json and read the docker-compose.yml file and then merge and rewrite it again in the yml format the docker compose file.


---

### FILE: lib/utils.sh ###

#!/usr/bin/env bash

# -------- tty / colors --------
_is_tty() { [[ -t 1 ]]; }
if _is_tty; then
  _C_BOLD="$(printf '\033[1m')"; _C_DIM="$(printf '\033[2m')"
  _C_RED="$(printf '\033[31m')"; _C_YEL="$(printf '\033[33m')"
  _C_CYN="$(printf '\033[36m')"; _C_GRN="$(printf '\033[32m')"
  _C_RST="$(printf '\033[0m')"
else
  _C_BOLD=""; _C_DIM=""; _C_RED=""; _C_YEL=""; _C_CYN=""; _C_GRN=""; _C_RST=""
fi

# -------- logging --------
log()   { printf "%s%s%s\n" "${_C_DIM}" "$*" "${_C_RST}" 1>&2; }
info()  { printf "%s%s%s\n" "${_C_CYN}" "$*" "${_C_RST}" 1>&2; }
good()  { printf "%s%s%s\n" "${_C_GRN}" "$*" "${_C_RST}" 1>&2; }
warn()  { printf "%s%s%s\n" "${_C_YEL}" "$*" "${_C_RST}" 1>&2; }
error() { printf "%s%s%s\n" "${_C_RED}${_C_BOLD}" "$*" "${_C_RST}" 1>&2; }
die() { error "$@"; exit 1; }

# -------- yq detection (mikefarah v4) --------
have_yq() {
  [ "${DOCKY_FORCE_NO_YQ:-0}" = "1" ] && return 1
  command -v yq >/dev/null 2>&1 || return 1
  local v; v="$(yq --version 2>&1 || true)"
  # Check for 'mikefarah' and a version number starting with 'v' or a space, followed by '4.'
  echo "$v" | grep -qi 'mikefarah' || return 1
  echo "$v" | grep -qE '[v ]4\.' || return 1
  return 0
}

# -------- cache helpers --------
_cache_get() {
  local key="$1" line
  [ -f "${DOCKY_CACHE_FILE}" ] || return 1
  line="$(grep -E "^${key}=" "${DOCKY_CACHE_FILE}" 2>/dev/null || true)"
  [ -n "${line}" ] || return 1
  printf "%s" "${line#${key}=}"
}

_cache_set() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "${DOCKY_CACHE_FILE}")"
  touch "${DOCKY_CACHE_FILE}"
  if grep -qE "^${key}=" "${DOCKY_CACHE_FILE}" 2>/dev/null; then
    tmp="$(mktemp)"; sed -E "s|^${key}=.*|${key}=${val}|" "${DOCKY_CACHE_FILE}" > "$tmp" && mv "$tmp" "${DOCKY_CACHE_FILE}"
  else
    printf "%s=%s\n" "${key}" "${val}" >> "${DOCKY_CACHE_FILE}"
  fi
}

# -------- prompting --------
prompt_for_var() {
  local var_name="$1" prompt_text="$2" def="${3:-}"
  local cached input value
  cached="$(_cache_get "${var_name}" || true)"
  local shown_default="${cached:-$def}"
  printf "› %s %s(default: %s)%s: " "${prompt_text}" "${_C_DIM}" "${shown_default}" "${_C_RST}" > /dev/tty
  IFS= read -r input < /dev/tty || input=""
  value="${input:-$shown_default}"
  export "${var_name}"="${value}"
  _cache_set "${var_name}" "${value}"
}


---

### FILE: lib/common.sh ###

#!/usr/bin/env bash

# --- PATHS (DEFINED FIRST) ---
export DOCKY_HOME="${DOCKY_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
export STUBS_DIR="${STUBS_DIR:-${DOCKY_HOME}/stubs}"
export COMPOSE_OUT_FILE="${COMPOSE_OUT_FILE:-${PROJECT_ROOT}/docker-compose.yml}"
export DOCKY_SNIPPETS_DIR="${PROJECT_ROOT}/.docker-snippets"
export DOCKY_CACHE_FILE="${DOCKY_SNIPPETS_DIR}/.docky-cache"

# --- SOURCE LIBRARIES ---
# shellcheck disable=SC1091
source "${DOCKY_HOME}/lib/utils.sh"
# shellcheck disable=SC1091
source "${DOCKY_HOME}/lib/merger.sh"

# --- CORE FUNCTIONS ---

# Renders a template by replacing DOCKY_REPLACEABLE_* variables
_render_template() {
  local template="$1"
  for var in $(compgen -v DOCKY_REPLACEABLE_); do
    local value="${!var}"
    template=$(echo "$template" | sed "s|${var}|${value}|g")
  done
  echo "$template"
}

# Orchestrates the process for a single stub
build_stub_docs() {
  local svc="$1"
  local stub="${STUBS_DIR}/${svc}.sh"
  [ -f "$stub" ] || die "Stub file not found: ${stub}"

  ( # Run in a subshell to isolate variables
    # shellcheck disable=SC1090
    source "$stub"
    [ "$(type -t get_variables)" = "function" ] && get_variables
    local service_template; service_template="$([ "$(type -t get_service_template)" = "function" ] && get_service_template || echo "")"
    local volumes_template; volumes_template="$([ "$(type -t get_volumes_template)" = "function" ] && get_volumes_template || echo "")"
    local final_service_yaml; final_service_yaml="$(_render_template "$service_template")"
    local final_volumes_yaml; final_volumes_yaml="$(_render_template "$volumes_template")"
    printf -- '%s\0%s' "$final_service_yaml" "$final_volumes_yaml"
  )
}


---

### FILE: lib/merger.sh ###

#!/usr/bin/env bash

# Requires functions from utils.sh (have_yq, info, warn)

merge_with_yq() {
  local compose="$1" service_yaml="$2" volume_yaml="$3"
  local tmp_add tmp_out
  tmp_add="$(mktemp)"; tmp_out="$(mktemp)"
  cat > "$tmp_add" <<EOF
services:
${service_yaml}

volumes:
${volume_yaml}
EOF
  yq eval-all 'select(fileIndex==0) *+ select(fileIndex==1)' "$compose" "$tmp_add" > "$tmp_out"
  mv "$tmp_out" "$compose"
  rm -f "$tmp_add"
}

compose_has_service() {
  local compose="$1" svc="$2"
  if have_yq; then
    yq -e ".services | has(\"$svc\")" "$compose" >/dev/null 2>&1
  else
    awk -v s="$svc" '
      $0 ~ /^services:/ { in=1; next }
      in && $0 ~ /^[^[:space:]]/ { in=0 }
      in && $0 ~ "^[[:space:]]+"s":" { found=1 }
      END { exit(found?0:1) }
    ' "$compose"
  fi
}

merge_without_yq() {
    local compose="$1" service_name="$2" service_yaml="$3" volume_yaml="$4"

    # Export multi-line strings so awk can safely read them from the environment
    export AWK_SVC_BLOCK="$service_yaml"
    export AWK_VOL_BLOCK="$volume_yaml"

    local current_content; current_content=$(cat "$compose")
    local processed_content

    # --- Step 1: Inject Service Block ---
    if echo "$current_content" | grep -qE '^services:'; then
        # If services: key exists, inject the block under it
        processed_content=$(echo "$current_content" | awk -v name="$service_name" '
            BEGIN { svc_block = ENVIRON["AWK_SVC_BLOCK"] }
            /^services:/ { print; in_s=1; next }
            in_s && /^[^[:space:]]/ { if (!ins) { print "  # --- Service: "name" ---"; print svc_block; ins=1 } in_s=0 }
            { print }
            END { if(in_s && !ins) { print "  # --- Service: "name" ---"; print svc_block } }
        ')
    else
        # If no services: key, add it to the end
        processed_content=$(printf '%s\nservices:\n%s\n' "$current_content" "$service_yaml")
    fi

    # --- Step 2: Inject Volume Block ---
    if [ -n "$volume_yaml" ]; then
        if echo "$processed_content" | grep -qE '^volumes:'; then
            # If volumes: key exists, inject under it
            processed_content=$(echo "$processed_content" | awk '
                BEGIN { vol_block = ENVIRON["AWK_VOL_BLOCK"] }
                /^volumes:/ { print; in_v=1; next }
                in_v && /^[^[:space:]]/ { if (!ins) { print vol_block; ins=1 } in_v=0 }
                { print }
                END { if(in_v && !ins) { print vol_block } }
            ')
        else
            # If no volumes: key, add it before networks: or at the very end
            if echo "$processed_content" | grep -qE '^networks:'; then
                processed_content=$(echo "$processed_content" | awk '
                    BEGIN { vol_block = ENVIRON["AWK_VOL_BLOCK"] }
                    /^networks:/ && !done { print "volumes:"; print vol_block; print ""; done=1 }
                    { print }
                ')
            else
                processed_content=$(printf '%s\n\nvolumes:\n%s\n' "$processed_content" "$volume_yaml")
            fi
        fi
    fi

    # --- Step 3: Write the final, correct content back to the file ---
    echo "$processed_content" > "$compose"

    # Clean up environment variables
    unset AWK_SVC_BLOCK
    unset AWK_VOL_BLOCK
}

---

### FILE: lib/version.sh ###

# shellcheck disable=SC2034
DOCKY_VERSION="v2.0.0"
---

### FILE: commands/add_service.sh ###

#!/usr/bin/env bash

service_name="${1:-}"
[ -n "$service_name" ] || die "Usage: docky add-svc <name>"
stub_file="${STUBS_DIR}/${service_name}.sh"
[ -f "$stub_file" ] || die "Stub '${service_name}' not found in ${STUBS_DIR}"
[ -f "$COMPOSE_OUT_FILE" ] || die "Compose file not found. Run 'docky gen' first to create it."

info "--- Adding service: ${service_name} ---"
if compose_has_service "$COMPOSE_OUT_FILE" "$service_name"; then
  info "Service '${service_name}' already present. Nothing to do."
  exit 0
fi

# Load cached variables from the last 'gen' run and export them so the new stub
# has access to global settings like NETWORK_NAME.
if [ -f "${DOCKY_CACHE_FILE}" ]; then
  set -a # Automatically export all variables defined from now on
  # shellcheck disable=SC1090
  source "${DOCKY_CACHE_FILE}"
  set +a # Stop automatically exporting
fi

svc_yaml="" vol_yaml=""
if ! { IFS= read -r -d $'\0' svc_yaml && { IFS= read -r -d '' vol_yaml || true; }; } < <(build_stub_docs "$service_name"); then
    die "Failed to read definition for service '${service_name}'. Aborting."
fi

info "Merging service '${service_name}' into compose file..."
if not have_yq; then
  info "Using 'yq' for merging."
  merge_with_yq "$COMPOSE_OUT_FILE" "$svc_yaml" "$vol_yaml"
else
  warn "yq v4 not found. Trying awk-based merge 99.999% may not work as expected."
  merge_without_yq "$COMPOSE_OUT_FILE" "$service_name" "$svc_yaml" "$vol_yaml"
fi
good "Service '${service_name}' successfully merged."


---

### FILE: commands/doctor.sh ###

#!/usr/bin/env bash

info "--- Running Docky Doctor ---"
ok=1

# --- Check 1: Core Dependencies ---
info "› Checking for core dependencies..."
command -v docker >/dev/null 2>&1 && good "  ✓ docker found" || { error "  ✗ docker not found"; ok=0; }
if have_yq; then
  good "  ✓ yq (v4, mikefarah) found"
else
  warn "  ! yq (v4, mikefarah) not found. Will use less reliable awk merger."
  info "    (See https://github.com/mikefarah/yq for installation)"
fi

# --- Check 2: Paths and Permissions ---
info "› Checking paths and permissions..."
[ -d "${DOCKY_HOME}" ] && good "  ✓ DOCKY_HOME is valid: ${DOCKY_HOME}" || { error "  ✗ DOCKY_HOME is not a valid directory"; ok=0; }
[ -d "${STUBS_DIR}" ] && good "  ✓ STUBS_DIR is valid: ${STUBS_DIR}" || { error "  ✗ STUBS_DIR is not a valid directory"; ok=0; }
[ -w "$(dirname "${DOCKY_CACHE_FILE}")" ] && good "  ✓ Cache directory is writable." || { error "  ✗ Cache directory is not writable: $(dirname "${DOCKY_CACHE_FILE}")"; ok=0; }
[ -x "${DOCKY_HOME}/docky.sh" ] && good "  ✓ docky.sh is executable." || { warn "  ! docky.sh is not executable (run 'chmod +x .docker/v2/docky')"; }


# --- Check 3: Stub File Integrity ---
info "› Validating service stubs..."
for stub in "${STUBS_DIR}"/*.sh; do
  svc_name=$(basename -s .sh "$stub")
  info "  - Checking stub: ${svc_name}"
  ( # Run in a subshell to avoid polluting the main script
    source "$stub"
    [ "$(type -t get_variables)" = "function" ] && good "    ✓ Found get_variables()" || { error "    ✗ Missing get_variables() function"; ok=0; }
    [ "$(type -t get_service_template)" = "function" ] && good "    ✓ Found get_service_template()" || { error "    ✗ Missing get_service_template() function"; ok=0; }
    [ "$(type -t get_volumes_template)" = "function" ] && good "    ✓ Found get_volumes_template()" || { error "    ✗ Missing get_volumes_template() function"; ok=0; }
  )
done

echo ""
if [ "$ok" -eq 1 ]; then
  good "✓ Docky setup looks good!"
else
  error "✗ Docky setup has issues. Please review the errors above."
  exit 1
fi

---

### FILE: commands/generate.sh ###

#!/usr/bin/env bash


force=0
services_to_generate=()
for arg in "$@"; do
  [[ "$arg" == "--force" ]] && force=1 || services_to_generate+=("$arg")
done

[ ${#services_to_generate[@]} -eq 0 ] && services_to_generate=("app")

if [[ " ${services_to_generate[*]} " =~ " app " ]] && [[ "${services_to_generate[0]}" != "app" ]]; then
  services_without_app=()
  for svc in "${services_to_generate[@]}"; do [ "$svc" != "app" ] && services_without_app+=("$svc"); done
  services_to_generate=("app" "${services_without_app[@]}")
fi

if [ -f "${COMPOSE_OUT_FILE}" ] && [ $force -eq 0 ]; then
  info "${COMPOSE_OUT_FILE#${PROJECT_ROOT}/} already exists. Use 'docky gen ${services_to_generate[*]} --force' to overwrite."
  exit 0
fi

[ -f "${COMPOSE_OUT_FILE}" ] && [ $force -eq 1 ] && {
  ts="$(date +%Y%m%d-%H%M%S)"; bak_file="${COMPOSE_OUT_FILE}.${ts}.bak"
  cp "${COMPOSE_OUT_FILE}" "$bak_file"
  info "Backed up existing compose file to ${bak_file#${PROJECT_ROOT}/}"
}

info "Assembling new docker-compose.yml..."
services_yaml=""
volumes_yaml=""
network_name=""

for svc in "${services_to_generate[@]}"; do
  info "--- Assembling service: ${svc} ---"
  svc_yaml_part="" vol_yaml_part=""
  if ! { IFS= read -r -d $'\0' svc_yaml_part && { IFS= read -r -d '' vol_yaml_part || true; }; } < <(build_stub_docs "$svc"); then
      warn "Failed to read definition for service '${svc}'. Skipping."
      continue
  fi

  if [ -n "${svc_yaml_part}" ]; then
    services_yaml="${services_yaml}${services_yaml:+$'\n'}${svc_yaml_part}"
  fi
  if [ -n "${vol_yaml_part}" ]; then
    volumes_yaml="${volumes_yaml}${volumes_yaml:+$'\n'}${vol_yaml_part}"
  fi
done

network_name=$(_cache_get "DOCKY_REPLACEABLE_NETWORK_NAME")
[ -z "${services_yaml}" ] && die "No services could be assembled. Aborting generation."

tmp="$(mktemp)"
{
  echo "# This file was generated by docky."
  echo "version: '3.8'"
  echo ""
  echo "services:"
  printf '%s\n' "${services_yaml}"
  if [ -n "${volumes_yaml}" ]; then
    echo ""
    echo "volumes:"
    printf '%s\n' "${volumes_yaml}"
  fi
  echo ""
  echo "networks:"
  echo "  ${network_name}:"
  echo "    driver: bridge"
  echo "    name: ${network_name}"
} > "$tmp"

mv "$tmp" "${COMPOSE_OUT_FILE}"
good "Wrote ${COMPOSE_OUT_FILE#${PROJECT_ROOT}/}"


---

### FILE: commands/list_services.sh ###

#!/usr/bin/env bash


info "--- Available Service Stubs ---"
# List all .sh files in the stubs directory and remove the extension
ls -1 "$STUBS_DIR" | sed 's/\.sh$//' | sed 's/^/  - /'

echo ""
log "(Run 'docky add-svc <name>' to enable a service)"


---

### FILE: commands/open_docs.sh ###

#!/usr/bin/env bash
set -euo pipefail

if ! command -v mkdocs >/dev/null 2>&1; then
  echo "✗ ERROR: mkdocs not found. Please install it first: pip install mkdocs" >&2
  exit 1
fi

docs_dir="${PROJECT_ROOT}/.docker/v2/docs"

if [ -f "$docs_dir/mkdocs.yml" ]; then
    echo "› Serving documentation from ${docs_dir} on http://127.0.0.1:8000"
    (cd "$docs_dir" && mkdocs serve)
else
    echo "✗ ERROR: mkdocs.yml not found in ${docs_dir}" >&2
    exit 1
fi

---

### FILE: commands/snippet.sh ###

#!/usr/bin/env bash


sub_command="${1:-help}"
snippet_name="${2:-}" # Name is now optional for some commands

_show_snippet_help() {
    info "docky snippet — A helper for creating common config files"
    cat <<EOF

Usage:
  docky snippet <command> [name]

Commands:
  php-ini [name]      Create a custom PHP .ini file.
                      (Default name: custom)

  s6-service <name>   Create a new s6-overlay service directory and run script.
                      (Name is required)

  nginx-conf [name]   Create a custom Nginx .conf file.
                      (Default name: custom)

  list                List all existing snippets.
EOF
}

case "$sub_command" in
    php-ini)
        [ -z "$snippet_name" ] && snippet_name="custom"
        ini_name="${snippet_name%.ini}"
        ini_dir="${DOCKY_SNIPPETS_DIR}/php"
        mkdir -p "$ini_dir"
        ini_file="${ini_dir}/${ini_name}.ini"

        if [ -f "$ini_file" ]; then
            warn "Snippet already exists: ${ini_file#${PROJECT_ROOT}/}"
        else
            cat > "$ini_file" <<EOF
; ${ini_name}.ini — project snippet
; This file can be mounted into your container to override PHP settings.

memory_limit = 512M
upload_max_filesize = 128M
EOF
            good "Created snippet: ${ini_file#${PROJECT_ROOT}/}"
            info "--- How to use ---"
            log "To apply this configuration, add the following volume mount to your 'app' service in docker-compose.yml:"
            echo ""
            good "    volumes:"
            good "      - ./.docker-snippets/php/${ini_name}.ini:/usr/local/etc/php/conf.d/99-${ini_name}.ini:ro"
            echo ""
        fi
        ;;

    s6-service)
        [ -z "$snippet_name" ] && die "Error: A name is required for the s6-service snippet."
        service_dir="${DOCKY_SNIPPETS_DIR}/s6-services/${snippet_name}/services/${snippet_name}"
        run_file="${service_dir}/run"
        type_file="${service_dir}/type"

        if [ -d "$service_dir" ]; then
            warn "Snippet directory already exists: ${service_dir#${PROJECT_ROOT}/}"
        else
            mkdir -p "$service_dir"
            cat > "$run_file" <<EOF
#!/command/with-contenv bash
# s6-overlay service script: ${snippet_name}
# This script will be executed and monitored by the s6 supervisor.
# Ensure it is an executable file (chmod +x).

echo "Starting '${snippet_name}' service..."

# --- EXAMPLE: Long-running process ---
# Your long-running application command goes here.
# 'exec' is important as it replaces the shell process with your command,
# allowing s6 to correctly manage the process.

# Example for a Laravel Queue Worker:
# exec php /var/www/html/artisan queue:work --sleep=3 --tries=3

# Example for a simple looping script:
# while true; do
#   echo "'${snippet_name}' is running..."
#   sleep 10
# done

EOF
            chmod +x "$run_file"
            echo "longrun" > "$type_file" # or "oneshot" for short tasks
            echo "#!/bin/sh" > "${service_dir}/finish"
            good "Created s6-service snippet: ${service_dir#${PROJECT_ROOT}/}"
            info "--- How to use ---"
            log "To enable this service, mount its directory into '/etc/services.d/' in your 'app' service in docker-compose.yml:"
            echo ""
            good "    volumes:"
            good "      - ./.docker-snippets/s6-services/${snippet_name}:/etc/services.d/${snippet_name}:ro"
            echo ""
        fi
        ;;

    nginx-conf)
        [ -z "$snippet_name" ] && snippet_name="custom"
        conf_name="${snippet_name%.conf}"
        conf_dir="${DOCKY_SNIPPETS_DIR}/nginx"
        mkdir -p "$conf_dir"
        conf_file="${conf_dir}/${conf_name}.conf"

        if [ -f "$conf_file" ]; then
            warn "Snippet already exists: ${conf_file#${PROJECT_ROOT}/}"
        else
            cat > "$conf_file" <<EOF
# ${conf_name}.conf — project snippet
# This file can be mounted into your Nginx container to add or override server configuration.

server {
  listen 80;
  server_name my-custom-domain.local;

  root /var/www/html/public;

  location / {
    # ... your custom location logic ...
    try_files \$uri /index.php\$is_args\$args;
  }
}
EOF
            good "Created snippet: ${conf_file#${PROJECT_ROOT}/}"
            info "--- How to use ---"
            log "To apply this configuration, mount the file into Nginx's config directory in your 'app' service in docker-compose.yml:"
            echo ""
            good "    volumes:"
            good "      - ./.docker-snippets/nginx/${conf_name}.conf:/etc/nginx/sites-enabled/${conf_name}.conf:ro"
            echo ""
        fi
        ;;

    list)
        info "--- Project Snippets in ${DOCKY_SNIPPETS_DIR#${PROJECT_ROOT}/} ---"
        if [ -d "$DOCKY_SNIPPETS_DIR" ] && [ -n "$(ls -A "$DOCKY_SNIPPETS_DIR")" ]; then
            find "$DOCKY_SNIPPETS_DIR" -type f -print | sed "s|^${PROJECT_ROOT}/|  - |"
        else
            log "  (No snippets directory found or directory is empty)"
        fi
        ;;
    *)
        _show_snippet_help
        ;;
esac


---

### FILE: docky.sh ###

#!/usr/bin/env bash

#set -euo pipefail

export DOCKY_HOME
DOCKY_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DOCKY_HOME/lib/common.sh"

cmd="${1:-help}"; shift || true

case "$cmd" in
  gen|generate|rebuild)
    source "$DOCKY_HOME/commands/generate.sh" "$@"
    ;;
  add-svc)
    source "$DOCKY_HOME/commands/add_service.sh" "$@"
    ;;
  doctor)
    source "$DOCKY_HOME/commands/doctor.sh" "$@"
    ;;
  list-svc|list)
    source "$DOCKY_HOME/commands/list_services.sh" "$@"
    ;;
  snippet)
    source "$DOCKY_HOME/commands/snippet.sh" "$@"
    ;;
  up|down|ps|logs|exec|build|pull|restart)
    docker compose -f "${COMPOSE_OUT_FILE}" "$cmd" "$@"
    ;;
  *)
    info "docky — Docker helper"
    cat <<EOF

Usage:
  docky gen [app mysql...]  Create/refresh docker-compose.yml from stubs
  docky add-svc <name>      Add a new service to an existing compose file
  docky list                List available service stubs
  docky doctor              Run diagnostics to check your setup
  docky [up|down|logs|...]  Pass-through to docker compose
EOF
    ;;
esac


