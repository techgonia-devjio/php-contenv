#!/usr/bin/env bash
set -euo pipefail

mysql --user=root --password="$MYSQL_ROOT_PASSWORD" <<-EOSQL
  CREATE DATABASE IF NOT EXISTS testing;
  CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
  GRANT ALL PRIVILEGES ON `testing`.* TO '${MYSQL_USER}'@'%';
  FLUSH PRIVILEGES;
EOSQL
