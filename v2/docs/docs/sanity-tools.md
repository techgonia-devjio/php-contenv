# Dev Tools & Sanity

## `mani-sanity`
A single command to print:
- OS, kernel, time, CPU count
- Memory/disk snapshots
- s6 version & running services
- PHP version, loaded extensions, INI
- Composer & Node
- FrankenPHP version (when present)
- Selected env and PATH

Run:
```bash
docker exec -it <ctr> bash
mani-sanity
```

## Shell history QOL

* `/etc/profile.d/zz-history.sh` sets timestamps, `histappend`, ignores dup/space, etc.
* **Persistence**: history persists **within the running container**. If you want to persist across container recreation, add a volume:

  ```yaml
  volumes:
    - ./.docker/history:/root   # stores .bash_history in your project
  ```

  (Optional; not enabled by default to avoid cross-project bleed.)
