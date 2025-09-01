# Swoole Profile

- Goal: run **Open Swoole** / **Swoole** PHP server for async/concurrent workloads or Laravel Octane.
- Build arg: `PHP_EXT_SWOOLE=true` in Swoole profile to compile the extension (template Dockerfile path: `php/8.4/swoole/Dockerfile`).
- Healthcheck: `common/runtime/healthchecks/healthcheck-swoole.sh` (expects `http://127.0.0.1/` 200 OK).

**Run**
```bash
docker compose -f docker-compose.profiles.yml --profile swoole up --build
````

**Laravel Octane (optional)**

* Set `ENABLE_OCTANE=true` and include an entrypoint/cmd to start `php artisan octane:start --server=swoole --host=0.0.0.0 --port=80`.
* You can model an s6 service under `/etc/services.d/octane/run` if you want Octane supervised.
