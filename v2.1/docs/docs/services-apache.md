# Apache Profile

- Base: `php:<PHP>-apache-bookworm`
- Modules: `rewrite headers env dir mime proxy proxy_fcgi setenvif`
- VHost: `common/runtime/configs/apache/sites-available/000-default.conf`
  - `DocumentRoot /var/www/html/public`
  - `AllowOverride All` (dev convenience)

**Run**
```bash
./.docker/v2/docky gen   # if not done yet
./.docker/v2/docky up    # or with -d for detach mode
````

**Logs**
- Apache: `/var/log/apache2`
- PHP errors go to stderr (Docker logs) by default via `90-docker-custom.ini`.


** Queue worker (optional overlay)**
- If you enable the queue-worker overlay, ENABLE_QUEUE_WORKER=true keeps the service.
- Without artisan, the worker idles.

