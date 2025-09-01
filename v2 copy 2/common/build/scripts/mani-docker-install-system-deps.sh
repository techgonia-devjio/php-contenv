#!/bin/sh
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  apt-transport-https ca-certificates gnupg lsb-release curl git nano zip unzip \
  gosu procps sqlite3 libcap2-bin libzip-dev libssl-dev build-essential \
  pkg-config autoconf dnsutils locales locales-all acl
apt-get clean && rm -rf /var/lib/apt/lists/*
echo "----> System dependencies installed successfully."