# Extend the Docker env — examples (not auto-applied)

This folder shows *how you could* extend the environment in your **project**, without changing the submodule.

- **php/** — put `.ini` files here (e.g., `custom.ini`). Docky auto-mounts `.docker-snippets/php/*.ini` to `/usr/local/etc/php/conf.d/` when you run `./.docker/v2/docky gen`.
- **overlays/** — demo overlays you can copy into your project at `.docker-snippets/overlays/<name>/…`. Overlays are applied at container boot by `cont-init.d/20-overlay.sh`.
- **scripts/** — random helper scripts you might copy/use inside containers.

> These are **examples only**. They don’t change your stack until you copy them where Docky looks.

----

In your root proejct you can create any folder .i.e .docker-snippets and add the docker related files their, if possibilty organized and then you can mount each file in the docker compose "app" service under volumes section.


example: you want to add a s6-service. In .docker-snippets, you create overlays/helloworld-svc/services.d/hello-world/{run,type} and then in docker compose file 

    volumes:
      - .:/var/www/html
      - ./.docker-snippets/overlays:/opt/overlay:ro   # <— mount all your overlays
    environment:
      OVERLAY_DIRS: /opt/overlay             # <— tells init where to look


for custom php.ini files

    volumes:
      - .:/var/www/html
      - ./.docker-snippets/php/custom.ini:/usr/local/etc/php/conf.d/99-custom.ini:ro  # <- changing or editing php ini file
      - ./.docker-snippets/configs/nginx/nginx.conf:/etc/nginx/nginx.conf:ro          # <- overriding nginx conf server when using nginx server 