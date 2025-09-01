#!/bin/sh
# ==============================================================================
# mani-docker-install-system-deps.sh (v2.2 - Syntax Fixed)
#
# Description:
#   Installs the core system packages and build tools required for all image
#   variations. This script is designed to be the first layer in the Dockerfile
#   build process, as these dependencies change very infrequently.
#
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Set DEBIAN_FRONTEND to noninteractive to prevent any interactive prompts
# during package installation, which would cause the Docker build to hang.
export DEBIAN_FRONTEND=noninteractive

# --- Main Execution ---
echo "----> 1. Updating package lists..."
apt-get update

echo "----> 2. Installing core system utilities and build tools..."
# NOTE: Each line in this multi-line command MUST end with a backslash (\)
# to indicate that the command continues on the next line.
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    curl \
    git \
    nano \
    zip \
    unzip \
    gosu \
    procps \
    sqlite3 \
    libcap2-bin \
    libzip-dev \
    libssl-dev \
    build-essential \
    pkg-config \
    autoconf \
    dnsutils \
    locales \
    locales-all

echo "----> 3. Cleaning up apt cache to reduce image size..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "----> System dependencies installed successfully."
