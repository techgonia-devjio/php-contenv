# shellcheck shell=bash

echo "—— Available Stubs (from submodule) ——"
( cd "$STUBS_DIR" && ls -1 *.yml 2>/dev/null | sed 's/\.yml$//' | sed 's/^/ - /' ) || echo " (none)"
echo
echo "—— Enabled Stubs (from ${DOCKY_CONFIG#$PROJECT_ROOT/}) ——"
yq -r '(.stubs // [])[]' "$DOCKY_CONFIG" 2>/dev/null | sed 's/^/ - /' || echo " (none)"
echo
echo "—— Final Services (in ${COMPOSE_OUT#$PROJECT_ROOT/}) ——"
if [ -f "$COMPOSE_OUT" ]; then
  yq -r '.services | keys | .[]' "$COMPOSE_OUT" | sed 's/^/ - /'
else
  echo " (compose not generated yet; run: bin/docky gen)"
fi