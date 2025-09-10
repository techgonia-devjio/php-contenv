#!/usr/bin/env bash
init_service_vars(){ :; }
get_service() {
cat <<'EOF'
  app:
    container_name: "${APP_NAME}"
    build:
      context: ./.docker/v2
      dockerfile: php/${PHP_VERSION}/${WEBSERVER}/Dockerfile
      args:
        PUID: "${UID:-1000}"
        PGID: "${GID:-1000}"
    ports:
      - "${APP_PORT}:80"
    volumes:
      - .:/var/www/html
    networks:
      - "${NETWORK_NAME}"
EOF
}
get_volumes(){ :; }
