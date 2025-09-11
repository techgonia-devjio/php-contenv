#!/usr/bin/env bash
set -euo pipefail

TO="${1:-${MAIL_TO:-}}"
SUBJECT="${2:-"Laravel mail test $(date -Iseconds)"}"
BODY="${3:-"Hello from $(hostname). This is a test email."}"

if [[ -z "${TO}" ]]; then
  echo "Usage: $0 to@example.com [subject] [body]"
  exit 1
fi

php artisan tinker --execute="
use Illuminate\Support\Facades\Mail;
Mail::raw('${BODY//\'/\\\'}', function(\$m){
  \$m->to('${TO}')->subject('${SUBJECT//\'/\\\'}');
});
"

echo "✔ Sent test email to: $TO"
