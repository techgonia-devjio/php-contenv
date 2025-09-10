# shellcheck shell=bash

patch_networks() {
  # Create a temporary directory for all intermediate files
  tmp_dir="$(mktemp -d)"
  # Ensure the temporary directory is removed when the function exits
  trap 'rm -rf "$tmp_dir"' EXIT

  local net
  net="$(yq eval -r '.project.network // "dockynet"' "$DOCKY_CONFIG")"
  echo "DEBUG: Network name is: $net" >&2

  # Step 1: Ensure .services and .networks exist
  yq eval -o=yaml '.services = (.services // {}) | .networks = (.networks // {})' - > "$tmp_dir/step1.yaml"
  if [ $? -ne 0 ]; then echo "ERROR: Step 1 failed." >&2; return 1; fi

  # Step 2: Add the project network definition
  NET="$net" yq eval -o=yaml '.networks[env(NET)] = {"driver":"bridge","name": env(NET)}' "$tmp_dir/step1.yaml" > "$tmp_dir/step2.yaml"
  if [ $? -ne 0 ]; then echo "ERROR: Step 2 failed." >&2; return 1; fi

  # Step 3: Attach the network to all services
  NET="$net" yq eval -o=yaml '.services |= with_entries(.value.networks = ((.value.networks // []) + [env(NET)]))' "$tmp_dir/step2.yaml" > "$tmp_dir/step3.yaml"
  if [ $? -ne 0 ]; then echo "ERROR: Step 3 failed." >&2; return 1; fi
  echo "DEBUG: After Step 3:" >&2

  # Step 4: Remove empty entries and duplicates (in two separate yq calls)
  yq eval -o=yaml '.services |= with_entries(.value.networks |= map(select(. != "")))' "$tmp_dir/step3.yaml" > "$tmp_dir/step4.yaml"
  if [ $? -ne 0 ]; then echo "ERROR: Step 4 failed." >&2; return 1; fi

  # Apply the unique filter on the result of step 4
  yq eval -o=yaml '.services |= with_entries(.value.networks |= unique)' "$tmp_dir/step4.yaml" > "$tmp_dir/final.yaml"
  if [ $? -ne 0 ]; then echo "ERROR: Step 5 failed." >&2; return 1; fi

  echo "DEBUG: After final step:" >&2

  # Print the final output to stdout so the caller can redirect it
  cat "$tmp_dir/final.yaml"
}

patch22_networks2354() {
  # Attach the project network to every service and ensure the network is declared.
  local net; net="$(yq eval -r '.project.network // "dockynet"' "$DOCKY_CONFIG")"
  echo "DEBUG: Network name is: $net" >&2

  # The single, combined yq command
  NET="$net" yq eval -o=yaml '
    .services = (.services // {}) |
    .networks = (.networks // {}) |
    .networks[env(NET)] = {"driver":"bridge","name": env(NET)} |
    .services |= with_entries(
      .value.networks = (
        (.value.networks // []) + [env(NET)]
      ) | map(select(. != "")) | unique
    )
  ' -
}


patch_app_from_config(){
  # Safely layer project-level app config (ports/env/volumes) into services.app
  DOCKY_CFG="$DOCKY_CONFIG" yq eval -o=yaml '
    . as $dc |
    (load(strenv(DOCKY_CFG)) | .app // {}) as $app |
    $dc
    | .services = (.services // {})
    | .services.app = (.services.app // {})
    | .services.app.ports       = ((.services.app.ports       // []) + ($app.ports   // []))
    | .services.app.environment = ((.services.app.environment // {}) *  ($app.env     // {}))
    | .services.app.volumes     = ((.services.app.volumes     // []) + ($app.volumes // []))
  ' -
}

patch_overlays_mount(){
  local names; mapfile -t names < <(yq -r '(.overlays // [])[]' "$DOCKY_CONFIG")
  [ "${#names[@]}" -gt 0 ] || { cat; return 0; }

  local proj_dir_rel; proj_dir_rel="$(yq -r '.vars.DOCKER_PROJECT_OVERLAYS_DIR // ".docker/v2/overlays"' "$DOCKY_CONFIG")"
  local proj_dir_abs="${PROJECT_ROOT}/${proj_dir_rel#./}"
  local sub_dir_abs="${SUBMODULE_DIR}/overlays"

  local sub_dir_rel
  if command -v realpath >/dev/null 2>&1 && realpath --relative-to="$PROJECT_ROOT" "$sub_dir_abs" >/dev/null 2>&1; then
    sub_dir_rel="./$(realpath --relative-to="$PROJECT_ROOT" "$sub_dir_abs")"
  else
    sub_dir_rel=".$(printf '%s' "$sub_dir_abs" | sed "s#^$PROJECT_ROOT##")"
  fi

  local exprs=() odirs=()
  for n in "${names[@]}"; do
    local mount_src=""
    if [ -d "${proj_dir_abs}/$n" ]; then
      mount_src="${proj_dir_rel}/$n"
    elif [ -d "${sub_dir_abs}/$n" ]; then
      mount_src="${sub_dir_rel}/$n"
    else
      continue
    fi
    local mount_dest="/opt/overlay/${n}"
    # Safe: create services/app/volumes if missing
    exprs+=( ".services = (.services // {}) | .services.app = (.services.app // {}) | .services.app.volumes = ((.services.app.volumes // []) + [\"${mount_src}:${mount_dest}:ro\"])")
    odirs+=( "${mount_dest}" )
  done

  if ((${#exprs[@]})); then
    local combined=""
    for e in "${exprs[@]}"; do combined+="${combined:+ | }${e}"; done
    local odirs_join; IFS=: read -r odirs_join <<< "${odirs[*]}"
    yq eval -o=yaml "$combined" - \
    | ODIRS="$odirs_join" yq eval -o=yaml '
        .services = (.services // {}) |
        .services.app = (.services.app // {}) |
        .services.app.environment = ((.services.app.environment // {}) * {"OVERLAY_DIRS": strenv(ODIRS)})
      ' -
  else
    cat
  fi
}

collect_snippet_volume_lines(){
  local phpdir="${PROJECT_ROOT}/${PROJ_SNIPPETS_PHP_SUBDIR}"
  [ -d "$phpdir" ] || return 0
  local f
  for f in "$phpdir"/*.ini; do
    [ -f "$f" ] || continue
    local rel
    if command -v realpath >/dev/null 2>&1 && realpath --relative-to="$PROJECT_ROOT" "$f" >/dev/null 2>&1; then
      rel="./$(realpath --relative-to="$PROJECT_ROOT" "$f")"
    else
      rel=".$(printf '%s' "$f" | sed "s#^$PROJECT_ROOT##")"
    fi
    local dest="/usr/local/etc/php/conf.d/$(basename "$f")"
    printf "%s:%s\n" "$rel" "$dest"
  done
}

patch_snippet_volumes(){
  local lines
  mapfile -t lines < <(collect_snippet_volume_lines || true)
  [ "${#lines[@]}" -gt 0 ] || { cat; return 0; }
  local exprs=() m
  for m in "${lines[@]}"; do
    exprs+=( ".services = (.services // {}) | .services.app = (.services.app // {}) | .services.app.volumes = ((.services.app.volumes // []) + [\"$m\"])")
  done
  local combined=""; for e in "${exprs[@]}"; do combined+="${combined:+ | }${e}"; done
  yq eval -o=yaml "$combined" -
}

patch_extras(){
  DOCKY_CFG="$DOCKY_CONFIG" yq eval -o=yaml '
    . as $dc |
    (load(strenv(DOCKY_CFG)) | .extras // {}) as $ex |
    $dc
    | .services = (.services *+ ($ex.services // {}))
    | .volumes  = (.volumes  *+ ($ex.volumes  // {}))
    | .networks = (.networks *+ ($ex.networks // {}))
  ' -
}

maybe_envsubst_file(){
  local in="$1" out="$2"
  if [[ "${USE_ENVSUBST:-0}" == "1" ]]; then
    have_envsubst || die "envsubst requested but not installed"
    load_dotenv
    local tmp esc
    tmp="$(mktemp)"; esc="$(mktemp)"
    sed -E 's/DOCKY_REPLACE_([A-Z0-9_]+)/DOCKY_KEEP_\1/g' "$in" > "$esc"
    envsubst < "$esc" > "$tmp"
    sed -E 's/DOCKY_KEEP_([A-Z0-9_]+)/DOCKY_REPLACE_\1/g' "$tmp" > "$out"
    rm -f "$tmp" "$esc"
  else
    cp -f "$in" "$out"
  fi
}

# -------- preserve existing compose AND augment app (env/ports/volumes) --------
patch_preserve_existing_services(){
  [ -f "$COMPOSE_OUT" ] || { cat; return 0; }

  EXIST="$COMPOSE_OUT" NET="$(yq -r '.project.network // "dockynet"' "$DOCKY_CONFIG")" yq eval -o=yaml '
    .services = (.services // {}) |
    .networks = (.networks // {}) |
    . as $gen |
    (load(strenv(EXIST)) // {}) as $ex |

    # Merge services: keep existing entries, add new from generated
    .services = (($gen.services // {}) * ($ex.services // {})) |

    # Rebuild app from existing as base, then augment with generated env/ports/volumes
    .services.app = (($ex.services.app // {}) * {}) |
    .services.app.environment =
      ((.services.app.environment // {}) * (($gen.services.app.environment // {}))) |
    .services.app.ports =
      (((.services.app.ports // []) + (($gen.services.app.ports // [])))
       | map(select(. != "")) | unique) |
    .services.app.volumes =
      (((.services.app.volumes // []) + (($gen.services.app.volumes // [])))
       | map(select(. != "")) | unique) |

    # Attach project network to each service, dedupe, drop empties
    .services |= with_entries(
      .value.networks = (
        ((.value.networks // []) + [env(NET)])
        | map(select(. != "")) | unique
      )
    ) |

    # Ensure the project network is declared
    .networks = ((.networks // {}) * { (env(NET)): {"driver":"bridge","name": env(NET)} })
  ' -
}
