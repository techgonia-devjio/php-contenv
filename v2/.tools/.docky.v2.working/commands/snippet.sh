#!/usr/bin/env bash
set -euo pipefail

sub_command="${1:-help}"
snippet_name="${2:-custom}"

SNIPPETS_DIR="${PROJECT_ROOT}/.docker-snippets"

case "$sub_command" in
    php-ini)
        ini_name="${snippet_name%.ini}"
        ini_dir="${SNIPPETS_DIR}/php"
        mkdir -p "$ini_dir"
        ini_file="${ini_dir}/${ini_name}.ini"

        if [ -f "$ini_file" ]; then
            echo "⚠ Snippet already exists: ${ini_file#${PROJECT_ROOT}/}"
        else
            cat > "$ini_file" <<EOF
; ${ini_name}.ini — project snippet
; This file can be mounted into your container.
; Example volume mount in docker-compose.yml:
; - ./.docker-snippets/php/${ini_name}.ini:/usr/local/etc/php/conf.d/99-${ini_name}.ini:ro

memory_limit = 512M
upload_max_filesize = 128M
EOF
            echo "✓ Created snippet: ${ini_file#${PROJECT_ROOT}/}"
            echo "› You must now manually add the volume mount to your app service in the compose file."
        fi
        ;;
    list)
        echo "--- Project Snippets in ${SNIPPETS_DIR#${PROJECT_ROOT}/} ---"
        if [ -d "$SNIPPETS_DIR" ]; then
            find "$SNIPPETS_DIR" -type f -print | sed "s|^${PROJECT_ROOT}/|  - |"
        else
            echo "  (No snippets directory found)"
        fi
        ;;
    *)
        echo "Usage: docky snippet <command> [name]"
        echo ""
        echo "Commands:"
        echo "  php-ini [name]   Create a custom PHP .ini file snippet (default name: custom)."
        echo "  list             List all existing snippets."
        ;;
esac
