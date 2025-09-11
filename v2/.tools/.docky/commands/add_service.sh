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
if have_yq; then
  info "Using 'yq' for merging."
  merge_with_yq "$COMPOSE_OUT_FILE" "$svc_yaml" "$vol_yaml"
else
  warn "yq v4 not found. Trying awk-based merge 99.999% may not work as expected lolzzz"
  merge_without_yq "$COMPOSE_OUT_FILE" "$service_name" "$svc_yaml" "$vol_yaml"
fi
good "Service '${service_name}' successfully merged."

