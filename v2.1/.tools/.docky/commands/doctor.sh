# shellcheck shell=bash

need docker
if ! docker compose version >/dev/null 2>&1; then die "Docker Compose v2 not found (need 'docker compose')."; fi
ok "docker: $(docker --version | cut -d' ' -f3- | sed 's/,//')"
ok "compose: $(docker compose version | head -n1)"
need yq
yq --version | grep -q 'version v4\.' || warn "yq v4 strongly recommended; found: $(yq --version)"
if have_envsubst; then ok "envsubst present"; else warn "envsubst not found; --envsubst will be unavailable"; fi
[ -f "$DOCKY_CONFIG" ] || die "config not found: $DOCKY_CONFIG"
ok "using config: ${DOCKY_CONFIG#$PROJECT_ROOT/}"
[ -d "$STUBS_DIR" ] || die "stubs dir missing: $STUBS_DIR"
ok "doctor looks good."