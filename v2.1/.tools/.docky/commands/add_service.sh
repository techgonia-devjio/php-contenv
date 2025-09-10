# shellcheck shell=bash

name="${1:-}"; [ -n "$name" ] || die "usage: docky add-svc <name>"
[ -f "${STUBS_DIR}/${name}.yml" ] || die "stub not found: ${STUBS_DIR}/${name}.yml"

proj_config="${PROJECT_DOCKY_YML_FILE:-$PROJECT_ROOT/${PROJ_SNIPPETS_DIR:-.docker-snippets}/docky.yml}"

# Bootstrap a project-level config as APP-ONLY baseline (opt-in for extra services)
if [ ! -f "$proj_config" ]; then
  info "creating project-level docky.yml from submodule default (app-only)"
  cp -f "${SUBMODULE_DIR}/docky.yml" "$proj_config"
  # force app-only list and drop any submodule defaults that add services implicitly
  yq -i '.stubs = ["app"]' "$proj_config"
  DOCKY_CONFIG="$proj_config"
fi

# Ensure .stubs exists
if ! yq -e '.stubs' "$proj_config" >/dev/null 2>&1; then
  yq -i '.stubs = ["app"]' "$proj_config"
fi

# Append requested service if not present
if yq -e ".stubs | contains([\"$name\"])" "$proj_config" >/dev/null; then
  info "service '$name' is already in the stubs list of ${proj_config#$PROJECT_ROOT/}"
else
  yq -i ".stubs += [\"$name\"]" "$proj_config"
  ok "added '$name' to stubs list in ${proj_config#$PROJECT_ROOT/}"
fi

# Regenerate compose
info "regenerating docker-compose.yml..."
source "${DOCKY_HOME:-$ROOT_DIR}/commands/generate.sh" --no-ask
