#!/command/with-contenv /bin/bash

set -e

OVERLAY_DIRS="${OVERLAY_DIRS:-${OVERLAY_DIR:-/opt/overlay}}"

log() { echo "[overlay] $*"; }

normalize() {
  echo "$1" | tr ':' ' '
}

for ODIR in $(normalize "$OVERLAY_DIRS"); do
  [ -d "$ODIR" ] || { log "skip: $ODIR (missing)"; continue; }

  # php/conf.d
  if [ -d "$ODIR/php/conf.d" ]; then
    for f in "$ODIR"/php/conf.d/*.ini; do
      [ -f "$f" ] || continue
      cp -f "$f" "/usr/local/etc/php/conf.d/$(basename "$f")"
      chmod 644 "/usr/local/etc/php/conf.d/$(basename "$f")" || true
      log "$ODIR: php/conf.d -> $(basename "$f")"
    done
  fi

  # php-fpm pools
  if [ -d /usr/local/etc/php-fpm.d ] && [ -d "$ODIR/php/pool.d" ]; then
    for f in "$ODIR"/php/pool.d/*.conf; do
      [ -f "$f" ] || continue
      cp -f "$f" "/usr/local/etc/php-fpm.d/$(basename "$f")"
      log "$ODIR: php-fpm/pool.d -> $(basename "$f")"
    done
  fi

  # nginx conf.d
  if [ -d /etc/nginx ] && [ -d "$ODIR/nginx/conf.d" ]; then
    for f in "$ODIR"/nginx/conf.d/*.conf; do
      [ -f "$f" ] || continue
      cp -f "$f" "/etc/nginx/conf.d/$(basename "$f")"
      log "$ODIR: nginx/conf.d -> $(basename "$f")"
    done
  fi

  # FrankenPHP (Caddy)
  if command -v caddy >/dev/null 2>&1; then
    [ -f "$ODIR/frankenphp/Caddyfile" ] && {
      cp -f "$ODIR/frankenphp/Caddyfile" /etc/caddy/Caddyfile.custom
      log "$ODIR: frankenphp -> Caddyfile.custom"
    }
    [ -d "$ODIR/frankenphp/snippets" ] && {
      mkdir -p /etc/caddy/snippets
      cp -rf "$ODIR/frankenphp/snippets/." /etc/caddy/snippets/
      log "$ODIR: frankenphp -> snippets"
    }
  fi

  # s6 services
  if [ -d "$ODIR/services.d" ]; then
    for svc in "$ODIR"/services.d/*; do
      [ -d "$svc" ] || continue
      name="$(basename "$svc")"
      rm -rf "/etc/services.d/$name"
      cp -a "$svc" "/etc/services.d/$name"
      find "/etc/services.d/$name" -type f -name run -exec chmod +x {} \; || true
      find "/etc/services.d/$name" -type f -path '*/log/run' -exec chmod +x {} \; || true
      log "$ODIR: services.d -> $name"
    done
  fi

  # extra cont-init hooks
  if [ -d "$ODIR/cont-init.d" ]; then
    for s in "$ODIR"/cont-init.d/*; do
      [ -f "$s" ] || continue
      chmod +x "$s" || true
      log "$ODIR: run cont-init $(basename "$s")"
      "$s"
    done
  fi

  # runtime apt
  if [ -s "$ODIR/apt/packages.txt" ] || [ -n "${EXTRA_APT_PACKAGES:-}" ]; then
    log "$ODIR: installing apt packages (dev only)"
    apt-get update
    [ -s "$ODIR/apt/packages.txt" ] && xargs -a "$ODIR/apt/packages.txt" -r apt-get install -y --no-install-recommends
    [ -n "${EXTRA_APT_PACKAGES:-}" ] && apt-get install -y --no-install-recommends $EXTRA_APT_PACKAGES
    rm -rf /var/lib/apt/lists/*
  fi

  # certs
  if [ -d "$ODIR/certs" ]; then
    mkdir -p /usr/local/share/ca-certificates
    find "$ODIR/certs" -type f -name '*.crt' -exec cp -f {} /usr/local/share/ca-certificates/ \;
    update-ca-certificates || true
    log "$ODIR: CA certificates updated"
  fi

  # removals
  if [ -s "$ODIR/remove/list" ]; then
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      rm -rf "/$rel" && log "$ODIR: removed /$rel" || true
    done < "$ODIR/remove/list"
  fi
done

log "done"
exit 0