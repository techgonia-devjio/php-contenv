#!/usr/bin/env bash
# This command is sourced by docky.sh, so it has access to all libraries.

# --- Test Helper Functions (self-contained for clarity) ---
_info() { printf "› %s\n" "$*"; }
_ok()   { printf "✓ %s\n" "$*"; }
_die()  { printf "✗ ERROR: %s\n" "$*" >&2; exit 1; }

# --- Test Environment Setup ---
TEST_PROJECT_DIR=""
_setup_test_environment() {
    _info "Setting up isolated test environment..."
    TEST_PROJECT_DIR=$(mktemp -d)
    local docky_source_dir
    docky_source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"

    echo "Test project directory: $TEST_PROJECT_DIR"
    echo "Docky source directory: $docky_source_dir"

    # Copy the entire .docky directory into the test project
    cp -R "$docky_source_dir" "$TEST_PROJECT_DIR/.docker/"
    _ok "Test environment created at: $TEST_PROJECT_DIR"
}

# --- Cleanup ---
_cleanup() {
  if [ -n "$TEST_PROJECT_DIR" ] && [ -d "$TEST_PROJECT_DIR" ]; then
    _info "Cleaning up test environment..."
    rm -rf "$TEST_PROJECT_DIR"
    _ok "Cleanup complete."
  fi
}
trap _cleanup EXIT

# --- Main Test Execution ---
main_test() {
    _setup_test_environment
    cd "$TEST_PROJECT_DIR" || _die "Failed to change into test directory."

    # The command to run docky inside the test environment
    local DOCKY_CMD="./.docker/v2/docky"
    # check if exists if not try with ../
    if [ ! -f "$DOCKY_CMD" ]; then
      DOCKY_CMD="../.docker/v2/docky"
      if [ ! -f "$DOCKY_CMD" ]; then
        DOCKY_CMD="../../.docker/v2/docky"
        if [ ! -f "$DOCKY_CMD" ]; then
          DOCKY_CMD="../../../.docker/v2/docky"
        fi
      fi
    fi

    [ -f "$DOCKY_CMD" ] || _die "docky command not found at $DOCKY_CMD curent dir: $(pwd)"

    # --- Test 1: 'docky gen' with multiple services ---
    _info "\n--- Testing 'docky gen app redis mysql' ---"
    # Pipe 'yes ""' to automatically accept all default prompt values
    if ! yes "" | "$DOCKY_CMD" gen app redis mysql; then
        _die "'docky gen' command failed."
    fi

    test -f "docker-compose.yml" || _die "'docky gen' failed to create docker-compose.yml."
    grep -q "  app:" "docker-compose.yml" || _die "'app' service missing after gen."
    grep -q "  redis:" "docker-compose.yml" || _die "'redis' service missing after gen."
    grep -q "  mysql:" "docker-compose.yml" || _die "'mysql' service missing after gen."
    _ok "'docky gen' created a multi-service compose file correctly."

    # --- Test 2: 'docky add-svc' to an existing file ---
    _info "\n--- Testing 'docky add-svc postgres' ---"
    if ! yes "" | "$DOCKY_CMD" add-svc postgres; then
        _die "'docky add-svc' command failed."
    fi
    grep -q "  postgres:" "docker-compose.yml" || _die "'postgres' service was not added."
    _ok "'docky add-svc postgres' worked correctly."

    # --- Test 3: Idempotency (adding an existing service) ---
    _info "\n--- Testing Idempotency (add-svc redis again) ---"
    # The command should succeed (exit 0) and print a specific message.
    local add_again_output
    add_again_output=$(yes "" | "$DOCKY_CMD" add-svc redis 2>&1)
    if ! echo "$add_again_output" | grep -q "already present"; then
        _die "Adding an existing service did not produce the expected 'already present' message."
    fi
    _ok "Attempting to add an existing service was handled gracefully."

    # --- Test 4: Doctor command ---
    _info "\n--- Testing 'docky doctor' ---"
    if ! "$DOCKY_CMD" doctor > /dev/null; then
        _die "'docky doctor' command failed."
    fi
    _ok "'docky doctor' command runs without errors."

    echo
    _ok "✅ All docky tests passed!"
}

# --- Run the main test function ---
main_test
