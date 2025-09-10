#!/usr/bin/env bash

get_variables() {
  info "--- Configuring MySQL Service ---"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PORT" "Enter host port for MySQL" "3306"
  prompt_for_var "DOCKY_REPLACEABLE_DB_DATABASE" "Enter MySQL database name" "laravel"
  prompt_for_var "DOCKY_REPLACEABLE_DB_USERNAME" "Enter MySQL user" "laraboy"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PASSWORD" "Enter MySQL password" "password"
  prompt_for_var "DOCKY_REPLACEABLE_DB_ROOT_PASSWORD" "Enter MySQL root password" "secret"
}

get_service_template() {
cat <<'EOF'
  mysql:
    image: mysql:8.4
    container_name: ${DB_CONTAINER_NAME:-DOCKY_REPLACEABLE_APP_NAME}-mysql
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_ROOT_PASSWORD:-DOCKY_REPLACEABLE_DB_ROOT_PASSWORD}"
      MYSQL_DATABASE: "${DB_DATABASE:-DOCKY_REPLACEABLE_DB_DATABASE}"
      MYSQL_USER: "${DB_USERNAME:-DOCKY_REPLACEABLE_DB_USERNAME}"
      MYSQL_PASSWORD: "${DB_PASSWORD:-DOCKY_REPLACEABLE_DB_PASSWORD}"
    ports:
      - "${DB_PORT:-DOCKY_REPLACEABLE_DB_PORT}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./.docker/v2/database/mysql/create-database.sh:/docker-entrypoint-initdb.d/10-create-database.sh:ro
      - ./.docker/v2/database/mysql/create-testing-database.sh:/docker-entrypoint-initdb.d/20-create-testing-database.sh:ro
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-uroot", "-p${DB_ROOT_PASSWORD:-DOCKY_REPLACEABLE_DB_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - "DOCKY_REPLACEABLE_NETWORK_NAME"
    restart: unless-stopped
EOF
}

get_volumes_template() {
cat <<'EOF'
  mysql_data:
    driver: local
EOF
}
