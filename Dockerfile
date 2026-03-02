#syntax=docker/dockerfile:1

# Base Alpine image
FROM alpine:3.19

WORKDIR /app

# Installation de PHP 8.3 et extensions nécessaires
RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-pdo \
    php83-pdo_pgsql \
    php83-pgsql \
    php83-session \
    php83-tokenizer \
    php83-xml \
    php83-dom \
    php83-xmlwriter \
    php83-simplexml \
    php83-mbstring \
    php83-ctype \
    php83-opcache \
    php83-intl \
    php83-zip \
    php83-curl \
    php83-openssl \
    nginx \
    curl \
    git \
    && ln -s /usr/bin/php83 /usr/bin/php

# Installation de Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Configuration Composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Configuration Nginx pour Symfony
RUN mkdir -p /run/nginx && \
    rm -f /etc/nginx/http.d/default.conf

COPY <<EOF /etc/nginx/http.d/app.conf
server {
    listen 80;
    server_name localhost;
    root /app/public;
    
    location / {
        try_files \$uri /index.php\$is_args\$args;
    }
    
    location ~ ^/index\.php(/|$) {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        internal;
    }
    
    location ~ \.php$ {
        return 404;
    }
}
EOF

# Configuration PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 127.0.0.1:9000/' /etc/php83/php-fpm.d/www.conf

# Script de démarrage
COPY <<EOF /usr/local/bin/docker-entrypoint
#!/bin/sh
set -e

# Démarrer PHP-FPM en arrière-plan
php-fpm83 -D

# Démarrer Nginx en premier plan
exec nginx -g 'daemon off;'
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint

# Copier les fichiers Symfony
COPY --chown=nginx:nginx . /app

# Installation des dépendances
RUN composer install --no-interaction --optimize-autoloader

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]

HEALTHCHECK --start-period=60s CMD curl http://localhost --silent --show-error --fail --output /dev/null || exit 1
