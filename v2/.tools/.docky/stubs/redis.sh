#!/usr/bin/env bash

get_variables() {
  info "--- Configuring Redis Service ---"
  prompt_for_var "DOCKY_REPLACEABLE_REDIS_PORT" "Enter host port for Redis" "6379"
  prompt_for_var "DOCKY_REPLACEABLE_REDIS_PASSWORD" "Enter Redis password (leave empty for none)" "password"
}

get_service_template() {
cat <<'EOF'
  redis:
    image: redis:alpine
    container_name: ${APP_NAME:-DOCKY_REPLACEABLE_APP_NAME}-redis
    command: redis-server --requirepass "${REDIS_PASSWORD:-DOCKY_REPLACEABLE_REDIS_PASSWORD}"
    ports:
      - "${REDIS_PORT:-DOCKY_REPLACEABLE_REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD:-DOCKY_REPLACEABLE_REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - "DOCKY_REPLACEABLE_NETWORK_NAME"
EOF
}

get_volumes_template() {
cat <<'EOF'
  redis_data:
    driver: local
EOF
}
