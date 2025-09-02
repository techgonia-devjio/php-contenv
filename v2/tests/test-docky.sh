#!/usr/bin/env bash
set -euo pipefail

# Smoke test docky without touching your repo

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # -> repo root

# Detect docky location: consumer layout (.docker/v2) or package layout (v2)
if [ -x "$ROOT/.docker/v2/docky" ]; then
  DOCKY_PATH="$ROOT/.docker/v2/docky"
  COPY_STEP(){ cp -a "$ROOT/.docker" app/.docker; }
elif [ -x "$ROOT/v2/docky" ]; then
  DOCKY_PATH="$ROOT/v2/docky"
  COPY_STEP(){ mkdir -p app/.docker && cp -a "$ROOT/v2" app/.docker/v2; }
else
  echo "Root: $ROOT"
  echo "docky not found at $ROOT/.docker/v2/docky or $ROOT/v2/docky or make sure its executable chmod +x"
  exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
mkdir -p app
COPY_STEP
cd app

# regenerate compose
./.docker/v2/docky gen --no-ask

test -f docker-compose.yml || { echo "compose not generated"; exit 1; }
grep -q '^services:' docker-compose.yml || { echo "compose invalid"; exit 1; }

# add a stub service and ensure it appears in project docky.yml
./.docker/v2/docky add-svc mysql
grep -q 'mysql' docky.yml || { echo "mysql stub not added"; exit 1; }

echo "docky tests OK"
