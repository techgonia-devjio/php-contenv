#!/bin/sh
# ==============================================================================
# mani-docker-install-js-runtime.sh (v2.3 - Robust NVM Installer)
#
# Description:
#   Installs requested JavaScript runtimes and package managers based on
#   Docker build arguments, using a robust method for NVM in non-interactive
#   shells.
#
# ==============================================================================

set -e

# --- Helper Functions for Each Installer ---

install_node() {
    echo "----> Installing Node.js (version: ${JS_RUNTIME_NODE_VERSION})..."
    export NVM_DIR="/usr/local/nvm"
    
    # Create the NVM directory and download the installer
    mkdir -p "$NVM_DIR"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    # CRITICAL FIX: Run nvm commands in a bash subshell where we can source nvm.sh.
    # This is the most reliable way to use nvm in a non-interactive script.
    bash -c "
        # Source the nvm script to make the 'nvm' function available
        . \"$NVM_DIR/nvm.sh\"
        
        # Install the requested version of Node.js
        nvm install \"${JS_RUNTIME_NODE_VERSION}\"
        
        # Set the default alias
        nvm alias default \"${JS_RUNTIME_NODE_VERSION}\"
        nvm use default
    "
    
    # The nvm environment is now set up for future shell sessions.
    # We can verify the installation by checking the symlink nvm creates.
    NODE_VERSION_PATH="$NVM_DIR/versions/node/$(cat $NVM_DIR/alias/default)"
    echo "      Node version: $($NODE_VERSION_PATH/bin/node -v)"
    echo "      npm version: $($NODE_VERSION_PATH/bin/npm -v)"
}

install_deno() {
    echo "----> Installing Deno..."
    curl -fsSL https://deno.land/x/install/install.sh | sh
    echo "      Deno installation complete. Add /root/.deno/bin to your PATH."
}

install_bun() {
    echo "----> Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    echo "      Bun installation complete. Add /root/.bun/bin to your PATH."
}

install_yarn() {
    # This needs to run in the nvm-sourced subshell as well
    bash -c "
        . \"$NVM_DIR/nvm.sh\"
        if command -v npm > /dev/null; then
            echo \"----> Installing Yarn via npm...\"
            npm install -g yarn
            echo \"      Yarn version: $(yarn --version)\"
        else
            echo \"      Skipping Yarn: npm is not installed (Node.js is required).\"
        fi
    "
}

install_pnpm() {
    # This needs to run in the nvm-sourced subshell as well
    bash -c "
        . \"$NVM_DIR/nvm.sh\"
        if command -v npm > /dev/null; then
            echo \"----> Installing pnpm via npm...\"
            npm install -g pnpm
            echo \"      pnpm version: $(pnpm --version)\"
        else
            echo \"      Skipping pnpm: npm is not installed (Node.js is required).\"
        fi
    "
}

# --- Main Execution ---
echo "----> Checking which JS runtimes to install..."

if [ "$JS_RUNTIME_REQUIRE_NODE" = "true" ]; then
    install_node
fi

if [ "$JS_RUNTIME_REQUIRE_DENO" = "true" ]; then
    install_deno
fi

if [ "$JS_RUNTIME_REQUIRE_BUN" = "true" ]; then
    install_bun
fi

# Package managers require Node/npm to be installed first
if [ "$JS_RUNTIME_REQUIRE_NODE" = "true" ]; then
    if [ "$JS_RUNTIME_REQUIRE_YARN" = "true" ]; then
        install_yarn
    fi
    if [ "$JS_RUNTIME_REQUIRE_PNPM" = "true" ]; then
        install_pnpm
    fi
fi

# Add all relevant paths to the system profile to make them available in all shells
# This ensures that when you 'docker exec' into the container, the commands are available.
echo "
# Add JS Runtime Paths
export NVM_DIR=\"/usr/local/nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
export DENO_INSTALL=\"/root/.deno\"
export PATH=\"\$DENO_INSTALL/bin:\$PATH\"
export BUN_INSTALL=\"/root/.bun\"
export PATH=\"\$BUN_INSTALL/bin:\$PATH\"
" > /etc/profile.d/js_runtimes.sh

echo "----> JS runtime installation complete."
