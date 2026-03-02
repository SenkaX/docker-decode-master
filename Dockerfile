# Base Alpine image
FROM alpine:edge

WORKDIR /app

# Installation de PHP 8.3 et extensions nécessaires
RUN apk add --no-cache \
    php84 \
    php84-fpm \
    php84-phar \
    php84-pdo \
    php84-pdo_pgsql \
    php84-pgsql \
    php84-session \
    php84-tokenizer \
    php84-xml \
    php84-dom \
    php84-xmlwriter \
    php84-simplexml \
    php84-mbstring \
    php84-ctype \
    php84-opcache \
    php84-intl \
    php84-zip \
    php84-curl \
    php84-openssl \
    php84-iconv \
    nginx \
    curl \
    git

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
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 127.0.0.1:9000/' /etc/php84/php-fpm.d/www.conf

# Script de démarrage
COPY <<EOF /usr/local/bin/docker-entrypoint
#!/bin/sh
set -e

# Démarrer PHP-FPM en arrière-plan
php-fpm84 -D

# Démarrer Nginx en premier plan
exec nginx -g 'daemon off;'
EOF

RUN chmod +x /usr/local/bin/docker-entrypoint

# Copier les fichiers Symfony
COPY --chown=nginx:nginx . /app

# Installation des dépendances
RUN composer install --no-interaction --optimize-autoloader

# Créer les répertoires nécessaires avec les bonnes permissions
RUN mkdir -p /app/var/cache /app/var/log /app/var/share && \
    chown -R nginx:nginx /app/var

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]

HEALTHCHECK --start-period=60s CMD curl http://localhost --silent --show-error --fail --output /dev/null || exit 1