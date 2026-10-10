FROM php:8.2-apache

# Install required system packages and PHP extensions
RUN apt-get update \
    && apt-get install -y \
        git \
        unzip \
        libicu-dev \
        libzip-dev \
        libonig-dev \
    && docker-php-ext-install \
        intl \
        mbstring \
        mysqli \
        pdo_mysql \
        zip \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# Use Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set the project directory
WORKDIR /var/www/html

# Install PHP dependencies
COPY composer.json composer.lock* ./
RUN composer install --no-dev --optimize-autoloader

# Copy the CodeIgniter project
COPY . .

# Use CodeIgniter's public folder as Apache's document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri \
    -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

# Create writable folders for CodeIgniter sessions, cache, and logs
RUN mkdir -p \
        /var/www/html/writable/session \
        /tmp/ci_sessions \
    && chown -R www-data:www-data \
        /var/www/html/writable \
        /tmp/ci_sessions \
    && chmod -R 775 \
        /var/www/html/writable \
        /tmp/ci_sessions

EXPOSE 80