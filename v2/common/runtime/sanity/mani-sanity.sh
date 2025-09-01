#!/bin/sh

# Portable system sanity report (BusyBox/GNU friendly)
# this is nailed/geneated by chatgpt
set -e

p() { printf " - %-26s %s\n" "$1" "$2"; }

echo "===== SYSTEM ====="
p "Hostname" "$(hostname)"
p "OS" "$(awk -F= '/^PRETTY_NAME=/{gsub(/"/,"");print $2}' /etc/os-release 2>/dev/null || echo Debian)"
p "Kernel" "$(uname -srmo 2>/dev/null || uname -a)"
p "Time (UTC)" "$(date -u '+%Y-%m-%d %H:%M:%S')"
p "Timezone" "$(readlink -f /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##' || echo UTC)"
p "CPU (nproc)" "$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN)"

# Memory (free -h if present; fallback to /proc/meminfo)
if command -v free >/dev/null 2>&1; then
  line="$(free -h 2>/dev/null | awk 'NR==2{print $2" total, "$3" used, "$4" free"}')"
  [ -n "$line" ] || line="$(free | awk 'NR==2{printf "%.0fMB total, %.0fMB used, %.0fMB free", $2/1024, $3/1024, $4/1024}')"
  p "Mem (free -h)" "$line"
else
  total=$(awk '/MemTotal/{printf "%.0fMB",$2/1024}' /proc/meminfo)
  avail=$(awk '/MemAvailable/{printf "%.0fMB",$2/1024}' /proc/meminfo)
  p "Mem (proc)" "$total total, $avail available"
fi

# Disk
if command -v df >/dev/null 2>&1; then
  dline="$(df -h /var/www/html 2>/dev/null | awk 'NR==2{print $2" total, "$4" free"}')"
  [ -n "$dline" ] && p "Disk /var/www/html" "$dline"
fi

p "User" "$(id -un) (uid=$(id -u), gid=$(id -g))"
p "PUID/PGID env" "${PUID:--}/${PGID:--}"

echo "===== S6 & SERVICES ====="
ov="$(ls -d /package/admin/s6-overlay-* 2>/dev/null | head -n1 || true)"
ver=""; [ -n "$ov" ] && ver="${ov##*/s6-overlay-}"
p "s6 overlay" "${ver:-present}"
sv="$(ls /etc/services.d 2>/dev/null | paste -sd, - || true)"
p "services.d" "${sv:-none}"
echo " - processes:"
printf "  %-3s %-15s %s\n" PID COMMAND COMMAND
ps -o pid= -o comm= -o args= | awk 'NR<=200{printf "  %-3s %-15s %s\n",$1,$2,$3" "$4" "$5}'

echo "===== APACHE ====="
if command -v apache2ctl >/dev/null 2>&1; then
  p "Apache" "$(apache2ctl -v | awk -F/ '/Server version/{print $2}')"
else
  echo " - Apache not present"
fi

echo "===== PHP ====="
php -v | head -n1
p "INI files" "/usr/local/etc/php/conf.d"
echo " - conf.d:"; ls -1 /usr/local/etc/php/conf.d 2>/dev/null | sed 's/^/   * /'
echo " - loaded extensions:"
php -r 'foreach (get_loaded_extensions() as $e) printf("   * %-20s %s\n",$e,phpversion($e)?:PHP_VERSION);'
if php -m | grep -qi xdebug; then
  echo " - xdebug:"
  php -i | awk -F"=> " '/^xdebug\./{printf("   * %-24s %s\n",$1,$2)}' | sort
fi

echo "===== COMPOSER ====="
if command -v composer >/dev/null 2>&1; then
  composer --version
  p "Vendor dir" "$( [ -d vendor ] && echo vendor || echo '(none)' )"
else
  echo " - Composer not installed"
fi

echo "===== JS RUNTIMES ====="
for b in node npm pnpm yarn deno bun; do
  if command -v "$b" >/dev/null 2>&1; then
    v="$($b --version 2>/dev/null | head -n1)"
    [ -z "$v" ] && v="$($b -v 2>/dev/null | head -n1)"
    p "$b" "$v"
  fi
done

echo "===== SWOOLE RUNTIME ====="
if php -m | grep -qiE '^openswoole$|^swoole$'; then
  p "Swoole" "$(php -r 'echo phpversion("openswoole")?:phpversion("swoole")?:"unknown";')"
  p "Document root" "${SWOOLE_DOCUMENT_ROOT:-/var/www/html/public}"
  p "Host" "${SWOOLE_HOST:-localhost}"
  p "Port" "${SWOOLE_PORT:-9501}"
  p "Worker num" "${SWOOLE_WORKER_NUM:-auto}"
  p "Max requests" "${SWOOLE_MAX_REQUESTS:-unlimited}"
  p "Static handler" "$( [ "${SWOOLE_STATIC:-1}" = "1" ] && echo enabled || echo disabled )"
else
  echo " - Swoole / OpenSwoole not installed"
fi

echo "===== FRANKENPHP ====="
if command -v frankenphp >/dev/null 2>&1; then
  v="$(frankenphp --version 2>/dev/null | head -n1)"
  [ -z "$v" ] && v="present"
  printf " - %-26s %s\n" "frankenphp" "$v"
else
  echo " - not present"
fi


echo "===== DB CLIENTS ====="
for d in mysql psql redis-cli mongosh mongo memcached; do
  if command -v "$d" >/dev/null 2>&1; then
    p "$d" "$($d --version 2>/dev/null | head -n1)"
  fi
done

echo "===== ENV (selected) ====="
for k in APP_ENV PUID PGID XDEBUG_MODE XDEBUG_CLIENT_HOST DB_HOST DB_PORT REDIS_HOST REDIS_PORT; do
  v="$(printenv "$k" 2>/dev/null || true)"; [ -n "$v" ] && echo "$k=$v"
done

echo "===== PATH ====="
echo "$PATH" | tr ':' '\n' | sed 's/^/ - /'
echo
echo "OK"
