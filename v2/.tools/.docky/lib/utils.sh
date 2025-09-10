#!/usr/bin/env bash

# -------- tty / colors --------
_is_tty() { [[ -t 1 ]]; }
if _is_tty; then
  _C_BOLD="$(printf '\033[1m')"; _C_DIM="$(printf '\033[2m')"
  _C_RED="$(printf '\033[31m')"; _C_YEL="$(printf '\033[33m')"
  _C_CYN="$(printf '\033[36m')"; _C_GRN="$(printf '\033[32m')"
  _C_RST="$(printf '\033[0m')"
else
  _C_BOLD=""; _C_DIM=""; _C_RED=""; _C_YEL=""; _C_CYN=""; _C_GRN=""; _C_RST=""
fi

# -------- logging --------
log()   { printf "%s%s%s\n" "${_C_DIM}" "$*" "${_C_RST}" 1>&2; }
info()  { printf "%s%s%s\n" "${_C_CYN}" "$*" "${_C_RST}" 1>&2; }
good()  { printf "%s%s%s\n" "${_C_GRN}" "$*" "${_C_RST}" 1>&2; }
warn()  { printf "%s%s%s\n" "${_C_YEL}" "$*" "${_C_RST}" 1>&2; }
error() { printf "%s%s%s\n" "${_C_RED}${_C_BOLD}" "$*" "${_C_RST}" 1>&2; }
die() { error "$@"; exit 1; }

# -------- yq detection (mikefarah v4) --------
have_yq() {
  [ "${DOCKY_FORCE_NO_YQ:-0}" = "1" ] && return 1
  command -v yq >/dev/null 2>&1 || return 1
  local v; v="$(yq --version 2>&1 || true)"
  # Check for 'mikefarah' and a version number starting with 'v' or a space, followed by '4.'
  echo "$v" | grep -qi 'mikefarah' || return 1
  echo "$v" | grep -qE '[v ]4\.' || return 1
  return 0
}

# -------- cache helpers --------
_cache_get() {
  local key="$1" line
  [ -f "${DOCKY_CACHE_FILE}" ] || return 1
  line="$(grep -E "^${key}=" "${DOCKY_CACHE_FILE}" 2>/dev/null || true)"
  [ -n "${line}" ] || return 1
  printf "%s" "${line#${key}=}"
}

_cache_set() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "${DOCKY_CACHE_FILE}")"
  touch "${DOCKY_CACHE_FILE}"
  if grep -qE "^${key}=" "${DOCKY_CACHE_FILE}" 2>/dev/null; then
    tmp="$(mktemp)"; sed -E "s|^${key}=.*|${key}=${val}|" "${DOCKY_CACHE_FILE}" > "$tmp" && mv "$tmp" "${DOCKY_CACHE_FILE}"
  else
    printf "%s=%s\n" "${key}" "${val}" >> "${DOCKY_CACHE_FILE}"
  fi
}

# -------- prompting --------
prompt_for_var() {
  local var_name="$1" prompt_text="$2" def="${3:-}"
  local cached input value
  cached="$(_cache_get "${var_name}" || true)"
  local shown_default="${cached:-$def}"
  printf "› %s %s(default: %s)%s: " "${prompt_text}" "${_C_DIM}" "${shown_default}" "${_C_RST}" > /dev/tty
  IFS= read -r input < /dev/tty || input=""
  value="${input:-$shown_default}"
  export "${var_name}"="${value}"
  _cache_set "${var_name}" "${value}"
}



esc_sed() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
export -f esc_sed