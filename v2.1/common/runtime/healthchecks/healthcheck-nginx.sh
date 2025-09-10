#!/usr/bin/env bash
set -Eeuo pipefail
curl -fsS --max-time 2 http://127.0.0.1/healthz >/dev/null
timeout 2 bash -lc '</dev/tcp/127.0.0.1/9000' 2>/dev/null
