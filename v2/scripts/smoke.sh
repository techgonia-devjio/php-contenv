#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/smoke.sh php/8.4/nginx/Dockerfile development 8088
DF="${1:-php/8.4/nginx/Dockerfile}"
TARGET="${2:-development}"
PORT="${3:-8088}"
TAG="mani-smoke-$(basename "$(dirname "$DF")")-$(basename "$(dirname "$(dirname "$DF")")")-$TARGET-$$"

echo "==> Building $TAG from $DF ($TARGET)"
docker build -f "$DF" --target "$TARGET" -t "$TAG" .

cid=""
cleanup() { [[ -n "$cid" ]] && docker rm -f "$cid" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "==> Running on :$PORT"
cid=$(docker run -d -p "$PORT:80" -v "$PWD:/var/www/html" --name "$TAG" "$TAG")
# wait for port
for i in {1..30}; do
  if curl -sS "http://localhost:$PORT" >/dev/null; then break; fi
  sleep 1
done

echo "==> HTTP probe"
curl -sS -D - "http://localhost:$PORT" -o /dev/null | sed -n '1,10p'

echo "==> Sanity"
docker exec -it "$cid" mani-sanity || true

echo "==> PHP extensions"
docker exec -it "$cid" php -m | sed -n '1,200p'

echo "==> OK"
