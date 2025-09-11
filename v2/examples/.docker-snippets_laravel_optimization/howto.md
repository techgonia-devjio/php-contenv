## How to use

You can copy the docker-snippets_laravel_optimization folder into your project `cp -r .docker/v2/examples/.docker-snippets_laravel_optimization .docker-snippets` and then modify the files as needed.

Now, you can edit the docker-compose.yml file.
> hint: if you are going to run you app in production within docker container, you can create docker-compose.prod.yml file and add the same services with different configurations.

```yaml
# docker-compose.yml file
services:
  app:
    volumes:
      - ./.docker-snippets/php/custom.dev.ini:/usr/local/etc/php/conf.d/zz99-laravel-optimization.ini:ro
      - ./.docker-snippets/config.server/nginx/nginx.override.dev.conf:/etc/nginx/nginx.conf:ro
      - ./docker-snippets/config.server/nginx/conf.d/00default.dev.conf:/etc/nginx/conf.d/default.conf:ro
```

```yaml
# docker-compose.prod.yml file
services:
  app:
    volumes:
      - ./.docker-snippets/php/custom.prod.ini:/usr/local/etc/php/conf.d/zz99-laravel-optimization.ini:ro
      - ./.docker-snippets/config.server/nginx/nginx.override.prod.conf:/etc/nginx/nginx.conf:ro
      - ./docker-snippets/config.server/nginx/conf.d/00default.prod.conf:/etc/nginx/conf.d/default.conf:ro
```


