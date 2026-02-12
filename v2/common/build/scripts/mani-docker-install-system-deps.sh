#!/bin/sh
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  apt-transport-https ca-certificates gnupg lsb-release curl git nano zip unzip \
  gosu procps sqlite3 libcap2-bin libzip-dev libssl-dev build-essential \
  pkg-config autoconf dnsutils locales locales-all acl dos2unix
apt-get clean && rm -rf /var/lib/apt/lists/*

# Generic hook for project-specific build scripts
if [ -d "/usr/local/bin/project-build-hooks" ]; then
    find /usr/local/bin/project-build-hooks -name "*.sh" -type f -exec chmod +x {} \;
    for f in /usr/local/bin/project-build-hooks/*.sh; do
        if [ -x "$f" ]; then
            echo "----> Running project build hook: $f"
            "$f"
        fi
    done
fi

echo "----> System dependencies installed successfully."
