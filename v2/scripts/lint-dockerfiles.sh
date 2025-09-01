#!/usr/bin/env bash
set -euo pipefail

# Lightweight checks without hadolint
fail=0
while IFS= read -r -d '' df; do
  grep -q '^FROM ' "$df" || { echo "Dockerfile missing FROM: $df"; fail=1; }
  grep -q 'SHELL \["/bin/bash"' "$df" || echo "INFO: consider Bash shell for pipefail in $df"
done < <(find php -name Dockerfile -print0)

exit $fail
