#!/usr/bin/env bash
set -euo pipefail

if ! command -v mkdocs >/dev/null 2>&1; then
  echo "✗ ERROR: mkdocs not found. Please install it first: pip install mkdocs" >&2
  exit 1
fi

docs_dir="${PROJECT_ROOT}/.docker/v2/docs"

if [ -f "$docs_dir/mkdocs.yml" ]; then
    echo "› Serving documentation from ${docs_dir} on http://127.0.0.1:8000"
    (cd "$docs_dir" && mkdocs serve)
else
    echo "✗ ERROR: mkdocs.yml not found in ${docs_dir}" >&2
    exit 1
fi
