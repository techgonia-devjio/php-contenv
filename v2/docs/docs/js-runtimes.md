Managed by `common/build/scripts/mani-docker-install-js-runtime.sh`:
- **Node via NVM** with symlinks to `/usr/local/bin/{node,npm,npx}` so it “just works” in shell and CI.
- **Corepack** enabled (for Yarn/Pnpm shims).
- Optional **Deno** and **Bun**.
- Optional `npm -g yarn` and Pnpm (via Corepack or npm).

**Why ship Node?** Most PHP apps use asset pipelines (Vite, Webpack) or tools like Tailwind/ESBuild.

**Typical dev setup**
```yaml
# docker-compose profiles build args
JS_RUNTIME_REQUIRE_NODE: true
JS_RUNTIME_NODE_VERSION: 22
JS_RUNTIME_REQUIRE_YARN: true
````
