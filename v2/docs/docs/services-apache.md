# Apache Profile

- Image: `php:8.4-apache-bookworm`
- Apache modules enabled: `rewrite headers env dir mime proxy proxy_fcgi setenvif`
- Virtual host: `common/runtime/configs/apache/sites-available/000-default.conf`
  - `DocumentRoot /var/www/html/public`
  - `AllowOverride All` for `.htaccess` dev convenience

**Run**
```bash
docker compose -f docker-compose.profiles.yml --profile apache up --build
````

**Logs**

* `/var/log/apache2`
* PHP errors go to stderr (Docker logs) by default via `90-docker-custom.ini`.

**Queue worker (optional)**

* Env: `ENABLE_QUEUE_WORKER=true` will keep the `queue-worker` s6 service.
* If App lacks `artisan`, the service chills (does nothing).
