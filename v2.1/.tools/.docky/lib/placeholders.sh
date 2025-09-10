# shellcheck shell=bash

collect_placeholders(){
  local file="$1"
  grep -oE '\$\{?DOCKY_REPLACE_[A-Z0-9_]+\}?' "$file" | sed 's/[${}]//g' | sort -u || true
}

option_list_for(){
  local base="$1"
  yq -r "((.OPTIONS.$base // .OPTIONS.${base}s // .OPTIONS.${base}S // [])[])" "$DOCKY_CONFIG"
}

default_for(){
  yq -r ".vars.$1 // []" "$DOCKY_CONFIG"
}

prompt_choice(){
  local key="$1" base="${1#DOCKY_REPLACE_}" def="$2"
  shift 2
  local opts=("$@")
  echo
  echo "⚙  $base"
  if ((${#opts[@]})); then
    echo "   available:"
    local i=1
    for o in "${opts[@]}"; do printf "    %d) %s\n" "$i" "$o"; ((i++)); done
    echo -n "   pick [1-${#opts[@]}] or type a value"
    [ -n "$def" ] && echo -n " (default: $def)"
    echo -n ": "
    read -r ans || true
    if [[ -z "$ans" && -n "$def" ]]; then
      echo "$def"
    elif [[ "$ans" =~ ^[0-9]+$ ]] && (( ans>=1 && ans<=${#opts[@]} )); then
      echo "${opts[ans-1]}"
    else
      echo "$ans"
    fi
  else
    echo -n "   value"
    [ -n "$def" ] && echo -n " (default: $def)"
    echo -n ": "
    read -r ans || true
    echo "${ans:-$def}"
  fi
}

resolve_placeholders(){
  local in="$1" out="$2" ask="${3:-1}"
  local tmp_in; tmp_in="$(mktemp)"; cp "$in" "$tmp_in"

  local keys; mapfile -t keys < <(collect_placeholders "$tmp_in" || true)
  [ "${#keys[@]}" -gt 0 ] || { cp -f "$tmp_in" "$out"; rm "$tmp_in"; return 0; }

  local k base def val opts
  for k in "${keys[@]}"; do
    base="${k#DOCKY_REPLACE_}"
    val="$(ans_get "$k")"
    [ -z "$val" ] && val="${!base:-}"
    mapfile -t opts < <(option_list_for "$base" || true)
    if [ -z "$val" ]; then
      def="$(default_for "$base")"
      if [[ "$ask" == "1" ]] && is_tty; then
        val="$(prompt_choice "$k" "$def" "${opts[@]}")"
      else
        val="${def:-${opts[0]:-}}"
      fi
    fi
    ans_set "$k" "$val"
    export "$k"="$val"
  done

  local norm; norm="$(mktemp)"
  sed -E 's/\$([A-Z0-9_]+)/${\1}/g' "$tmp_in" > "$norm"

  local vlist; vlist="$(printf ' ${%s}' "${keys[@]}")"
  envsubst "$vlist" < "$norm" > "$out"

  rm -f "$tmp_in" "$norm"
}

resolve_placeholders23(){
  local in="$1" out="$2" ask="${3:-1}"
  local tmp_in; tmp_in="$(mktemp)"; cp "$in" "$tmp_in"

  # 1) collect keys
  local keys; mapfile -t keys < <(collect_placeholders "$tmp_in" || true)
  [ "${#keys[@]}" -gt 0 ] || { cp -f "$tmp_in" "$out"; rm "$tmp_in"; return 0; }

  # 2) pick values (same as your current logic)
  local k base def val opts
  for k in "${keys[@]}"; do
    base="${k#DOCKY_REPLACE_}"
    val="$(ans_get "$k")"
    [ -z "$val" ] && val="${!base:-}"
    mapfile -t opts < <(option_list_for "$base" || true)
    if [ -z "$val" ]; then
      def="$(default_for "$base")"
      if [[ "$ask" == "1" ]] && is_tty; then
        val="$(prompt_choice "$k" "$def" "${opts[@]}")"
      else
        val="${def:-${opts[0]:-}}"
      fi
    fi
    ans_set "$k" "$val"
    export "$k"="$val"
  done

  # 3) normalize $VAR -> ${VAR} so envsubst catches both forms
  local norm; norm="$(mktemp)"
  sed -E 's/\$([A-Z0-9_]+)/${\1}/g' "$tmp_in" > "$norm"

  # 4) build a whitelist for envsubst and substitute
  local vlist; vlist="$(printf ' ${%s}' "${keys[@]}")"
  envsubst "$vlist" < "$norm" > "$out"

  rm -f "$tmp_in" "$norm"
}
