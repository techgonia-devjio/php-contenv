#!/command/with-contenv /bin/bash

set -euo pipefail
echo "cont-init:v4 map www-data to host PUID/PGID, fix perms, setup history"

# map IDs
if [[ -n "${PUID:-}" ]]; then
  cu="$(id -u www-data)"; [[ "$cu" != "$PUID" ]] && usermod -o -u "$PUID" www-data
fi
if [[ -n "${PGID:-}" ]]; then
  cg="$(id -g www-data)"; [[ "$cg" != "$PGID" ]] && groupmod -o -g "$PGID" www-data
fi

# writable dirs
for d in /var/www/html/storage /var/www/html/bootstrap/cache; do
  [[ -d "$d" ]] || continue
  chown -R www-data:www-data "$d" || true
  chmod -R ug+rwX "$d" || true
done

# per-project persistent bash history (within bind-mounted workspace)
HISTDIR="/var/www/html/.container-history"
mkdir -p "$HISTDIR"
chown -R "${PUID:-33}:${PGID:-33}" "$HISTDIR" || true
ln -sf "$HISTDIR/bash_history" /root/.bash_history
if [[ -d /var/www ]]; then ln -sf "$HISTDIR/bash_history" /var/www/.bash_history || true; fi

# auto-load history profile for interactive shells
if ! grep -q 'zz-history.sh' /etc/bash.bashrc 2>/dev/null; then
  echo '[ -r /etc/profile.d/zz-history.sh ] && . /etc/profile.d/zz-history.sh' >> /etc/bash.bashrc
fi

# disable queue worker unless enabled
[[ "${ENABLE_QUEUE_WORKER:-false}" = "true" ]] || rm -rf /etc/services.d/queue-worker || true

echo "cont-init:v4 done"
