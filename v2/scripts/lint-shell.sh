#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
fail=0

while IFS= read -r -d '' f; do
  case "$f" in
    *.sh|*/run|*/finish|*/log/run)
      bash -n "$f" || { echo "BASH SYNTAX ERROR: $f"; fail=1; }
      ;;
  esac
done < <(find common -type f -print0)

exit $fail
