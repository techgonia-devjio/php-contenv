#!/usr/bin/env bash


info "--- Available Service Stubs ---"
# List all .sh files in the stubs directory and remove the extension
ls -1 "$STUBS_DIR" | sed 's/\.sh$//' | sed 's/^/  - /'

echo ""
info "--- Enabled Services (.docker-services) ---"
if [ -f "$SERVICES_CONFIG_FILE" ] && [ -s "$SERVICES_CONFIG_FILE" ]; then
    cat "$SERVICES_CONFIG_FILE" | sed 's/^/  - /'
else
    log "  (None. Run 'docky add-svc <name>' to enable a service)"
fi
