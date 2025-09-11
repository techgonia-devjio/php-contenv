#!/usr/bin/env bash
set -euo pipefail

export DOCKY_HOME="${DOCKY_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
export STUBS_DIR="${STUBS_DIR:-${DOCKY_HOME}/stubs}"
export COMPOSE_OUT_FILE="${COMPOSE_OUT_FILE:-${PROJECT_ROOT}/docker-compose.yml}"
export DOCKY_SNIPPETS_DIR="${PROJECT_ROOT}/.docker-snippets"
export DOCKY_CACHE_FILE="${DOCKY_SNIPPETS_DIR}/.docky-cache"

# shellcheck disable=SC1091
source "${DOCKY_HOME}/lib/utils.sh"
# shellcheck disable=SC1091
source "${DOCKY_HOME}/lib/merger.sh"

# --- CORE FUNCTIONS ---
_render_template() {
  local template="$1"
  local vars; vars="$(compgen -v DOCKY_REPLACEABLE_ || true)"
  [ -z "$vars" ] && { printf '%s' "$template"; return; }

  while IFS= read -r var; do
    # shellcheck disable=SC2154
    local raw="${!var:-}"
    local esc="$(esc_sed "$raw")"
    template="$(printf '%s' "$template" | sed -e "s|${var}|${esc}|g")"
  done <<< "$vars"

  printf '%s' "$template"
}


_render_template_legacy() {
  local template="$1"
  for var in $(compgen -v DOCKY_REPLACEABLE_); do
    local value="${!var}"
    template=$(echo "$template" | sed "s|${var}|${value}|g")
  done
  echo "$template"
}


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

