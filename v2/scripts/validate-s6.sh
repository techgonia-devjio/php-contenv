#!/usr/bin/env bash
set -euo pipefail
err=0

# executable bits
while IFS= read -r -d '' f; do
  if [[ ! -x "$f" ]]; then
    echo "FIXME: not executable: $f"
    err=1
  fi
done < <(find common/runtime/s6 -type f \( -name run -o -name finish \) -print0)

# service types present
while IFS= read -r -d '' d; do
  if [[ ! -f "$d/type" ]]; then
    echo "FIXME: missing type file in $d"
    err=1
  fi
done < <(find common/runtime/s6/variants -maxdepth 3 -type d -name '[a-z]*' -path '*/services.d/*' -print0)

# CRLF check
if git ls-files -z | xargs -0 file | grep -E "CRLF|CR line terminators" >/dev/null 2>&1; then
  echo "WARN: CRLF found in repo. Convert to LF for s6 scripts."
fi

exit $err
