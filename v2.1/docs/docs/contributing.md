# Contributing

- Keep scripts **idempotent** and **branchless**: each flag should do one thing, skip otherwise.
- Prefer **domain installers** (core/db/images) over monolith scripts.
- Add new services under `common/runtime/s6/variants/<server>/services.d/<name>/run`.
- Include a healthcheck for any new server.
- Update docs + examples. Small, focused PRs are easiest to review.