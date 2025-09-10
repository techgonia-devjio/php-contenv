# shellcheck shell=bash


ans_get(){
  local key="$1"
  [ -f "$ANSWERS_FILE" ] || { echo ""; return 0; }
  yq -r ".[\"$key\"] // \"\"" "$ANSWERS_FILE"
}


ans_set(){
  local key="$1" val="$2"
  if [ ! -f "$ANSWERS_FILE" ]; then
    printf "{}\n" > "$ANSWERS_FILE"
  fi
  yq -i ".[\"$key\"] = \"$val\"" "$ANSWERS_FILE"
}


ans_show(){
  if [ -f "$ANSWERS_FILE" ]; then
    echo "# ${ANSWERS_FILE#${PROJECT_ROOT}/}"
    cat "$ANSWERS_FILE"
  else
    echo "(no answers saved yet)"
  fi
}


ans_reset(){
  rm -f "$ANSWERS_FILE"
  ok "cleared ${ANSWERS_FILE#${PROJECT_ROOT}/}"
}