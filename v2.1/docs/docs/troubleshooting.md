# Troubleshooting

## “Illegal option -o pipefail” in init
Ensure init scripts that use bash start with:
```sh
#!/command/with-contenv /bin/bash
set -euo pipefail
```

## Nginx duplicate mime types / `default_type duplicate`

* Don’t include `mime.types` twice.
* Use a single `default_type application/octet-stream;` inside `http { ... }`.

## Xdebug “Could not connect”

* IDE listening on 9003?
* Container sees host? Default is `xdebug.client_host=host.docker.internal`.
* Turn on with `XDEBUG_MODE=debug`.

## “extension not found” at runtime

* Make sure you enabled the extension at **build** (`PHP_EXT_*`) and rebuilt the image.
* The runtime stage installs the correct shared libs only if the flag was on during build.

## “artisan not found” in queue-worker

* That’s fine – the service will idle. Set `ENABLE_QUEUE_WORKER=false` to remove it.

## FrankenPHP warns about TLS / HOME

* Normal for local HTTP on `:80`. Set `HOME=/root` (compose already does) to silence the HOME warning.