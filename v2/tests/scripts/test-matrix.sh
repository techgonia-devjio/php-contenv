#!/usr/bin/env bash
set -euo pipefail

# Accept pairs via CLI or default set.
# Each pair is: "<DockerfileRelPath> <server>"
if [ "$#" -ge 2 ]; then
  PAIRS=("$@")
else
  PAIRS=(
    "php/8.4/nginx/Dockerfile" "nginx"
    "php/8.4/apache/Dockerfile" "apache"
    "php/8.4/frankenphp/Dockerfile" "frankenphp"
  )
fi

PORT_BASE=${PORT_BASE:-9100}
TARGET=${TARGET:-development}

i=0
while [ $i -lt ${#PAIRS[@]} ]; do
  DF="${PAIRS[$i]}"; SERVER="${PAIRS[$((i+1))]}"
  PORT=$((PORT_BASE + (i/2)))
  echo "---- $DF ($SERVER) : $PORT ----"
  bash "$(dirname "$0")/test-runtime.sh" "$DF" "$TARGET" "$PORT" "$SERVER"
  i=$((i+2))
done
