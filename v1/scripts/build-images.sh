#!/bin/bash

# This script builds all the Docker images and tags them with the correct version.

# Set the Docker Hub username and repository name.
USERNAME="techgonia-devjio"
REPOSITORY="php-contenv"

# Set the project version.
VERSION="1.0.0"

# Build the images for each PHP version and web server.
for PHP_VERSION in 8.1 8.2 8.3 8.4; do
  for WEB_SERVER in apache nginx; do
    echo "Building ${PHP_VERSION}-${WEB_SERVER}..."
    docker build -t ${USERNAME}/${REPOSITORY}:${PHP_VERSION}-${WEB_SERVER}-v${VERSION} -f ${PHP_VERSION}/${WEB_SERVER}/Dockerfile .
  done
done
