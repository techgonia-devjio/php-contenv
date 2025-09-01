# Nginx + PHP-FPM Profile

- Nginx config: `common/runtime/configs/nginx/nginx.conf`
- Server block: `common/runtime/configs/nginx/conf.d/default.conf`
  - `root /var/www/html/public`
  - `try_files ... /index.php?...`
  - `fastcgi_pass 127.0.0.1:9000;` (php-fpm running in same container)

**Run**
```bash
docker compose -f docker-compose.profiles.yml --profile nginx up --build
````

**Logs**

* `/var/log/nginx` and `/var/log/php`

**Verify**

```bash
docker exec -it <ctr> bash
nginx -t && nginx -T | head -n 60
```
