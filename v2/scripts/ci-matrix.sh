#!/usr/bin/env bash
set -euo pipefail

VERSIONS=(8.1 8.2 8.3 8.4)
VARIANTS=(apache nginx frankenphp)
TARGET=development
PORT_BASE=9000

# for v in "${VERSIONS[@]}"; do
#   for var in "${VARIANTS[@]}"; do
#     DF="php/$v/$var/Dockerfile"
#     [[ -f "$DF" ]] || { echo "skip $DF"; continue; }
#     PORT=$((PORT_BASE++))
#     echo "---- $v/$var -> $PORT ----"
#     bash scripts/smoke.sh "$DF" "$TARGET" "$PORT"
#   done
# done
