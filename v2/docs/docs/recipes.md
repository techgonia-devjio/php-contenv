# Recipes

## Laravel (Apache)
- Ensure `public/index.php` exists (Laravel layout).
- `ENABLE_QUEUE_WORKER=true` if you want s6 to supervise `artisan queue:work`.
- DB config via env (`DB_*`) in compose.

## Symfony (Nginx+FPM)
- Keep `root /var/www/html/public;`
- Consider enabling `PHP_EXT_INTL=true` (default on).

## WordPress (Apache or Nginx)
- `PHP_EXT_GD=true`, `PHP_EXT_IMAGICK=true` helpful for media.
- `PHP_EXT_XDEBUG=true` for local plugin dev (still keep `XDEBUG_MODE=off` until needed).

## Heavy image processing
- Prefer `PHP_EXT_VIPS=true` for speed and lower memory on large images.

## Postgres stack
```yaml
# in build args
INSTALL_DB_PGSQL_CLIENT: true
DB_PGSQL_CLIENT_VERSION: 17
PHP_EXT_PDO_PGSQL: true
# optionally disable MySQL stack:
INSTALL_DB_MYSQL_CLIENT: false
PHP_EXT_PDO_MYSQL: false