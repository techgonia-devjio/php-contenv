#!/usr/bin/env bash

init_service_vars(){ :; }

get_variables() {
  info "--- Configuring App Service (Global Settings) ---"
  prompt_for_var "DOCKY_REPLACEABLE_APP_NAME" "Enter your application name" "docky_app"
  prompt_for_var "DOCKY_REPLACEABLE_APP_PORT" "Enter the web port to expose on your host" "8081"
  prompt_for_var "DOCKY_REPLACEABLE_VITE_PORT" "Enter the Vite port" "5170"
  prompt_for_var "DOCKY_REPLACEABLE_PHP_VERSION" "Enter PHP version (e.g., 8.4, 8.3)" "8.4"
  prompt_for_var "DOCKY_REPLACEABLE_WEBSERVER" "Enter webserver (nginx, apache, frankenphp)" "nginx"
  prompt_for_var "DOCKY_REPLACEABLE_NETWORK_NAME" "Enter Docker network name" "mainnet"
}

get_service_template() {
cat <<'EOF'
  app:
    container_name: ${APP_SERVICE_NAME:-DOCKY_REPLACEABLE_APP_NAME}
    build:
      context: "${DOCKER_CONTEXT:-./.docker/v2}"
      dockerfile: php/DOCKY_REPLACEABLE_PHP_VERSION/DOCKY_REPLACEABLE_WEBSERVER/Dockerfile
      # target: development or production
      target: ${PHP_DOCKER_TARGET:-development}
      args:
        JS_RUNTIME_REQUIRE_NODE: "true"
        JS_RUNTIME_NODE_VERSION: "22"
        INSTALL_DB_MYSQL_CLIENT: "true"
        PHP_EXT_PDO_MYSQL: "true"
        # look docs for more options to add or disable default extensions and packages
    extra_hosts:
      - "host.docker.internal:host-gateway"
    ports:
      - "${APP_PORT:-DOCKY_REPLACEABLE_APP_PORT}:80"
      - "${VITE_PORT:-DOCKY_REPLACEABLE_VITE_PORT}:${VITE_PORT:-5170}"
    environment:
      PUID: ${WWWUSER:-1000}
      PGID: ${WWWGROUP:-1000}
      # Must match the server name in PHPStorm's server configuration, need for xdebug
      PHP_IDE_CONFIG: "serverName=docker"
      XDEBUG_MODE: "off"
      XDEBUG_CONFIG: '${XDEBUG_CONFIG:-client_host=host.docker.internal}'
      IGNITION_LOCAL_SITES_PATH: '${PWD}'
      SUPERVISOR_PHP_USER: "www-data"
    volumes:
      # - "${DOCKER_SUBMODULE_DIR:-.docker/v2}/common/runtime/configs/php/92-docker-php-ext-xdebug.ini:/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
      # - ./.docker/v2/overlays/queue-worker:/opt/overlay/queue-worker:ro # example overlay mount provided by default
      # - ./.docker/v2/overlays/locales:/opt/overlay/locales:ro # example overlay mount provided by default
      # - ".docker-snippets/php/98-custom.ini:/usr/local/etc/php/conf.d/99-custom.ini" # custom user php.ini snippet
      - ./logs/:/var/log
      - .:/var/www/html
    # healthcheck:
      # test: ["CMD", "/usr/local/bin/healthcheck-nginx.sh"]
      # interval: 30s
      # timeout: 3s
      # retries: 5
      # disable: true # uncomment to disable healthcheck
    # use depends_on to ensure db is started before app, but does not wait for db to be "ready", only start the docker container
    # depends_on:
    #  - db
    networks:
      - DOCKY_REPLACEABLE_NETWORK_NAME

EOF
}
get_volumes_template(){ :; }
