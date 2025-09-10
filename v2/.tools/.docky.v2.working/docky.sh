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
  doctor)
    source "$DOCKY_HOME/commands/doctor.sh" "$@"
    ;;
  list-svc|list)
    source "$DOCKY_HOME/commands/list_services.sh" "$@"
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

