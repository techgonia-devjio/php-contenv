# shellcheck shell=bash

if ! command -v mkdocs >/dev/null 2>&1; then
  die "mkdocs not found. Install: pip install mkdocs mkdocs-material"
fi

docs_dir="${SUBMODULE_DIR}/docs"
[ -f "$docs_dir/mkdocs.yml" ] || die "mkdocs.yml not found in ${docs_dir}"
info "Serving docs from $docs_dir on http://127.0.0.1:5105"
( cd "$docs_dir" && mkdocs serve -a 127.0.0.1:5105 )