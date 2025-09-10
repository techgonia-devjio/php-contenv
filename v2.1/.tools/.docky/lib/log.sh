# shellcheck shell=bash


die(){ echo "✗ $*" >&2; exit 1; }
warn(){ echo "⚠ $*" >&2; }
info(){ echo "› $*"; }
ok(){ echo "✓ $*"; }