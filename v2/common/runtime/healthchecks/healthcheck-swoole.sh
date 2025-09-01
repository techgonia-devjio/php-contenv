#!/bin/sh
set -e
HOST="${SWOOLE_HOST:-127.0.0.1}"
PORT="${SWOOLE_PORT:-80}"
curl -fsS "http://${HOST}:${PORT}/" >/dev/null
