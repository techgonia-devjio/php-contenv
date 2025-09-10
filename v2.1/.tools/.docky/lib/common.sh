# shellcheck shell=bash
set -euo pipefail

# ---- anchor paths (works from any entrypoint) ----
DOCKY_HOME="${DOCKY_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"     # -> .../.docker/v2/.tools/.docky
SUBMODULE_DIR="${SUBMODULE_DIR:-$(cd "$DOCKY_HOME/../.." && pwd)}"              # -> .../.docker/v2
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"



STUBS_DIR="${STUBS_DIR:-${SUBMODULE_DIR}/stubs/services}"
COMPOSE_OUT="${COMPOSE_OUT:-${PROJECT_ROOT}/docker-compose.yml}"
PROJ_SNIPPETS_DIR=".docker-snippets"
PROJ_SNIPPETS_PHP_SUBDIR="${PROJ_SNIPPETS_PHP_SUBDIR:-${PROJ_SNIPPETS_DIR}/php}"
ANSWERS_FILE="${ANSWERS_FILE:-${PROJECT_ROOT}/${PROJ_SNIPPETS_DIR}/.docky.answers.yml}"
PROJECT_DOCKY_YML_FILE="${PROJECT_ROOT}/${PROJ_SNIPPETS_DIR}/docky.yml"
# Prefer project-level config; fallback to submodule default
if [ -f "${PROJECT_DOCKY_YML_FILE}" ]; then
  DOCKY_CONFIG="${PROJECT_DOCKY_YML_FILE}"
else
  DOCKY_CONFIG="${SUBMODULE_DIR}/docky.yml"
fi

# libs
# shellcheck disable=SC1091
source "$DOCKY_HOME/lib/version.sh"
source "$DOCKY_HOME/lib/log.sh"
source "$DOCKY_HOME/lib/utils.sh"
source "$DOCKY_HOME/lib/answers.sh"
source "$DOCKY_HOME/lib/stubs.sh"
source "$DOCKY_HOME/lib/patches.sh"
source "$DOCKY_HOME/lib/placeholders.sh"
