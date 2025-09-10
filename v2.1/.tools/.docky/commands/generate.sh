# shellcheck shell=bash

USE_ENVSUBST=0; ASK=1

for m in "$@"; do
  case "$m" in
    --envsubst) USE_ENVSUBST=1 ;;
    --no-ask)   ASK=0 ;;
  esac
done

# doctor (non-fatal)
if [ -f "$DOCKY_HOME/commands/doctor.sh" ]; then
  { source "$DOCKY_HOME/commands/doctor.sh"; } >/dev/null || true
elif [ -f "$SUBMODULE_DIR/.tools/.docky/commands/doctor.sh" ]; then
  { source "$SUBMODULE_DIR/.tools/.docky/commands/doctor.sh"; } >/dev/null || true
fi

mapfile -t files < <(collect_stub_files)
if [ -f "$COMPOSE_OUT" ]; then
  info "merge (non-app overlays only): $(printf '%s ' "${files[@]//$PROJECT_ROOT\//}")"
else
  info "fresh mode (app-only unless project overrides): $(printf '%s ' "${files[@]//$PROJECT_ROOT\//}")"
fi

tmp_merged="$(mktemp)"
if [ "${#files[@]}" -eq 0 ]; then
  printf '{}' > "$tmp_merged"
else
  merge_stubs "${files[@]}" > "$tmp_merged"
fi

t1="$(mktemp)"; t2="$(mktemp)"; t3="$(mktemp)"; t4="$(mktemp)"; t5="$(mktemp)"; t6="$(mktemp)"; t7="$(mktemp)"

patch_networks < "$tmp_merged" > "$t1"
echo "Network patched"
patch_app_from_config < "$t1"        > "$t2"
echo "App from config patched"
patch_overlays_mount  < "$t2"        > "$t3"
echo "Overlays mount patched"
patch_snippet_volumes < "$t3"        > "$t4"
echo "Snippet volumes patched"
patch_extras          < "$t4"        > "$t5"
echo "Extras patched"
patch_preserve_existing_services < "$t5" > "$t6"
echo "Existing services preserved"

resolve_placeholders "$t6" "$t7" "$ASK"
maybe_envsubst_file   "$t7" "$COMPOSE_OUT"

rm -f "$tmp_merged" "$t1" "$t2" "$t3" "$t4" "$t5" "$t6" "$t7"
ok "wrote ${COMPOSE_OUT#${PROJECT_ROOT}/}"
info "services:"; yq -r '.services | keys | .[]' "$COMPOSE_OUT" | sed 's/^/ - /'
