# shellcheck shell=bash

sub="${1:-}"; shift || true

snippet_php_ini(){
  local name="${1:-custom}"
  name="${name%.ini}"
  local dir="${PROJECT_ROOT}/${PROJ_SNIPPETS_PHP_SUBDIR}"
  mkdir -p "$dir"
  local f="${dir}/${name}.ini"
  if [ -f "$f" ]; then
    warn "exists: ${f#${PROJECT_ROOT}/}"
  else
    cat > "$f" <<EOF
; ${name}.ini — project snippet (auto-mounted by docky)
; examples:
; memory_limit = 1024M
; upload_max_filesize = 128M
EOF
    ok "created ${f#"${PROJECT_ROOT}"/}"
  fi
  { source "$DOCKY_HOME/commands/generate.sh" --no-ask; } >/dev/null || true
  info "mounted at: /usr/local/etc/php/conf.d/${name}.ini"
}

snippet_list(){
  local phpdir="${PROJECT_ROOT}/${PROJ_SNIPPETS_PHP_SUBDIR}"
  echo "snippets root: ${phpdir}"
  if [ -d "$phpdir" ]; then
    echo "php ini:"
    find "$phpdir" -maxdepth 1 -type f -name '*.ini' -printf " - %P\n" 2>/dev/null || true
  else
    echo "php ini: (none)"
  fi
}

case "$sub" in
  php-ini) snippet_php_ini "${1:-custom}" ;;
  ls|list) snippet_list ;;
  *) die "usage: docky snippet {php-ini <name>|list}" ;;
esac