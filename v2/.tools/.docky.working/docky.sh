#!/usr/bin/env bash


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
  rm-svc|remove-svc)
    source "$DOCKY_HOME/commands/remove_service.sh" "$@"
    ;;
  list-svc)
    echo "--- Available Service Stubs ---"
    ls -1 "$STUBS_DIR" | sed -n 's/\.sh$//p' | sed 's/^/  - /'
    echo ""
    echo "--- Enabled Services (.docker-services) ---"
    if [ -s "$SERVICES_CONFIG_FILE" ]; then
      sed 's/^/  - /' "$SERVICES_CONFIG_FILE"
    else
      echo "  (none)"
    fi
    ;;
  up|down|ps|logs|exec|build|pull|restart)
    docker compose "$cmd" "$@"
    ;;
  *)
    cat <<EOF
docky — Docker helper

Usage:
  docky gen                 Create/refresh docker-compose.yml (merge, non-destructive)
  docky add-svc <name>      Enable a stub and merge into compose
  docky rm-svc <name>       Disable a stub and remove from compose (best-effort)
  docky list-svc            List available/enabled services
  docky [up|down|logs|...]  Pass-through to docker compose
EOF
    ;;
esac
