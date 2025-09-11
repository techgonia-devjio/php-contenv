#!/usr/bin/env bash


info "--- Available Service Stubs ---"
# List all .sh files in the stubs directory and remove the extension
ls -1 "$STUBS_DIR" | sed 's/\.sh$//' | sed 's/^/  - /'

echo ""
log "(Run 'docky add-svc <name>' to enable a service)"

