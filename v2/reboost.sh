#!/usr/local/bin/bash
# reboost: repository snapshot generator (macOS/Linux, Bash 5+)
# Usage:
#   reboost [path=.] [--output <file>] [--ignoreDir "dir1|dir2|.git"] [--ignoreFiles "*.md|LICENSE|.gitattributes"]

set -euo pipefail
shopt -s nocasematch

PATH_ARG="."
OUTPUT_FILE=""
IGNORE_DIRS_RAW=""
IGNORE_FILES_RAW=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_FILE="${2:-}"; shift 2 ;;
    --ignoreDir|--ignoreDirs) IGNORE_DIRS_RAW="${2:-}"; shift 2 ;;
    --ignoreFiles) IGNORE_FILES_RAW="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: reboost [path=.] [--output <file>] [--ignoreDir \"dir1|dir2|...\"] [--ignoreFiles \"glob1|glob2|...\"]"
      exit 0
      ;;
    *) PATH_ARG="$1"; shift ;;
  esac
done

if [[ ! -d "$PATH_ARG" ]]; then
  echo "Path not a directory: $PATH_ARG" >&2
  exit 1
fi

timestamp() { date +"%Y-%m-%d_%H-%M-%S"; }
[[ -n "$OUTPUT_FILE" ]] || OUTPUT_FILE="snapshot_$(timestamp).txt"

ABS_PATH="$(cd "$PATH_ARG" && pwd)"

IFS='|' read -r -a IGNORE_DIRS <<< "${IGNORE_DIRS_RAW}"
IFS='|' read -r -a IGNORE_FILES <<< "${IGNORE_FILES_RAW}"

# Build a `find` command (as an ARRAY) that prunes ignored directories and prints NUL-separated files
declare -a FIND_CMD=()
build_find_cmd() {
  FIND_CMD=(find "$ABS_PATH")
  if (( ${#IGNORE_DIRS[@]} > 0 )) && [[ -n "${IGNORE_DIRS_RAW}" ]]; then
    FIND_CMD+=( "(" )
    local first=1
    for d in "${IGNORE_DIRS[@]}"; do
      [[ -z "$d" ]] && continue
      d="${d#/}"; d="${d%/}"
      if (( first )); then first=0; else FIND_CMD+=( -o ); fi
      FIND_CMD+=( -type d \( -ipath "*/$d" -o -ipath "*/$d/*" \) )
    done
    FIND_CMD+=( ")" -prune -o )
  fi
  FIND_CMD+=( -type f -print0 )
}

matches_ignore_files() {
  local name="$1"
  if (( ${#IGNORE_FILES[@]} == 0 )) || [[ -z "${IGNORE_FILES_RAW}" ]]; then
    return 1
  fi
  local g
  for g in "${IGNORE_FILES[@]}"; do
    [[ -z "$g" ]] && continue
    if [[ "$name" == $g ]]; then
      return 0
    fi
  done
  return 1
}

capture_tree() {
  local pattern=""
  [[ -n "$IGNORE_DIRS_RAW" ]] && pattern="$IGNORE_DIRS_RAW"
  if [[ -n "$IGNORE_FILES_RAW" ]]; then
    if [[ -n "$pattern" ]]; then
      pattern="$pattern|$IGNORE_FILES_RAW"
    else
      pattern="$IGNORE_FILES_RAW"
    fi
  fi

  if command -v tree >/dev/null 2>&1; then
    if [[ -n "$pattern" ]]; then
      (cd "$ABS_PATH" && tree -h -a -I "$pattern")
    else
      (cd "$ABS_PATH" && tree -h -a)
    fi
  else
    (cd "$ABS_PATH" && find . -print | sed 's|^\./||')
  fi
}

{
  echo "# reboost snapshot"
  echo "# Generated: $(date -Iseconds 2>/dev/null || date)"
  echo "# Root: ${ABS_PATH}"
  echo "# Ignore Dirs: ${IGNORE_DIRS_RAW:-<none>}"
  echo "# Ignore Files: ${IGNORE_FILES_RAW:-<none>}"
  echo
  echo "===== TREE ====="
  capture_tree
  echo
} > "$OUTPUT_FILE"

build_find_cmd

declare -a INCLUDED_FILES=()
while IFS= read -r -d '' abs; do
  rel="${abs#$ABS_PATH/}"
  base="${rel##*/}"
  if matches_ignore_files "$base"; then
    continue
  fi
  INCLUDED_FILES+=("$rel")
done < <("${FIND_CMD[@]}")

{
  echo "===== FILE INDEX (${#INCLUDED_FILES[@]}) ====="
  for rel in "${INCLUDED_FILES[@]}"; do
    echo "$rel"
  done
  echo
} >> "$OUTPUT_FILE"

{
  echo "===== FILE CONTENTS ====="
  for rel in "${INCLUDED_FILES[@]}"; do
    abs="${ABS_PATH}/${rel}"
    echo
    echo "---------- BEGIN FILE: ${rel} ----------"
    mt="$(/usr/bin/file -I -b "$abs" 2>/dev/null || /usr/bin/file -b "$abs" 2>/dev/null || echo text/plain)"
    if [[ "$mt" == text/* || "$mt" == application/json* || "$mt" == application/xml* || "$mt" == application/javascript* ]]; then
      sed -e 's/\r$//' "$abs"
    else
      echo "[binary or non-text content omitted: $mt]"
    fi
    echo "----------- END FILE: ${rel} -----------"
  done
} >> "$OUTPUT_FILE"

echo "$OUTPUT_FILE"
