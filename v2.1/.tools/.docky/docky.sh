#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # -> .../.tools/.docky
export DOCKY_HOME="$SCRIPT_DIR"

# shellcheck disable=SC1091
source "$DOCKY_HOME/lib/common.sh"

cmd="${1:-help}"; shift || true
case "$cmd" in
  version|-v|--version) echo "docky $DOCKY_VERSION" ;;
  doctor)          source "$DOCKY_HOME/commands/doctor.sh" ;;
  gen|generate)    source "$DOCKY_HOME/commands/generate.sh" "$@" ;;
  add-svc|add-service) source "$DOCKY_HOME/commands/add_service.sh" "${1:-}" ;;
  list-svc|list-services) source "$DOCKY_HOME/commands/list_services.sh" ;;
  snippet)         sub="${1:-}"; shift || true; source "$DOCKY_HOME/commands/snippet.sh" "$sub" "$@" ;;
  config)          sub="${1:-show}"; shift || true; source "$DOCKY_HOME/commands/config.sh" "$sub" "$@" ;;
  open-docs)       source "$DOCKY_HOME/commands/open_docs.sh" ;;
  up|down|ps|logs|exec|run|restart|build|pull) source "$DOCKY_HOME/commands/dc.sh" "$cmd" "$@" ;;
  help|-h|--help|*)

    cat <<'EOF'
docky — v2.6
USAGE
  .docker/v2/docky <command>

COMMANDS
  doctor                          Check dependencies (docker, yq, etc).
  gen [--no-ask] [--envsubst]     Generate docker-compose.yml from stubs.
  add-svc <name>                  Add a service stub to your project's docky.yml.
  list-svc                        List available and enabled service stubs.
  snippet php-ini <name>          Create a custom PHP .ini file snippet.
  snippet list                    List active project snippets.
  config show|set|reset           Manage saved answers in .docky.answers.yml.
  open-docs                       Serve documentation locally (mkdocs).
  up|down|ps|logs|...             Pass-through to 'docker compose'.

NOTES
- Config: Uses 'docky.yml' in your project root if it exists, otherwise
  falls back to the default one in the submodule.
- Answers: Choices from 'gen' saved in '.docky.answers.yml' in project root.
- Overlays: Project-level overlays in '.docker/overlays/' override same-named
  overlays from the submodule.
EOF
    ;;
 esac