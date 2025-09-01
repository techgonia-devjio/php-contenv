# PHP Extensions (what/why/how)

## Core set
- **opcache**: performance, always built.
- **intl** (on by default): ICU for i18n, message formatting, collators.
- **zip** (on by default): composer + app packaging.
- **soap/xsl/gmp/bcmath/exif/pcntl**: opt-in flags.

> **Why flags?** Keep images lean. Enable only what you actually need.

## DB & caches
- **pdo_mysql** (default on)
- **pdo_pgsql** (opt-in)
- **sqlite/pdo_sqlite** (opt-in)
- **redis** (PECL, opt-in)
- **memcached** (PECL, opt-in)
- **mongodb** (PECL, opt-in)

**Runtime libs** are installed in final images only when the extension is enabled (e.g., `libpq5` for `pdo_pgsql`, `libmemcached11` for `memcached`, etc).

## Images
- **gd** (compiled with jpeg/webp/freetype/xpm)
- **imagick** (PECL; uses ImageMagick libs)
- **vips** (PECL; uses libvips)

**Why Vips?** It’s fast and memory-efficient for large images. Many modern stacks prefer it over ImageMagick for heavy transforms.

## Xdebug
- Installed at build time when `PHP_EXT_XDEBUG=true` (default).
- Controlled at runtime with `XDEBUG_MODE` (default `off`).
- IDE connects at `xdebug.client_host=host.docker.internal` port `9003`.

> Tip: leave it **installed** but **off** most of the time. Flip `XDEBUG_MODE=debug` only when investigating.