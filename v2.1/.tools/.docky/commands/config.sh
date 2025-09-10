# shellcheck shell=bash

subcmd="${1:-show}"; shift || true
case "$subcmd" in
  show)  ans_show ;;
  reset) ans_reset ;;
  set)
    k="${1:-}"; v="${2:-}"
    [ -n "$k" ] && [ -n "$v" ] || die "usage: docky config set DOCKY_REPLACE_KEY value"
    ans_set "$k" "$v"; ok "set $k=$v" ;;
  *) die "usage: docky config {show|reset|set DOCKY_REPLACE_KEY value}" ;;
esac