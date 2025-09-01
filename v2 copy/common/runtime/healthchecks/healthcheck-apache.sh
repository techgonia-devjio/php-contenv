#!/bin/sh
# ==============================================================================
# Healthcheck for Apache
#
# Description:
#   Checks if the Apache server is responding to requests on localhost.
#   Exits with status 0 if healthy, 1 if not.
# ==============================================================================

set -e

# Use curl to ping the server status page.
# --fail: Exit with an error code if the HTTP response is not 2xx.
# --silent: Don't show progress meter.
# --show-error: Show error message on failure.
# --output /dev/null: Discard the body of the response.
curl --fail --silent --show-error --output /dev/null http://localhost/server-status || exit 1