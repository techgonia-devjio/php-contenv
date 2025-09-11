#!/bin/bash

set -euo pipefail

: "${JS_RUNTIME_NODE_VERSION:=lts}"
: "${JS_RUNTIME_REQUIRE_NODE:=true}"
: "${JS_RUNTIME_REQUIRE_DENO:=false}"
: "${JS_RUNTIME_REQUIRE_BUN:=false}"
: "${JS_RUNTIME_REQUIRE_YARN:=false}"
: "${JS_RUNTIME_REQUIRE_PNPM:=false}"

install_node() {
  echo "----> Installing Node.js (version: ${JS_RUNTIME_NODE_VERSION})..."
  export NVM_DIR="/usr/local/nvm"
  mkdir -p "$NVM_DIR"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  fi

  bash -lc "\
    export NVM_DIR=$NVM_DIR && \
    . \"$NVM_DIR/nvm.sh\" && \
    nvm install \"$JS_RUNTIME_NODE_VERSION\" && \
    nvm alias default \"$JS_RUNTIME_NODE_VERSION\" && \
    nvm use default && \
    corepack enable && \
    echo '      Node version: ' \"\$(node -v)\" && \
    echo '      npm version:  ' \"\$(npm -v)\" && \
    ln -sf \"\$(nvm which node)\" /usr/local/bin/node && \
    ln -sf \"\$(dirname \$(nvm which node))/npm\" /usr/local/bin/npm && \
    ln -sf \"\$(dirname \$(nvm which node))/npx\" /usr/local/bin/npx \
  "
}

install_deno() {
  echo "----> Installing Deno..."
  if [ ! -x /usr/local/bin/deno ]; then
    curl -fsSL https://deno.land/x/install/install.sh | sh
    ln -sf /root/.deno/bin/deno /usr/local/bin/deno
  fi
}

install_bun() {
  echo "----> Installing Bun..."
  if [ ! -x /usr/local/bin/bun ]; then
    curl -fsSL https://bun.sh/install | bash
    ln -sf /root/.bun/bin/bun /usr/local/bin/bun
  fi
}

install_yarn() {
  
  bash -lc "
    export NVM_DIR=/usr/local/nvm && \
    . \"$NVM_DIR/nvm.sh\" && \
    if command -v yarn >/dev/null 2>&1; then
      echo '----> Skipping Yarn: already installed (version: ' \"\$(yarn --version)\" ')';
    elif command -v npm >/dev/null 2>&1; then
      echo '----> Installing Yarn via npm...';
      npm install -g yarn && \
      echo '      Yarn version: ' \"\$(yarn --version)\";
    else
      echo '      Skipping Yarn: npm not available';
    fi
  "
}

install_pnpm() {
  bash -lc "\
    export NVM_DIR=/usr/local/nvm && \
    . \"$NVM_DIR/nvm.sh\" && \
    if command -v corepack >/dev/null; then \
      echo '----> Activating pnpm via Corepack...'; \
      corepack prepare pnpm@latest --activate && \
      echo '      pnpm version: ' \"\$(pnpm --version)\"; \
    elif command -v npm >/dev/null; then \
      echo '----> Installing pnpm via npm...'; \
      npm install -g pnpm && \
      echo '      pnpm version: ' \"\$(pnpm --version)\"; \
    else \
      echo '      Skipping pnpm: npm not available'; \
    fi \
  "
}

echo "----> Checking which JS runtimes to install..."
[ "$JS_RUNTIME_REQUIRE_NODE" = "true" ] && install_node
[ "$JS_RUNTIME_REQUIRE_DENO" = "true" ] && install_deno
[ "$JS_RUNTIME_REQUIRE_BUN"  = "true" ] && install_bun

if [ "$JS_RUNTIME_REQUIRE_NODE" = "true" ]; then
  [ "$JS_RUNTIME_REQUIRE_YARN" = "true" ] && install_yarn
  [ "$JS_RUNTIME_REQUIRE_PNPM" = "true" ] && install_pnpm
fi


# Add all relevant paths to the system profile to make them available in all shells
# This ensures that when you 'docker exec' into the container, the commands are available.
# echo "
# # Add JS Runtime Paths
# export NVM_DIR=\"/usr/local/nvm\"
# [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
# export DENO_INSTALL=\"/root/.deno\"
# export PATH=\"\$DENO_INSTALL/bin:\$PATH\"
# export BUN_INSTALL=\"/root/.bun\"
# export PATH=\"\$BUN_INSTALL/bin:\$PATH\"
# " > /etc/profile.d/js_runtimes.sh

# Do not rely on /etc/profile.d inside containers; symlinks above guarantee availability.
echo "----> JS runtime installation complete."
