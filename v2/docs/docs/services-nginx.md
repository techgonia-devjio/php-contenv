# Nginx + PHP-FPM Profile

- Nginx config: `common/runtime/configs/nginx/nginx.conf`
- Server block: `common/runtime/configs/nginx/conf.d/default.conf`
  - `root /var/www/html/public`
  - `try_files ... /index.php?...`
  - `fastcgi_pass 127.0.0.1:9000;` (php-fpm running in same container)

**Run**
```bash
./.docker/v2/docky gen
./.docker/v2/docky up -d
````

**Logs**
- Nginx: /var/log/nginx
- PHP-FPM: /var/log/php

#### Debug tips

```bash
docker exec -it <app_name> bash     # or ./.docker/v2/docky exec
nginx -t && nginx -T | head -n 80
```
