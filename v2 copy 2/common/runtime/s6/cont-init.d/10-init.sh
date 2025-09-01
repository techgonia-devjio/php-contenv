#!/command/with-contenv bash
set -euo pipefail
echo "cont-init:v3 map www-data to host PUID/PGID and fix perms"

if [[ -n "${PUID:-}" ]]; then
  cu="$(id -u www-data)"; [[ "$cu" != "$PUID" ]] && usermod -o -u "$PUID" www-data
fi
if [[ -n "${PGID:-}" ]]; then
  cg="$(id -g www-data)"; [[ "$cg" != "$PGID" ]] && groupmod -o -g "$PGID" www-data
fi

for d in /var/www/html/storage /var/www/html/bootstrap/cache; do
  [[ -d "$d" ]] || continue
  chown -R www-data:www-data "$d" || true
  chmod -R ug+rwX "$d" || true
done

[[ "${ENABLE_QUEUE_WORKER:-false}" = "true" ]] || rm -rf /etc/services.d/queue-worker || true
echo "cont-init:v3 done"