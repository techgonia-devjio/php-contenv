# shellcheck shell=bash

need(){ command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

yq_raw(){ yq -r "$1" "$2"; }

have_envsubst(){ command -v envsubst >/dev/null 2>&1; }

is_tty(){ [[ -t 0 ]] && [[ -t 1 ]]; }

load_dotenv(){
  local envf="${PROJECT_ROOT}/.env"
  [ -f "$envf" ] || return 0
  set -a
  # shellcheck disable=SC1090
  . "$envf"
  set +a
}
# Add visibility for new helpers
export -f relpath || true