#!/command/with-contenv bash
# ==============================================================================
# S6 Initialization Script
#
# Description:
#   This script runs once when the container starts, before any services.
#   It handles dynamic user/group ID mapping and sets permissions on common
#   framework directories like those for Laravel.
# ==============================================================================

set -e

echo "----> Running container initialization tasks..."

# --- Dynamic User/Group ID Mapping ---
# Check if the user wants to sync the container's user ID with the host's user.
# This is crucial for fixing file permission issues during development.
if [ -n "${PUID}" ] && [ "$(id -u mani)" != "${PUID}" ]; then
    echo "----> Changing 'mani' user ID to ${PUID}"
    usermod -o -u "${PUID}" mani
fi

if [ -n "${PGID}" ] && [ "$(id -g mani)" != "${PGID}" ]; then
    echo "----> Changing 'mani' group ID to ${PGID}"
    groupmod -o -g "${PGID}" mani
fi

# --- Framework Permissions ---
# Set permissions for common Laravel directories if they exist.
# This ensures the web server and CLI can write to them.
if [ -d /var/www/html/storage ]; then
    echo "----> Setting ownership for /var/www/html/storage"
    chown -R mani:mani /var/www/html/storage
fi


if [ -d /var/www/html/bootstrap/cache ]; then
    echo "----> Setting ownership for /var/www/html/bootstrap/cache"
    chown -R mani:mani /var/www/html/bootstrap/cache
fi


echo "----> Fixing service directory permissions"
/bin/chown -R root:root /etc/s6-overlay/services.d
/bin/chmod -R 755 /etc/s6-overlay/services.d

echo "----> Initialization complete."
