#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash tests/scripts/test-runtime.sh php/8.4/nginx/Dockerfile development 8091 nginx
# Defaults:
DF_REL="${1:-php/8.4/nginx/Dockerfile}"
TARGET="${2:-development}"
PORT="${3:-8090}"
SERVER="${4:-nginx}"

say(){ echo "[$(date +%H:%M:%S)] $*"; }
fail(){ echo "❌ $*" >&2; exit 1; }
want(){ local what="$1" cmd="$2"; say "assert: $what"; bash -lc "$cmd" >/dev/null || fail "$what"; }

# --- Resolve paths ------------------------------------------------------
# tests/scripts -> tests
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# tests -> v2
V2_DIR="$(cd "$TESTS_DIR/.." && pwd)"
# v2 -> repo root
REPO_ROOT="$(cd "$V2_DIR/.." && pwd)"

# Preferred runtime mount is the v2 dir (it contains public/, php/, common/, etc.)
APP_MOUNT="$V2_DIR"
FIXTURES_DIR="$TESTS_DIR/fixtures"

# Build context rule:
# - If running in a consumer project with submodule at ./.docker/v2 -> use that.
# - Else (inside this repo) use the package's v2 dir.
if [ -d "$REPO_ROOT/.docker/v2" ]; then
  BUILD_CTX="$REPO_ROOT/.docker/v2"
else
  BUILD_CTX="$V2_DIR"
fi

DF="$BUILD_CTX/$DF_REL"
[ -f "$DF" ] || fail "Dockerfile not found: $DF"

# Tag: mani-test-<server>-<phpVer>-<target>-<pid>
PHP_VER="$(basename "$(dirname "$(dirname "$DF")")")"   # e.g. 8.4
TAG="mani-test-${SERVER}-${PHP_VER}-${TARGET}-$$"

say "==> Build $TAG from $DF (target=$TARGET, ctx=$BUILD_CTX)"
docker build -f "$DF" --target "$TARGET" -t "$TAG" "$BUILD_CTX" \
  --build-arg INSTALL_DB_MYSQL_CLIENT=true \
  --build-arg INSTALL_DB_PGSQL_CLIENT=true \
  --build-arg DB_PGSQL_CLIENT_VERSION="${DB_PGSQL_CLIENT_VERSION:-17}" \
  --build-arg PHP_EXT_PDO_MYSQL=true \
  --build-arg PHP_EXT_PDO_PGSQL=true \
  --build-arg PHP_EXT_GD=true \
  --build-arg PHP_EXT_IMAGICK=true \
  --build-arg PHP_EXT_VIPS=true \
  --build-arg PHP_EXT_INTL=true \
  --build-arg PHP_EXT_ZIP=true \
  --build-arg PHP_EXT_XDEBUG=true \
  --build-arg JS_RUNTIME_REQUIRE_NODE=true \
  --build-arg JS_RUNTIME_NODE_VERSION=22

# --- Run ---------------------------------------------------------------
cid=""
cleanup(){ [ -n "${cid:-}" ] && docker rm -f "$cid" >/dev/null 2>&1 || true; }
trap cleanup EXIT

say "==> Run on :$PORT"
cid=$(docker run -d \
  -p "$PORT:80" \
  -e PUID=1000 -e PGID=1000 \
  -e XDEBUG_MODE=off \
  -e XDEBUG_CLIENT_HOST=host.docker.internal \
  -e OVERLAY_DIRS=/opt/overlay \
  -v "$APP_MOUNT:/var/www/html" \
  -v "$FIXTURES_DIR/php/99-test.ini:/usr/local/etc/php/conf.d/99-test.ini:ro" \
  -v "$FIXTURES_DIR/overlays/hello-svc:/opt/overlay/hello-svc:ro" \
  --name "$TAG" "$TAG")

# --- Probes -------------------------------------------------------------
say "==> Wait for HTTP"
for i in {1..60}; do
  if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null; then break; fi
  sleep 1
  [ $i -eq 60 ] && fail "HTTP not up"
done

say "==> HTTP 200 on /"
curl -fsS -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:$PORT/" | grep -q '^200$' || fail "GET / not 200"

say "==> Server process check"
case "$SERVER" in
  nginx)      docker exec "$cid" pgrep -fa nginx >/dev/null || fail "nginx not running" ;;
  apache)     docker exec "$cid" pgrep -fa apache2 >/dev/null || fail "apache not running" ;;
  frankenphp) docker exec "$cid" pgrep -fa frankenphp >/dev/null || fail "frankenphp not running" ;;
  *)          say "unknown server: $SERVER (skipping process check)";;
esac

say "==> PHP extensions"
want "php present" "docker exec $cid php -v"
want "opcache compiled" "docker exec $cid php -i | grep -qi opcache.enable"
want "intl loaded" "docker exec $cid php -m | grep -qi '^intl$'"
want "zip loaded" "docker exec $cid php -m | grep -qi '^zip$'"
want "pdo_mysql loaded" "docker exec $cid php -m | grep -qi 'pdo_mysql'"
want "pdo_pgsql loaded" "docker exec $cid php -m | grep -qi 'pdo_pgsql'"
want "gd loaded" "docker exec $cid php -m | grep -qi '^gd$'"
want "imagick loaded" "docker exec $cid php -m | grep -qi '^imagick$'"
want "vips loaded" "docker exec $cid php -m | grep -qi '^vips$'"

say "==> Xdebug present but off"
want "xdebug extension present" "docker exec $cid php -m | grep -qi '^xdebug$'"
docker exec "$cid" php -r 'echo function_exists("xdebug_info") ? (getenv("XDEBUG_MODE") ?: ini_get("xdebug.mode") ?: "(none)") : "(none)";' \
   | grep -Eiq '(^off$)|^\(none\)$' || fail "xdebug not effectively off"
say "==> memory_limit overridden (via mounted ini)"
docker exec "$cid" sh -lc 'php -i | grep -Eq "^memory_limit => 384M => 384M$"' || fail "memory_limit not 384M"
