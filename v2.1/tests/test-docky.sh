#!/usr/bin/env bash
set -euo pipefail

# Smoke test docky without touching your repo

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # -> repo root

# Detect docky location: consumer layout (.docker/v2) or package layout (v2)
if [ -x "$ROOT/.docker/v2/docky" ]; then
  DOCKY_PATH="$ROOT/.docker/v2/docky"
  COPY_STEP(){
    cp -a "$ROOT/.docker" app/.docker;
    mkdir -p app/.docker-snippets && touch app/.docker-snippets/docky.answers.yml;
  }
elif [ -x "$ROOT/v2/docky" ]; then
  # shellcheck disable=SC2034
  DOCKY_PATH="$ROOT/v2/docky"
  COPY_STEP(){
    mkdir -p app/.docker && cp -a "$ROOT/v2" app/.docker/v2;
    mkdir -p app/.docker-snippets && touch app/.docker-snippets/docky.answers.yml
  }
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
echo "Adding mysql stub service"
./.docker/v2/docky add-svc mysql
grep -q 'mysql:' docker-compose.yml || { echo "mysql service not in compose"; exit 1; }
# ensure at this point only mysql and app service are present and not others
yq e '.services | keys | .[]' docker-compose.yml | grep -Ev '^(app|mysql)$' && { echo "ERROR: unexpected services in compose"; yq e '.services | keys | .[]' docker-compose.yml; exit 1; }
echo "docky tests OK"
