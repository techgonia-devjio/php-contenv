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

