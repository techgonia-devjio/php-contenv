# shellcheck shell=bash

collect_stub_files(){
  # Read stub names from config and pipe through xargs to trim any whitespace.
  mapfile -t _names < <(yq -r '(.stubs // [])[]' "$DOCKY_CONFIG" | xargs -n 1)

  local want=()

  if [ -f "$COMPOSE_OUT" ]; then
    # When a compose file already exists, only process stubs that are NOT 'app'.
    local n
    for n in "${_names[@]}"; do
      if [[ "$n" != "app" ]]; then
        want+=("$n")
      fi
    done
  else
    # This is the first run (no docker-compose.yml exists).
    # Process all stubs defined in the config.
    want=("${_names[@]}")
  fi

  # If the final list is empty (e.g., only 'app' was listed for an existing compose file),
  # this function will correctly return an empty list, which is handled downstream.

  local p n app=() rest=()
  for n in "${want[@]}"; do
    p="${STUBS_DIR}/${n}.yml"
    [ -f "$p" ] || die "stub not found: $p"
    # Ensure 'app' stub is always first in the processing order if it exists.
    if [[ "$n" == "app" ]]; then app+=("$p"); else rest+=("$p"); fi
  done

  printf '%s\n' "${app[@]}" "${rest[@]}"
}

merge_stubs(){
  # If no files are passed, yq will wait on stdin. We must handle this.
  if [ "$#" -eq 0 ]; then
    echo "{}"
    return
  fi
  yq ea -o=yaml '. as $item ireduce ({}; . *+ $item)' "$@"
}

