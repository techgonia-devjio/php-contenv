#!/command/with-contenv /bin/bash

set -e

OVERLAY_DIR="${OVERLAY_DIR:-/opt/overlay}"
log() { echo "[overlay] $*"; }

[ -d "$OVERLAY_DIR" ] || { log "no overlay at $OVERLAY_DIR"; exit 0; }

# ---------- PHP conf.d overrides ----------
if [ -d "$OVERLAY_DIR/php/conf.d" ]; then
  for f in "$OVERLAY_DIR"/php/conf.d/*.ini; do
    [ -f "$f" ] || continue
    dst="/usr/local/etc/php/conf.d/$(basename "$f")"
    cp -f "$f" "$dst"
    chmod 644 "$dst" || true
    log "php/conf.d -> $(basename "$f")"
  done
fi

# ---------- PHP-FPM pool overrides (if FPM present) ----------
if [ -d /usr/local/etc/php-fpm.d ] && [ -d "$OVERLAY_DIR/php/pool.d" ]; then
  for f in "$OVERLAY_DIR"/php/pool.d/*.conf; do
    [ -f "$f" ] || continue
    cp -f "$f" "/usr/local/etc/php-fpm.d/$(basename "$f")"
    log "php-fpm/pool.d -> $(basename "$f")"
  done
fi

# ---------- Nginx conf.d overrides (if Nginx present) ----------
if [ -d /etc/nginx ] && [ -d "$OVERLAY_DIR/nginx/conf.d" ]; then
  for f in "$OVERLAY_DIR"/nginx/conf.d/*.conf; do
    [ -f "$f" ] || continue
    cp -f "$f" "/etc/nginx/conf.d/$(basename "$f")"
    log "nginx/conf.d -> $(basename "$f")"
  done
fi

# ---------- FrankenPHP / Caddy overrides (if present) ----------
if command -v caddy >/dev/null 2>&1; then
  [ -f "$OVERLAY_DIR/frankenphp/Caddyfile" ] && {
    cp -f "$OVERLAY_DIR/frankenphp/Caddyfile" /etc/caddy/Caddyfile.custom
    log "frankenphp: Caddyfile.custom installed"
  }
  [ -d "$OVERLAY_DIR/frankenphp/snippets" ] && {
    mkdir -p /etc/caddy/snippets
    cp -rf "$OVERLAY_DIR/frankenphp/snippets/." /etc/caddy/snippets/
    log "frankenphp: snippets installed"
  }
fi

# ---------- s6 services (add or override) ----------
if [ -d "$OVERLAY_DIR/services.d" ]; then
  for svc in "$OVERLAY_DIR"/services.d/*; do
    [ -d "$svc" ] || continue
    name="$(basename "$svc")"
    rm -rf "/etc/services.d/$name"
    cp -a "$svc" "/etc/services.d/$name"
    find "/etc/services.d/$name" -type f -name run -exec chmod +x {} \; || true
    find "/etc/services.d/$name" -type f -path '*/log/run' -exec chmod +x {} \; || true
    log "services.d -> $name"
  done
fi

# ---------- extra cont-init steps (run after base init) ----------
if [ -d "$OVERLAY_DIR/cont-init.d" ]; then
  for s in "$OVERLAY_DIR"/cont-init.d/*; do
    [ -f "$s" ] || continue
    chmod +x "$s" || true
    log "running cont-init: $(basename "$s")"
    "$s"
  done
fi

# ---------- runtime apt installs (dev-friendly) ----------
# Also honors EXTRA_APT_PACKAGES="git jq ..."
if [ -s "$OVERLAY_DIR/apt/packages.txt" ] || [ -n "${EXTRA_APT_PACKAGES:-}" ]; then
  log "installing apt packages from overlay (dev/use with care)"
  apt-get update
  if [ -s "$OVERLAY_DIR/apt/packages.txt" ]; then
    xargs -a "$OVERLAY_DIR/apt/packages.txt" -r apt-get install -y --no-install-recommends
  fi
  if [ -n "${EXTRA_APT_PACKAGES:-}" ]; then
    # shellcheck disable=SC2086
    apt-get install -y --no-install-recommends $EXTRA_APT_PACKAGES
  fi
  rm -rf /var/lib/apt/lists/*
fi

# ---------- CA certs ----------
if [ -d "$OVERLAY_DIR/certs" ]; then
  mkdir -p /usr/local/share/ca-certificates
  find "$OVERLAY_DIR/certs" -type f -name '*.crt' -exec cp -f {} /usr/local/share/ca-certificates/ \;
  update-ca-certificates || true
  log "CA certificates updated"
fi

# ---------- deletions (power tool) ----------
# Put relative paths in remove/list, e.g.:
#   usr/local/etc/php/conf.d/92-docker-php-ext-xdebug.ini
if [ -s "$OVERLAY_DIR/remove/list" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    rm -rf "/$rel" && log "removed /$rel" || true
  done < "$OVERLAY_DIR/remove/list"
fi

log "done"
exit 0
