# shellcheck shell=bash

dc(){ docker compose "$@"; }
cmd="$1"; shift || true
dc "$cmd" "$@"