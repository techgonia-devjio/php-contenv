#!/usr/bin/env bash

info "--- Running Docky Doctor ---"
ok=1

# --- Check 1: Core Dependencies ---
info "› Checking for core dependencies..."
command -v docker >/dev/null 2>&1 && good "  ✓ docker found" || { error "  ✗ docker not found"; ok=0; }
if have_yq; then
  good "  ✓ yq (v4, mikefarah) found"
else
  warn "  ! yq (v4, mikefarah) not found. Will use less reliable awk merger."
  info "    (See https://github.com/mikefarah/yq for installation)"
fi

# --- Check 2: Paths and Permissions ---
info "› Checking paths and permissions..."
[ -d "${DOCKY_HOME}" ] && good "  ✓ DOCKY_HOME is valid: ${DOCKY_HOME}" || { error "  ✗ DOCKY_HOME is not a valid directory"; ok=0; }
[ -d "${STUBS_DIR}" ] && good "  ✓ STUBS_DIR is valid: ${STUBS_DIR}" || { error "  ✗ STUBS_DIR is not a valid directory"; ok=0; }
[ -w "$(dirname "${DOCKY_CACHE_FILE}")" ] && good "  ✓ Cache directory is writable." || { error "  ✗ Cache directory is not writable: $(dirname "${DOCKY_CACHE_FILE}")"; ok=0; }
[ -x "${DOCKY_HOME}/docky.sh" ] && good "  ✓ docky.sh is executable." || { warn "  ! docky.sh is not executable (run 'chmod +x .docker/v2/docky')"; }


# --- Check 3: Stub File Integrity ---
info "› Validating service stubs..."
for stub in "${STUBS_DIR}"/*.sh; do
  svc_name=$(basename -s .sh "$stub")
  info "  - Checking stub: ${svc_name}"
  ( # Run in a subshell to avoid polluting the main script
    source "$stub"
    [ "$(type -t get_variables)" = "function" ] && good "    ✓ Found get_variables()" || { error "    ✗ Missing get_variables() function"; ok=0; }
    [ "$(type -t get_service_template)" = "function" ] && good "    ✓ Found get_service_template()" || { error "    ✗ Missing get_service_template() function"; ok=0; }
    [ "$(type -t get_volumes_template)" = "function" ] && good "    ✓ Found get_volumes_template()" || { error "    ✗ Missing get_volumes_template() function"; ok=0; }
  )
done

#if command -v docker >/dev/null 2>&1; then
#  info "› Rendering stubs (smoke test)..."
#  for stub in "${STUBS_DIR}"/*.sh; do
#    svc_name="$(basename -s .sh "$stub")"
#    IFS=$'\0' read -r svc_yaml vol_yaml < <(build_stub_docs "$svc_name")
#    tmp="$(mktemp)"
#    {
#      echo "version: '3.8'"
#      echo "services:"
#      printf '%s\n' "${svc_yaml:-{} }"
#      [ -n "$vol_yaml" ] && { echo "volumes:"; printf '%s\n' "$vol_yaml"; }
#    } > "$tmp"
#    if docker compose -f "$tmp" config -q >/dev/null 2>&1; then
#      good "  ✓ ${svc_name} renders valid YAML"
#    else
#      warn "  ✗ ${svc_name} rendered YAML not valid"
#      ok=0
#    fi
#    rm -f "$tmp"
#  done
#fi

echo ""
if [ "$ok" -eq 1 ]; then
  good "✓ Docky setup looks good!"
else
  error "✗ Docky setup has issues. Please review the errors above."
  exit 1
fi
