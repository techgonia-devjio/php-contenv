#!/usr/bin/env bash
set -euo pipefail

php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan optimize:clear

echo "✔ Dev caches cleared."
