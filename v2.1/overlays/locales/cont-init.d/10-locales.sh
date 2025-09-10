#!/command/with-contenv /bin/bash
set -euo pipefail

# Configure via env:
#   LOCALES="de_DE.UTF-8 en_GB.UTF-8 es_ES.UTF-8 it_IT.UTF-8 nl_NL.UTF-8 pt_BR.UTF-8 sv_SE.UTF-8"
#   DEFAULT_LOCALE="en_GB.UTF-8"
LOCALES_STR="${LOCALES:-en_US.UTF-8}"
DEFAULT_LOCALE="${DEFAULT_LOCALE:-en_US.UTF-8}"

echo "[locales] enabling: $LOCALES_STR (default: $DEFAULT_LOCALE)"

# Ensure lines exist in /etc/locale.gen (idempotent)
for loc in $LOCALES_STR; do
  pat="$(printf '%s UTF-8' "$loc")"
  if ! grep -qE "^${loc}[[:space:]]+UTF-8$" /etc/locale.gen 2>/dev/null; then
    echo "$pat" >> /etc/locale.gen
  fi
done

# Generate locales
locale-gen

# Persist default
if command -v update-locale >/dev/null 2>&1; then
  update-locale LANG="$DEFAULT_LOCALE" LC_ALL="$DEFAULT_LOCALE"
fi

# Also export for the running process tree
export LANG="$DEFAULT_LOCALE"
export LC_ALL="$DEFAULT_LOCALE"
