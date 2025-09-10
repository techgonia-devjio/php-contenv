#!/usr/bin/env bash
init_service_vars() {
  prompt_for_var "DB_PORT" "Enter host port for MySQL" "3306"
  prompt_for_var "DB_DATABASE" "Enter MySQL database name" "laravel"
  prompt_for_var "DB_USERNAME" "Enter MySQL user" "sail"
  prompt_for_var "DB_PASSWORD" "Enter MySQL password" "password"
  prompt_for_var "DB_ROOT_PASSWORD" "Enter MySQL root password" "secret"
}
get_service() {
cat <<'EOF'
  mysql:
    image: mysql:8.0
    container_name: "${APP_NAME}-mysql"
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_ROOT_PASSWORD}"
      MYSQL_DATABASE: "${DB_DATABASE}"
      MYSQL_USER: "${DB_USERNAME}"
      MYSQL_PASSWORD: "${DB_PASSWORD}"
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "${DB_PORT}:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    networks:
      - "${NETWORK_NAME}"
EOF
}
get_volumes() {
cat <<'EOF'
  db_data:
    driver: local
EOF
}
