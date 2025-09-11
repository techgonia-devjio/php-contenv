#!/usr/bin/env bash

get_variables() {
  info "--- Configuring PostgreSQL Service ---"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PORT" "Enter host port for PostgreSQL" "5432"
  prompt_for_var "DOCKY_REPLACEABLE_DB_DATABASE" "Enter PostgreSQL database name" "laravel"
  prompt_for_var "DOCKY_REPLACEABLE_DB_USERNAME" "Enter PostgreSQL user" "laraboy"
  prompt_for_var "DOCKY_REPLACEABLE_DB_PASSWORD" "Enter PostgreSQL password" "password"
}

get_service_template() {
cat <<'EOF'
  postgres:
    image: postgres:18-alpine
    container_name: ${DB_CONTAINER_NAME:-DOCKY_REPLACEABLE_APP_NAME}-pgsql
    environment:
      PGPASSWORD: '${DB_PASSWORD:-secret}'
      POSTGRES_DB: "${DB_DATABASE:-DOCKY_REPLACEABLE_DB_DATABASE}"
      POSTGRES_USER: "${DB_USERNAME:-DOCKY_REPLACEABLE_DB_USERNAME}"
      POSTGRES_PASSWORD: "${DB_PASSWORD:-DOCKY_REPLACEABLE_DB_PASSWORD}"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "${DB_PORT:-DOCKY_REPLACEABLE_DB_PORT}:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME:-DOCKY_REPLACEABLE_DB_USERNAME} -d ${DB_DATABASE:-DOCKY_REPLACEABLE_DB_DATABASE}"]
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
  postgres_data:
    driver: local
EOF
}
