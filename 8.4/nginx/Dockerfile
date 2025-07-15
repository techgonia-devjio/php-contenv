FROM php:8.4-fpm

LABEL maintainer="mani"

ARG NODE_VERSION=lts
ARG WWWUSER=1000
ARG WWWGROUP=1000

ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION=${NODE_VERSION}
ENV PATH $NVM_DIR/versions/node/v${NODE_VERSION}/bin:$PATH

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    locales-all \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    gosu \
    zip \
    unzip \
    git \
    supervisor \
    sqlite3 \
    libcap2-bin \
    python3 \
    dnsutils \
    fswatch \
    ffmpeg \
    nano \
    libpq-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libssl-dev \
    pkg-config \
    libldap2-dev \
    libmemcached-dev \
    libcurl4-openssl-dev \
    libevent-dev \
    zlib1g-dev \
    libicu-dev \
    libmcrypt-dev \
    libreadline-dev \
    default-mysql-client \
    postgresql-client-15 \
    nginx \
    inkscape \
    # Image processing libraries
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libmagickwand-dev \
    libvips-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_mysql pdo_pgsql mysqli zip exif pcntl bcmath gd soap intl opcache

RUN curl -L -o /tmp/imagick.tar.gz https://github.com/Imagick/imagick/archive/7088edc353f53c4bc644573a79cdcd67a726ae16.tar.gz \
 && tar --strip-components=1 -xf /tmp/imagick.tar.gz \
 && phpize \
 && ./configure \
 && make \
 && make install \
 && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/ext-imagick.ini \
 && rm -rf /tmp/*

# Install vips extension for libvips
RUN pecl install vips \
    && docker-php-ext-enable vips


RUN pecl install xdebug redis memcached mongodb \
    && docker-php-ext-enable xdebug redis memcached mongodb


COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN mkdir -p $NVM_DIR \
    && chown -R www-data:www-data $NVM_DIR

COPY common/install-nvm.sh /tmp/install-nvm.sh
RUN chmod +x /tmp/install-nvm.sh
RUN /tmp/install-nvm.sh
RUN rm /tmp/install-nvm.sh && . $NVM_DIR/nvm.sh \
&& nvm install ${NODE_VERSION} \
&& nvm alias default ${NODE_VERSION} \
&& nvm use default

ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
ENV PATH $NODE_PATH:$PATH


COPY common/nginx-conf/nginx.conf /etc/nginx/nginx.conf
COPY common/nginx-conf/default.conf /etc/nginx/conf.d/default.conf

RUN rm -f /var/www/html/index.html
COPY common/supervisord.nginx.conf /etc/supervisor/conf.d/supervisord.conf
COPY common/php/php.ini /usr/local/etc/php/conf.d/php.ini
COPY common/php/20-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

COPY common/start-container /usr/local/bin/start-container
RUN chmod +x /usr/local/bin/start-container

RUN chown -R www-data:www-data /var/www/html

RUN mkdir -p /var/log/php /var/log/nginx /var/log/supervisor \
 && chown -R www-data:www-data /var/log/php /var/log/nginx /var/log/supervisor \
 && chown -R www-data:www-data /var/www/html

# Expose port 80 for web traffic
EXPOSE 80

ENTRYPOINT ["start-container"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
