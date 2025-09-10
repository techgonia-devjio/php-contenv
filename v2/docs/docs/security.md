# Security Notes (Production)

- Disable `display_errors`, enable `log_errors`.
- Tighten file permissions; avoid group write in prod images.
- Turn **off** Xdebug in prod (best: not installed in prod target).
- Use read-only root FS, drop caps where possible.
- Supply robust TLS (FrankenPHP/Caddy can terminate TLS easily).
- Healthchecks should not expose secrets; current checks are simple HTTP GETs.

Production tip: set PHP_EXT_XDEBUG=false in build args when building the production target to exclude the extension entirely.