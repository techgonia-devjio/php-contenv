#!/usr/bin/env bash

get_variables() {
  info "--- Configuring MySQL Service ---"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PORT" "Enter host port for MySQL" "3306"
  prompt_for_var "DOCKY_REPLACEABLE_DB_DATABASE" "Enter MySQL database name" "laravel"
  prompt_for_var "DOCKY_REPLACEABLE_DB_USERNAME" "Enter MySQL user" "sail"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PASSWORD" "Enter MySQL password" "password"
  prompt_for_var "DOCKY_REPLACEABLE_DB_ROOT_PASSWORD" "Enter MySQL root password" "secret"
}

get_service_template() {
cat <<'EOF'
  mysql:
    image: mysql:8.0
    container_name: ${APP_NAME:-DOCKY_REPLACEABLE_APP_NAME}-mysql
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_ROOT_PASSWORD:-DOCKY_REPLACEABLE_DB_ROOT_PASSWORD}"
      MYSQL_DATABASE: "${DB_DATABASE:-DOCKY_REPLACEABLE_DB_DATABASE}"
      MYSQL_USER: "${DB_USERNAME:-DOCKY_REPLACEABLE_DB_USERNAME}"
      MYSQL_PASSWORD: "${DB_PASSWORD:-DOCKY_REPLACEABLE_DB_PASSWORD}"
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "${DB_PORT:-DOCKY_REPLACEABLE_DB_PORT}:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    networks:
      - "DOCKY_REPLACEABLE_NETWORK_NAME"
EOF
}

get_volumes_template() {
cat <<'EOF'
  db_data:
    driver: local
EOF
}

