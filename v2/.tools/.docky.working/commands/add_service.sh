#!/usr/bin/env bash

service_name="${1:-}"
[ -n "$service_name" ] || { echo "Usage: docky add-svc <name>" >&2; exit 1; }

stub_file="${STUBS_DIR}/${service_name}.sh"
[ -f "$stub_file" ] || { echo "✗ Stub '${service_name}' not found in ${STUBS_DIR}" >&2; exit 1; }

touch "$SERVICES_CONFIG_FILE"
if ! grep -qw "$service_name" "$SERVICES_CONFIG_FILE"; then
  echo "$service_name" >> "$SERVICES_CONFIG_FILE"
fi

# --- Initial Compose File Generation ---
# If the main compose file doesn't exist yet, run the full generation process.
if [ ! -f "$COMPOSE_OUT_FILE" ]; then
  echo "› Main compose file not found. Running initial generation..."
  source "$DOCKY_HOME/commands/generate.sh"
  exit 0
fi

echo "Reading the service; '${service_name}'..."
# --- Read and Parse Service Definitions ---
# This block reads the null-delimited service and volume YAML blocks
# from the build_stub_docs function. Using read -d is a bash-specific
# feature that correctly handles multi-line strings separated by a null byte.
{
  IFS= read -r -d $'\0' service_yaml
  IFS= read -r -d '' volume_yaml # This reads the rest of the stream
} < <(build_stub_docs "$service_name")


# --- Check if Service Already Exists ---
if compose_has_service "$COMPOSE_OUT_FILE" "$service_name"; then
  echo "› Service '${service_name}' already present in compose."
  exit 0
fi

# --- Merge New Service into Compose File ---
echo "Merging service '${service_name}' into compose file..."
if have_yq; then
  echo "› Using 'yq' for merging."
  merge_with_yq "$COMPOSE_OUT_FILE" "$service_yaml" "$volume_yaml"
else
  merge_without_yq "$COMPOSE_OUT_FILE" "$service_name" "$service_yaml" "$volume_yaml"
fi

echo "✓ Service '${service_name}' successfully merged into docker-compose.yml"
