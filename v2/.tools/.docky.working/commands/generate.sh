#!/usr/bin/env bash
set -euo pipefail

force=0
[ "${1:-}" = "--force" ] && force=1

# Ensure helper vars/files exist
touch "${ENV_FILE}" "${SERVICES_CONFIG_FILE}"

# Ensure at least 'app' is enabled by adding it to the top of the list if absent.
if ! grep -qw "app" "${SERVICES_CONFIG_FILE}"; then
  # Create a temporary file to preserve existing services
  tmp_svcs=$(mktemp)
  echo "app" > "$tmp_svcs"
  cat "${SERVICES_CONFIG_FILE}" >> "$tmp_svcs"
  mv "$tmp_svcs" "${SERVICES_CONFIG_FILE}"
fi

# Base prompts (only populate if empty)
prompt_for_var "APP_NAME"    "Enter your application name" "docky_app"
prompt_for_var "APP_PORT"    "Enter the web port to expose on your host" "8081"
prompt_for_var "PHP_VERSION" "Enter PHP version (8.4, 8.3, 8.2, 8.1)" "8.4"
prompt_for_var "WEBSERVER"   "Enter webserver (nginx, apache, frankenphp)" "nginx"
prompt_for_var "NETWORK_NAME" "Enter Docker network name" "mainnet"

# Safeguard existing compose unless --force is used
if [ -f "${COMPOSE_OUT_FILE}" ] && [ $force -eq 0 ]; then
  echo "› ${COMPOSE_OUT_FILE#${PROJECT_ROOT}/} already exists. Use 'docky gen --force' to overwrite."
  exit 0
fi

# Backup if overwriting an existing file
if [ -f "${COMPOSE_OUT_FILE}" ] && [ $force -eq 1 ]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  bak_file="${COMPOSE_OUT_FILE}.${ts}.bak"
  cp "${COMPOSE_OUT_FILE}" "$bak_file"
  echo "› Backed up existing compose file to ${bak_file#${PROJECT_ROOT}/}"
fi

# Assemble services/volumes from all stubs listed in the services config file
echo "Assembling new docker-compose.yml..."
services_yaml=""
volumes_yaml=""

while IFS= read -r svc || [ -n "$svc" ]; do
  [ -z "$svc" ] && continue
  echo "› Assembling service: ${svc}..."

  # Use a robust read method. The `|| true` ensures that the command
  # doesn't fail when a service has no volumes, which would cause `set -e` to exit.
  svc_yaml=""
  vol_yaml=""
  if ! { IFS= read -r -d $'\0' svc_yaml && { IFS= read -r -d '' vol_yaml || true; }; } < <(build_stub_docs "$svc"); then
      echo "✗ Warning: Failed to read definition for service '${svc}'. Skipping." >&2
      continue
  fi

  if [ -n "${svc_yaml}" ]; then
    # Append with a newline separator ONLY if the variable is not already empty
    services_yaml="${services_yaml}${services_yaml:+$'\n'}${svc_yaml}"
  fi
  if [ -n "${vol_yaml}" ]; then
    # Append with a newline separator ONLY if the variable is not already empty
    volumes_yaml="${volumes_yaml}${volumes_yaml:+$'\n'}${vol_yaml}"
  fi
done < "${SERVICES_CONFIG_FILE}"

# After the loop, ensure at least one service was successfully assembled.
if [ -z "${services_yaml}" ]; then
  echo "✗ Error: No services could be assembled. Aborting generation." >&2
  exit 1
fi

# Write the new compose file atomically to prevent corruption
tmp="$(mktemp)"
{
  echo "services:"
  # Print services. No need to strip a leading newline anymore.
  if [ -n "${services_yaml}" ]; then
    printf '%s\n' "${services_yaml}"
  fi

  # Only add the volumes section if there are actually volumes defined.
  if [ -n "${volumes_yaml}" ]; then
    echo ""
    echo "volumes:"
    printf '%s\n' "${volumes_yaml}"
  fi

  echo ""
  # Add the default network configuration
  cat <<EOF
networks:
  ${NETWORK_NAME}:
    driver: bridge
    name: ${NETWORK_NAME}
EOF
} > "$tmp"

mv "$tmp" "${COMPOSE_OUT_FILE}"
echo "✓ Wrote ${COMPOSE_OUT_FILE#${PROJECT_ROOT}/}"

