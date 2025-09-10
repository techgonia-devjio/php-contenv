#!/usr/bin/env bash
#set -euo pipefail

# --- PATHS ---
export DOCKY_HOME="${DOCKY_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
export STUBS_DIR="${STUBS_DIR:-${DOCKY_HOME}/stubs}"
export COMPOSE_OUT_FILE="${COMPOSE_OUT_FILE:-${PROJECT_ROOT}/docker-compose.yml}"
export ENV_FILE="${ENV_FILE:-${PROJECT_ROOT}/.env}"
export SERVICES_CONFIG_FILE="${SERVICES_CONFIG_FILE:-${PROJECT_ROOT}/.docker-services}"

# --- HELPERS ---
have_yq() { command -v yq >/dev/null 2>&1; }

prompt_for_var() {
  local var_name="$1" prompt_text="$2" default_value="${3:-}"
  local current_value=""
  if [ -f "$ENV_FILE" ]; then
    current_value="$(grep -E "^${var_name}=" "$ENV_FILE" | sed -E "s/^${var_name}=//" || true)"
  fi
  if [ -z "${current_value}" ]; then
    read -p "› ${prompt_text} (default: ${default_value}): " user_input
    current_value="${user_input:-$default_value}"
    { [ -f "$ENV_FILE" ] || touch "$ENV_FILE"; }
    if grep -qE "^${var_name}=" "$ENV_FILE"; then
      sed -i'' -E "s|^${var_name}=.*|${var_name}=${current_value}|" "$ENV_FILE"
    else
      echo "${var_name}=${current_value}" >> "$ENV_FILE"
    fi
  fi
  export "${var_name}"="${current_value}"
}

_require_stub_fn() {
  local fn="$1" name="$2"
  declare -F "$fn" >/dev/null || { echo "✗ Stub '${name}' missing function '${fn}'" >&2; exit 1; }
}

# Build YAML blocks for a single stub (service + volumes)
build_stub_docs() {
  local svc="$1"
  local stub="${STUBS_DIR}/${svc}.sh"

  [ -f "$stub" ] || { echo "✗ Stub not found: ${stub}" >&2; exit 1; }

  # shellcheck disable=SC1090
  source "$stub"

  # ** THE FIX IS HERE **
  # Force prompts to read from the terminal, preventing them from
  # interfering with the stdout pipe. Output still goes to stderr.
  if declare -F init_service_vars >/dev/null; then init_service_vars < /dev/tty >&2; fi

  _require_stub_fn get_service "$svc"
  _require_stub_fn get_volumes "$svc"

  local service_yaml volume_yaml
  service_yaml="$(get_service | sed 's/[[:space:]]\+$//')"
  volume_yaml="$(get_volumes | sed 's/[[:space:]]\+$//')"

  printf -- '%s\0%s' "$service_yaml" "$volume_yaml"

  # cleanup functions from environment to avoid cross bleed
  unset -f init_service_vars || true
  unset -f get_service || true
  unset -f get_volumes || true
}

# Merge a new service/volume into an EXISTING compose using yq
merge_with_yq() {
  local compose="$1" service_yaml="$2" volume_yaml="$3"
  local tmp_add tmp_out
  tmp_add="$(mktemp)"
  tmp_out="$(mktemp)"
  cat > "$tmp_add" <<EOF
services:
${service_yaml}

volumes:
${volume_yaml}
EOF

  yq ea 'select(fileIndex==0) *+ select(fileIndex==1)' "$compose" "$tmp_add" > "$tmp_out"
  mv "$tmp_out" "$compose"
  rm -f "$tmp_add"
}

# Grep-based check if service key exists in compose
compose_has_service() {
  local compose="$1" svc="$2"
  # allow arbitrary indentation, match top-level under "services:"
  awk -v s="$svc" '
    $0 ~ /^services:/ { in_s=1; next }
    $0 ~ /^[^[:space:]]/ && $0 !~ /^services:/ { in_s=0 }
    in_s && $0 ~ "^[[:space:]]+"s":" { found=1 }
    END { exit(found?0:1) }
  ' "$compose"
}

# Fallback merge without yq (best-effort)
merge_without_yq() {
  local compose="$1" service_name="$2" service_yaml="$3" volume_yaml="$4"
  local tmp
  tmp="$(mktemp)"

  # 1) Inject service block under `services:` before next top-level key
  awk -v svc_block="$service_yaml" -v svc_name="$service_name" '
    BEGIN{inserted=0}
    /^services:/ { print; in_services=1; next }
    in_services && (/^[^[:space:]]/){ # next top-level section
      if (!inserted) {
        print "  # --- Service: " svc_name " ---"
        print svc_block
        inserted=1
      }
      in_services=0
    }
    { print }
    END {
      if (in_services && !inserted) {
        print "  # --- Service: " svc_name " ---"
        print svc_block
      }
    }
  ' "$compose" > "$tmp"
  mv "$tmp" "$compose"

  # 2) Inject volumes
  if [ -n "$volume_yaml" ]; then
    if grep -qE '^volumes:' "$compose"; then
      # insert after volumes: before next top-level key
      awk -v vol_block="$volume_yaml" '
        BEGIN{done=0}
        /^volumes:/ { print; in_vol=1; next }
        in_vol && /^[^[:space:]]/ {
          if (!done) { print vol_block; done=1 }
          in_vol=0
        }
        { print }
        END {
          if (in_vol && !done) { print vol_block }
        }
      ' "$compose" > "$tmp"
      mv "$tmp" "$compose"
    else
      # add new volumes section right before networks: if exists, else at EOF
      if grep -qE '^networks:' "$compose"; then
        awk -v vol_block="$volume_yaml" '
          /^networks:/ && !printed { print "volumes:"; print vol_block; printed=1 }
          { print }
        ' "$compose" > "$tmp"
        mv "$tmp" "$compose"
      else
        {
          echo ""
          echo "volumes:"
          echo "$volume_yaml"
        } >> "$compose"
      fi
    fi
  fi
}
